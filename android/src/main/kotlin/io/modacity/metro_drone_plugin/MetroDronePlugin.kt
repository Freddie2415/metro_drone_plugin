package io.modacity.metro_drone_plugin

import androidx.annotation.NonNull
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import io.modacity.metro_drone_plugin.handlers.*

/** MetroDronePlugin */
class MetroDronePlugin: FlutterPlugin {
  // Method channels
  private lateinit var metronomeChannel: MethodChannel
  private lateinit var droneToneChannel: MethodChannel
  private lateinit var tunerChannel: MethodChannel
  
  // Event channels
  private lateinit var metronomeEventChannel: EventChannel
  private lateinit var metronomeTickEventChannel: EventChannel
  private lateinit var droneToneEventChannel: EventChannel
  private lateinit var tunerEventChannel: EventChannel
  
  // Handlers
  private lateinit var metronomeChannelHandler: MetronomeChannelHandler
  private lateinit var droneToneChannelHandler: DroneToneChannelHandler
  private lateinit var tunerChannelHandler: TunerChannelHandler
  private lateinit var metronomeStreamHandler: MetronomeStreamHandler
  private lateinit var metronomeTickStreamHandler: MetronomeTickStreamHandler
  private lateinit var droneToneStreamHandler: DroneToneStreamHandler
  private lateinit var tunerStreamHandler: TunerStreamHandler

  override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    // Initialize handlers
    metronomeChannelHandler = MetronomeChannelHandler()
    droneToneChannelHandler = DroneToneChannelHandler()
    tunerChannelHandler = TunerChannelHandler()
    metronomeStreamHandler = MetronomeStreamHandler()
    metronomeTickStreamHandler = MetronomeTickStreamHandler()
    droneToneStreamHandler = DroneToneStreamHandler()
    tunerStreamHandler = TunerStreamHandler()
    
    // Set up method channels
    metronomeChannel = MethodChannel(flutterPluginBinding.binaryMessenger, "metro_drone_plugin/metronome")
    metronomeChannel.setMethodCallHandler(metronomeChannelHandler)
    
    droneToneChannel = MethodChannel(flutterPluginBinding.binaryMessenger, "metro_drone_plugin/drone_tone")
    droneToneChannel.setMethodCallHandler(droneToneChannelHandler)
    
    tunerChannel = MethodChannel(flutterPluginBinding.binaryMessenger, "metro_drone_plugin/tuner")
    tunerChannel.setMethodCallHandler(tunerChannelHandler)
    
    // Set up event channels
    metronomeEventChannel = EventChannel(flutterPluginBinding.binaryMessenger, "metro_drone_plugin/metronome/events")
    metronomeEventChannel.setStreamHandler(metronomeStreamHandler)
    
    metronomeTickEventChannel = EventChannel(flutterPluginBinding.binaryMessenger, "metro_drone_plugin/metronome/tick")
    metronomeTickEventChannel.setStreamHandler(metronomeTickStreamHandler)
    
    droneToneEventChannel = EventChannel(flutterPluginBinding.binaryMessenger, "metro_drone_plugin/drone_tone/events")
    droneToneEventChannel.setStreamHandler(droneToneStreamHandler)
    
    tunerEventChannel = EventChannel(flutterPluginBinding.binaryMessenger, "metro_drone_plugin/tuner/events")
    tunerEventChannel.setStreamHandler(tunerStreamHandler)
  }

  override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
    metronomeChannel.setMethodCallHandler(null)
    droneToneChannel.setMethodCallHandler(null)
    tunerChannel.setMethodCallHandler(null)
    metronomeEventChannel.setStreamHandler(null)
    metronomeTickEventChannel.setStreamHandler(null)
    droneToneEventChannel.setStreamHandler(null)
    tunerEventChannel.setStreamHandler(null)
  }
}
