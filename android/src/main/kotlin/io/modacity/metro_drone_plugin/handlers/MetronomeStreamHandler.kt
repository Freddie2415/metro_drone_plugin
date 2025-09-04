package io.modacity.metro_drone_plugin.handlers

import app.metrodrone.domain.metronome.Metronome
import io.flutter.plugin.common.EventChannel
import android.util.Log

class MetronomeStreamHandler(private var metronome: Metronome) : EventChannel.StreamHandler {

    private var eventSink: EventChannel.EventSink? = null

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        eventSink = events
        metronome.onFieldUpdate = { field, value ->
            sendUpdate(field, value)
        }
    }

    override fun onCancel(arguments: Any?) {
        metronome.onFieldUpdate = null
        eventSink = null
    }

    // Helper method to send updates to Flutter
    fun sendUpdate(field: String, value: Any) {
        Log.d("Metronome", "${field}: $value")
        eventSink?.success(mapOf(field to value))
    }

    // Helper method to send multiple field updates
    fun sendUpdates(updates: Map<String, Any>) {
        eventSink?.success(updates)
    }
}

class MetronomeTickStreamHandler(private var metronome: Metronome) : EventChannel.StreamHandler {
    private var eventSink: EventChannel.EventSink? = null

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        eventSink = events
        metronome.onTickUpdated = { tick -> sendTick(tick) }
    }

    override fun onCancel(arguments: Any?) {
        metronome.onTickUpdated = null
        eventSink = null
    }

    // Helper method to send tick updates to Flutter
    fun sendTick(tickIndex: Int) {
        eventSink?.success(tickIndex)
    }
}