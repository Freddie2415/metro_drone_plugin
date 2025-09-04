package io.modacity.metro_drone_plugin.handlers

import app.metrodrone.domain.drone.Drone
import app.metrodrone.domain.drone.models.Note
import app.metrodrone.domain.drone.models.Octave
import app.metrodrone.domain.drone.models.SoundType
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
            metrodrone.drone.isPulsing = isPulsing
            if (metrodrone.drone.isPulsing) {
                metrodrone.stopDrone()
            }
            metrodrone.metronome.updatePulsarMode(isPulsing)
            result.success("isPulsing set to $isPulsing")
        } else {
            result.error("INVALID_ARGUMENTS", "isPulsing value missing", null)
        }
    }

    private fun handleSetNote(call: MethodCall, result: MethodChannel.Result) {
        val args = call.arguments as? Map<String, Any>
        if (args != null) {
            val noteString = args["note"] as? String
            val octave = args["octave"] as? Int

            if (noteString != null && octave != null) {
                val note = parseNoteFromString(noteString)
                if (note != null) {
                    metrodrone.drone.note = note
                    metrodrone.drone.octave = Octave(octave)
                    result.success("Set Note $noteString $octave")
                } else {
                    result.error("INVALID_ARGUMENTS", "Invalid note name: $noteString", null)
                }
            } else {
                result.error("INVALID_ARGUMENTS", "handleSetNote values missing or incorrect", null)
            }
        } else {
            result.error("INVALID_ARGUMENTS", "Invalid argument format", null)
        }
    }
    
    private fun parseNoteFromString(noteString: String): Note? {
        return when (noteString) {
            "C", "c" -> Note.C
            "C#", "c#", "CS", "cs", "Cs" -> Note.Cs
            "D", "d" -> Note.D
            "D#", "d#", "DS", "ds", "Ds" -> Note.Ds
            "E", "e" -> Note.E
            "F", "f" -> Note.F
            "F#", "f#", "FS", "fs", "Fs" -> Note.Fs
            "G", "g" -> Note.G
            "G#", "g#", "GS", "gs", "Gs" -> Note.Gs
            "A", "a" -> Note.A
            "A#", "a#", "AS", "as", "As" -> Note.As
            "B", "b" -> Note.B
            else -> null
        }
    }

    private fun handleSetTuningStandard(call: MethodCall, result: MethodChannel.Result) {
        val tuningStandard = call.arguments as? Double
        if (tuningStandard != null) {
            metrodrone.drone.tuning = app.metrodrone.domain.drone.models.Tuning(tuningStandard)
            result.success("tuningStandardA set to $tuningStandard")
        } else {
            result.error("INVALID_ARGUMENTS", "tuningStandard value missing", null)
        }
    }

    private fun handleSetSoundType(call: MethodCall, result: MethodChannel.Result) {
        val soundTypeString = call.arguments as? String
        if (soundTypeString != null) {
            val soundType = parseSoundTypeFromString(soundTypeString)
            if (soundType != null) {
                metrodrone.drone.soundType = soundType
                result.success("Set sound type to $soundTypeString")
            } else {
                result.error("INVALID_ARGUMENTS", "Invalid sound type: $soundTypeString", null)
            }
        } else {
            result.error("INVALID_ARGUMENTS", "soundType value missing", null)
        }
    }

    private fun parseSoundTypeFromString(soundTypeString: String): SoundType? {
        return when (soundTypeString.lowercase()) {
            "sine" -> SoundType.SINE
            "organ" -> SoundType.ORGAN
            "cello" -> SoundType.CELLO
            else -> null
        }
    }
}