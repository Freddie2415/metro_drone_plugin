package io.modacity.metro_drone_plugin.handlers

import android.Manifest
import android.content.Context
import android.content.pm.PackageManager
import android.util.Log
import androidx.core.content.ContextCompat
import app.metrodrone.domain.tuner.TunerEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import android.os.Handler
import android.os.Looper

class TunerChannelHandler(
    private val tunerEngine: TunerEngine, private val context: Context
) : MethodChannel.MethodCallHandler {

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "start" -> {
                handleStart(call, result)
            }

            "stop" -> {
                handleStop(call, result)
            }

            "setTuningStandard" -> {
                handleSetTuningStandard(call, result)
            }

            else -> {
                result.notImplemented()
            }
        }
    }

    private fun handleStart(call: MethodCall, result: MethodChannel.Result) {
        // Check if RECORD_AUDIO permission is granted
        if (ContextCompat.checkSelfPermission(
                context, Manifest.permission.RECORD_AUDIO
            ) != PackageManager.PERMISSION_GRANTED
        ) {
            result.error("PERMISSION_DENIED", "RECORD_AUDIO permission is required", null)
            return
        }

        try {
            val mainHandler = Handler(Looper.getMainLooper())
            tunerEngine.start { tunerResult ->
                Log.d("TUNER", "${tunerResult}")
                try {
                    // Switch to main thread for EventSink
                    mainHandler.post {
                        tunerEngine.onFieldUpdate?.invoke("pitch", tunerResult)
                    }
                } catch (e: Exception) {
                    Log.e("TUNER ERROR", "${e.message}")
                }
            }
            result.success(true)
        } catch (e: Exception) {
            result.error("START_ERROR", "Failed to start tuner: ${e.message}", null)
        }
    }

    private fun handleStop(call: MethodCall, result: MethodChannel.Result) {
        try {
            tunerEngine.stop()
            result.success(false)
        } catch (e: Exception) {
            result.error("STOP_ERROR", "Failed to stop tuner: ${e.message}", null)
        }
    }

    private fun handleSetTuningStandard(call: MethodCall, result: MethodChannel.Result) {
        val tuningStandard = call.arguments as? Double
        if (tuningStandard != null) {
            try {
                tunerEngine.updateTuningA(tuningStandard)
                result.success(tuningStandard)
            } catch (e: Exception) {
                result.error("TUNING_ERROR", "Failed to set tuning standard: ${e.message}", null)
            }
        } else {
            result.error("INVALID_ARGUMENTS", "tuningStandard value missing", null)
        }
    }
}