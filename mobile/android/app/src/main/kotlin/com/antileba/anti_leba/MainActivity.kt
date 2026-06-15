package com.antileba.anti_leba

import android.content.Context
import android.os.Build
import android.telephony.TelephonyManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val channelName = "com.antileba.anti_leba/device_telemetry"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getSimStatus" -> result.success(readSimStatus())
                    else -> result.notImplemented()
                }
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
