package io.modacity.metro_drone_plugin.handlers

import io.flutter.plugin.common.EventChannel

class MetronomeStreamHandler : EventChannel.StreamHandler {
    private var eventSink: EventChannel.EventSink? = null
    
    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        eventSink = events
        // TODO: Set up metronome field update listeners
        // When metronome properties change, call:
        // eventSink?.success(mapOf("fieldName" to value))
    }
    
    override fun onCancel(arguments: Any?) {
        eventSink = null
        // TODO: Remove listeners
    }
    
    // Helper method to send updates to Flutter
    fun sendUpdate(field: String, value: Any) {
        eventSink?.success(mapOf(field to value))
    }
    
    // Helper method to send multiple field updates
    fun sendUpdates(updates: Map<String, Any>) {
        eventSink?.success(updates)
    }
}

class MetronomeTickStreamHandler : EventChannel.StreamHandler {
    private var eventSink: EventChannel.EventSink? = null
    
    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        eventSink = events
        // TODO: Set up metronome tick listeners
        // When tick occurs, call:
        // eventSink?.success(tickIndex)
    }
    
    override fun onCancel(arguments: Any?) {
        eventSink = null
        // TODO: Remove tick listeners
    }
    
    // Helper method to send tick updates to Flutter
    fun sendTick(tickIndex: Int) {
        eventSink?.success(tickIndex)
    }
}