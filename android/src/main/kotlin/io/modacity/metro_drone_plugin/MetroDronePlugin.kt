package io.modacity.metro_drone_plugin

import androidx.annotation.NonNull
import app.metrodrone.domain.clicker.MetronomeClicker
import app.metrodrone.domain.drone.Drone
import app.metrodrone.domain.drone.soundgen.DronePulseGen
import app.metrodrone.domain.drone.soundgen.DroneSoundGen
import app.metrodrone.domain.metrodrone.Metrodrone
import app.metrodrone.domain.metrodrone.SoundPlayer
import app.metrodrone.domain.metronome.Metronome
import app.metrodrone.domain.metronome.soundgen.MetronomeSoundGen
import app.metrodrone.domain.metronome.soundgen.MetronomeSoundTreeBuilder
import app.metrodrone.domain.tuner.TunerEngine
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import io.modacity.metro_drone_plugin.handlers.*

/** MetroDronePlugin */
class MetroDronePlugin : FlutterPlugin {
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

    // Keep reference for cleanup
    private var metrodrone: Metrodrone? = null
    private var tuner: TunerEngine? = null

    override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        val context = flutterPluginBinding.applicationContext
        val droneSoundGen = DroneSoundGen()
        val metronomeSoundTreeBuilder = MetronomeSoundTreeBuilder(context)
        val metronomeSoundGen = MetronomeSoundGen(metronomeSoundTreeBuilder)
        val dronePulseGen = DronePulseGen(droneSoundGen)
        val drone = Drone(droneSoundGen)
        val clicker = MetronomeClicker()
        val metronome = Metronome(context, metronomeSoundGen, dronePulseGen, drone, clicker)
        val metronomeSoundPlayer = SoundPlayer()
        val droneSoundPlayer = SoundPlayer()
        val metrodroneInstance = Metrodrone(metronome, drone, metronomeSoundPlayer, droneSoundPlayer)
        metrodroneInstance.initialize(context)
        metrodrone = metrodroneInstance
        val tunerInstance = TunerEngine()
        tuner = tunerInstance

        // Initialize handlers
        metronomeChannelHandler = MetronomeChannelHandler(metrodroneInstance)
        droneToneChannelHandler = DroneToneChannelHandler(metrodroneInstance)
        metronomeStreamHandler = MetronomeStreamHandler(metronome)
        metronomeTickStreamHandler = MetronomeTickStreamHandler(metronome)
        droneToneStreamHandler = DroneToneStreamHandler(drone)
        tunerStreamHandler = TunerStreamHandler(tunerInstance)
        tunerChannelHandler = TunerChannelHandler(tunerInstance, context)

        // Connect metronome channel handler with tick stream handler
        metronomeChannelHandler.tickStreamHandler = metronomeTickStreamHandler

        // Set up method channels
        metronomeChannel =
            MethodChannel(flutterPluginBinding.binaryMessenger, "metro_drone_plugin/metronome")
        metronomeChannel.setMethodCallHandler(metronomeChannelHandler)

        droneToneChannel =
            MethodChannel(flutterPluginBinding.binaryMessenger, "metro_drone_plugin/drone_tone")
        droneToneChannel.setMethodCallHandler(droneToneChannelHandler)

        tunerChannel =
            MethodChannel(flutterPluginBinding.binaryMessenger, "metro_drone_plugin/tuner")
        tunerChannel.setMethodCallHandler(tunerChannelHandler)

        // Set up event channels
        metronomeEventChannel = EventChannel(
            flutterPluginBinding.binaryMessenger,
            "metro_drone_plugin/metronome/events"
        )
        metronomeEventChannel.setStreamHandler(metronomeStreamHandler)

        metronomeTickEventChannel =
            EventChannel(flutterPluginBinding.binaryMessenger, "metro_drone_plugin/metronome/tick")
        metronomeTickEventChannel.setStreamHandler(metronomeTickStreamHandler)

        droneToneEventChannel = EventChannel(
            flutterPluginBinding.binaryMessenger,
            "metro_drone_plugin/drone_tone/events"
        )
        droneToneEventChannel.setStreamHandler(droneToneStreamHandler)

        tunerEventChannel =
            EventChannel(flutterPluginBinding.binaryMessenger, "metro_drone_plugin/tuner/events")
        tunerEventChannel.setStreamHandler(tunerStreamHandler)
    }

    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        // Release audio resources
        metrodrone?.release()
        metrodrone = null
        tuner?.stop()
        tuner = null

        // Clear handlers
        metronomeChannel.setMethodCallHandler(null)
        droneToneChannel.setMethodCallHandler(null)
        tunerChannel.setMethodCallHandler(null)
        metronomeEventChannel.setStreamHandler(null)
        metronomeTickEventChannel.setStreamHandler(null)
        droneToneEventChannel.setStreamHandler(null)
        tunerEventChannel.setStreamHandler(null)
    }
}
