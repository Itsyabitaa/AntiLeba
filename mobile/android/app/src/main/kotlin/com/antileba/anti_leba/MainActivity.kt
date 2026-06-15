package com.antileba.anti_leba

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.media.AudioAttributes
import android.media.Ringtone
import android.media.RingtoneManager
import android.net.Uri
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager
import android.telephony.SmsManager
import android.telephony.TelephonyManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val channelName = "com.antileba.anti_leba/device_telemetry"
    private val simEventChannelName = "$channelName/sim_events"

    private var simEventSink: EventChannel.EventSink? = null
    private var simReceiver: BroadcastReceiver? = null
    private var alarmRingtone: Ringtone? = null
    private var alarmStopHandler: Handler? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getSimStatus" -> result.success(readSimStatus())
                    "isSmsCapable" -> result.success(isSmsCapable())
                    "sendSms" -> {
                        val to = call.argument<String>("to")
                        val message = call.argument<String>("message")
                        if (to.isNullOrBlank() || message == null) {
                            result.error("INVALID_ARGS", "to and message required", null)
                            return@setMethodCallHandler
                        }
                        try {
                            sendSms(to, message)
                            result.success(true)
                        } catch (error: Exception) {
                            result.error("SEND_FAILED", error.message, null)
                        }
                    }
                    "playAlarm" -> {
                        val durationSeconds = call.argument<Int>("durationSeconds") ?: 15
                        try {
                            playAlarm(durationSeconds)
                            result.success(true)
                        } catch (error: Exception) {
                            result.error("ALARM_FAILED", error.message, null)
                        }
                    }
                    "stopAlarm" -> {
                        stopAlarm()
                        result.success(true)
                    }
                    else -> result.notImplemented()
                }
            }

        EventChannel(flutterEngine.dartExecutor.binaryMessenger, simEventChannelName)
            .setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    simEventSink = events
                    registerSimReceiver()
                    events?.success(readSimStatus())
                }

                override fun onCancel(arguments: Any?) {
                    unregisterSimReceiver()
                    simEventSink = null
                }
            })
    }

    override fun onDestroy() {
        stopAlarm()
        unregisterSimReceiver()
        super.onDestroy()
    }

    private fun registerSimReceiver() {
        if (simReceiver != null) return

        simReceiver = object : BroadcastReceiver() {
            override fun onReceive(context: Context?, intent: Intent?) {
                simEventSink?.success(readSimStatus())
            }
        }

        // Standard SIM broadcast — not exposed as Intent/TelephonyManager constant on all SDKs.
        val filter = IntentFilter("android.intent.action.SIM_STATE_CHANGED")
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            registerReceiver(simReceiver, filter, Context.RECEIVER_NOT_EXPORTED)
        } else {
            registerReceiver(simReceiver, filter)
        }
    }

    private fun unregisterSimReceiver() {
        simReceiver?.let {
            try {
                unregisterReceiver(it)
            } catch (_: IllegalArgumentException) {
            }
        }
        simReceiver = null
    }

    private fun isSmsCapable(): Boolean {
        val tm = getSystemService(Context.TELEPHONY_SERVICE) as TelephonyManager
        return tm.phoneType != TelephonyManager.PHONE_TYPE_NONE
    }

    private fun sendSms(to: String, message: String) {
        val smsManager = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            getSystemService(SmsManager::class.java)
        } else {
            @Suppress("DEPRECATION")
            SmsManager.getDefault()
        }

        if (message.length > 160) {
            val parts = smsManager.divideMessage(message)
            smsManager.sendMultipartTextMessage(to, null, parts, null, null)
        } else {
            smsManager.sendTextMessage(to, null, message, null, null)
        }
    }

    private fun readSimStatus(): Map<String, String> {
        val tm = getSystemService(Context.TELEPHONY_SERVICE) as TelephonyManager
        val status = when (tm.simState) {
            TelephonyManager.SIM_STATE_READY -> "READY"
            TelephonyManager.SIM_STATE_ABSENT -> "ABSENT"
            TelephonyManager.SIM_STATE_PIN_REQUIRED -> "PIN_REQUIRED"
            TelephonyManager.SIM_STATE_PUK_REQUIRED -> "PUK_REQUIRED"
            TelephonyManager.SIM_STATE_NETWORK_LOCKED -> "NETWORK_LOCKED"
            TelephonyManager.SIM_STATE_NOT_READY -> "NOT_READY"
            else -> "UNKNOWN"
        }

        val operator = tm.simOperatorName?.takeIf { it.isNotBlank() } ?: "UNKNOWN"
        val serial = readSimSerial(tm)

        return mapOf(
            "status" to status,
            "operator" to operator,
            "serial" to serial,
        )
    }

    private fun readSimSerial(tm: TelephonyManager): String {
        return try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                tm.simSerialNumber?.takeIf { it.isNotBlank() } ?: "UNKNOWN"
            } else {
                "UNKNOWN"
            }
        } catch (_: SecurityException) {
            "UNKNOWN"
        }
    }

    private fun playAlarm(durationSeconds: Int) {
        stopAlarm()

        val alarmUri: Uri = RingtoneManager.getDefaultUri(RingtoneManager.TYPE_ALARM)
            ?: RingtoneManager.getDefaultUri(RingtoneManager.TYPE_RINGTONE)

        alarmRingtone = RingtoneManager.getRingtone(applicationContext, alarmUri)?.apply {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
                audioAttributes = AudioAttributes.Builder()
                    .setUsage(AudioAttributes.USAGE_ALARM)
                    .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                    .build()
            }
            play()
        }

        val vibrator = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            val manager = getSystemService(VibratorManager::class.java)
            manager?.defaultVibrator
        } else {
            @Suppress("DEPRECATION")
            getSystemService(Context.VIBRATOR_SERVICE) as Vibrator
        }

        vibrator?.let {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                it.vibrate(
                    VibrationEffect.createWaveform(
                        longArrayOf(0, 800, 400, 800, 400, 800),
                        0,
                    ),
                )
            } else {
                @Suppress("DEPRECATION")
                it.vibrate(longArrayOf(0, 800, 400, 800, 400, 800), 0)
            }
        }

        val handler = Handler(Looper.getMainLooper())
        alarmStopHandler = handler
        handler.postDelayed({ stopAlarm() }, durationSeconds.coerceIn(5, 60) * 1000L)
    }

    private fun stopAlarm() {
        alarmStopHandler?.removeCallbacksAndMessages(null)
        alarmStopHandler = null

        alarmRingtone?.stop()
        alarmRingtone = null

        val vibrator = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            val manager = getSystemService(VibratorManager::class.java)
            manager?.defaultVibrator
        } else {
            @Suppress("DEPRECATION")
            getSystemService(Context.VIBRATOR_SERVICE) as Vibrator
        }
        vibrator?.cancel()
    }
}
