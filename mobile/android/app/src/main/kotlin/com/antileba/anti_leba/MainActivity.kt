package com.antileba.anti_leba

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.Build
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
}
