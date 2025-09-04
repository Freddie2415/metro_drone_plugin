package io.modacity.metro_drone_plugin.handlers

import app.metrodrone.domain.drone.Drone
import app.metrodrone.domain.drone.models.Note
import app.metrodrone.domain.metrodrone.Metrodrone
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class DroneToneChannelHandler(private val metrodrone: Metrodrone) : MethodChannel.MethodCallHandler {

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "start" -> {
                handleStart(call, result)
            }
            "stop" -> {
                handleStop(call, result)
            }
            "setPulsing" -> {
                handleSetPulsing(call, result)
            }
            "setNote" -> {
                handleSetNote(call, result)
            }
            "setTuningStandard" -> {
                handleSetTuningStandard(call, result)
            }
            "setSoundType" -> {
                handleSetSoundType(call, result)
            }
            else -> {
                result.notImplemented()
            }
        }
    }

    private fun handleStart(call: MethodCall, result: MethodChannel.Result) {
        metrodrone.startDrone();
        result.success("start")
    }

    private fun handleStop(call: MethodCall, result: MethodChannel.Result) {
        metrodrone.stopDrone();
        result.success("stop")
    }

    private fun handleSetPulsing(call: MethodCall, result: MethodChannel.Result) {
        val isPulsing = call.arguments as? Boolean
        if (isPulsing != null) {
            metrodrone.metronome.updatePulsarMode(isPulsing)
            result.success("isPulsing set to $isPulsing")
        } else {
            result.error("INVALID_ARGUMENTS", "isPulsing value missing", null)
        }
    }

    private fun handleSetNote(call: MethodCall, result: MethodChannel.Result) {
        val args = call.arguments as? Map<String, Any>
        if (args != null) {
            val note = args["note"] as? String
            val octave = args["octave"] as? Int

            if (note != null && octave != null) {
                // TODO: Implement note setting
                result.success("Set Note $note $octave")
            } else {
                result.error("INVALID_ARGUMENTS", "handleSetNote values missing or incorrect", null)
            }
        } else {
            result.error("INVALID_ARGUMENTS", "Invalid argument format", null)
        }
    }

    private fun handleSetTuningStandard(call: MethodCall, result: MethodChannel.Result) {
        val tuningStandard = call.arguments as? Double
        if (tuningStandard != null) {
            // TODO: Implement tuning standard setting
            result.success("tuningStandardA set to $tuningStandard")
        } else {
            result.error("INVALID_ARGUMENTS", "tuningStandard value missing", null)
        }
    }

    private fun handleSetSoundType(call: MethodCall, result: MethodChannel.Result) {
        val soundTypeString = call.arguments as? String
        if (soundTypeString != null) {
            // TODO: Implement sound type setting
            result.success("set sound type to $soundTypeString")
        } else {
            result.error("INVALID_ARGUMENTS", "soundType value missing", null)
        }
    }
}