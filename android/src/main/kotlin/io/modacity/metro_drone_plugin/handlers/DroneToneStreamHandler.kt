package io.modacity.metro_drone_plugin.handlers

import app.metrodrone.domain.drone.Drone
import io.flutter.plugin.common.EventChannel

class DroneToneStreamHandler(private val drone: Drone) : EventChannel.StreamHandler {
    private var eventSink: EventChannel.EventSink? = null
    
    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        eventSink = events
        // Set up drone tone field update listeners
        drone.onFieldUpdate = { field, value ->
            sendUpdate(field, value)
        }
    }
    
    override fun onCancel(arguments: Any?) {
        eventSink = null
        // Remove listeners
        drone.onFieldUpdate = null
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