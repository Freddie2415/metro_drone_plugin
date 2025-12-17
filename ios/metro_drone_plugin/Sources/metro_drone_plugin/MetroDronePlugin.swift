import Flutter
import UIKit

public class MetroDronePlugin: NSObject, FlutterPlugin {
    static let metroDrone = MetroDrone()
    static let tuner = Tuner()

    public static func register(with registrar: FlutterPluginRegistrar) {
        // Configure audio session once for the entire app
        // This enables Flutter recording + plugin playback/tuner + external music
        AudioSessionManager.shared.configureOnce()

        MetronomeChannelHandler.register(with: registrar)
        DroneToneChannelHandler.register(with: registrar)
        TunerChannelHandler.register(with: registrar)

        let metronomeEventChannel = FlutterEventChannel(name: "metro_drone_plugin/metronome/events", binaryMessenger: registrar.messenger())
        let metronomeStreamHandler = MetronomeStreamHandler(metronome: metroDrone.metronome)
        metronomeEventChannel.setStreamHandler(metronomeStreamHandler)

        let metronomeTickEventChannel = FlutterEventChannel(name: "metro_drone_plugin/metronome/tick", binaryMessenger: registrar.messenger())
        let metronomeTickStreamHandler = MetronomeTickStreamHandler(metronome: metroDrone.metronome)
        metronomeTickEventChannel.setStreamHandler(metronomeTickStreamHandler)

        let droneToneEventChannel = FlutterEventChannel(name: "metro_drone_plugin/drone_tone/events", binaryMessenger: registrar.messenger())
        let droneToneStreamHandler = DroneToneStreamHandler(droneTone: metroDrone.generatedDroneTone)
        droneToneEventChannel.setStreamHandler(droneToneStreamHandler)

        let tunerEventChannel = FlutterEventChannel(name: "metro_drone_plugin/tuner/events", binaryMessenger: registrar.messenger())
        let tunerStreamHandler = TunerStreamHandler(tuner: tuner)
        tunerEventChannel.setStreamHandler(tunerStreamHandler)
    }
}
