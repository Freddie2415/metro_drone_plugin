package io.modacity.metro_drone_plugin.handlers

import android.util.Log
import app.metrodrone.domain.tuner.TunerEngine
import io.flutter.plugin.common.EventChannel

class TunerStreamHandler(val tunerEngine: TunerEngine) : EventChannel.StreamHandler {
    private var eventSink: EventChannel.EventSink? = null

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        eventSink = events
        tunerEngine.onFieldUpdate = { field, value ->
            if (field == "pitch") {
                sendTunerData(value as TunerEngine.Result)
            } else {
                eventSink?.success(mapOf(field to value))
            }
        }
    }

    override fun onCancel(arguments: Any?) {
        tunerEngine.onFieldUpdate = null;
        eventSink = null
    }

    // Method to send TunerEngine.Result to Flutter
    fun sendTunerData(result: TunerEngine.Result) {
        val (note, octave) = parseNoteName(result.noteName)
        val pitchData = mapOf(
            "pitch" to mapOf(
                "note" to note,
                "octave" to octave,
                "frequency" to result.hz.toDouble(),
                "closestOffsetCents" to result.centsOff
            )
        )
        Log.d("Tuner", "PitchData ${pitchData}")
        eventSink?.success(pitchData)
    }

    // Parse note name like "A4" into note "A" and octave "4"
    private fun parseNoteName(noteName: String): Pair<String, String> {
        val regex = Regex("([A-G]#?)(-?\\d+)")
        val match = regex.find(noteName)
        return if (match != null) {
            val note = match.groupValues[1]
            val octave = match.groupValues[2]
            note to octave
        } else {
            "Unknown" to "Unknown"
        }
    }
}