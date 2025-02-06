import Flutter
import UIKit

public class MetroDronePlugin: NSObject, FlutterPlugin {
    static let metroDrone = MetroDrone()

    public static func register(with registrar: FlutterPluginRegistrar) {
        MetronomeChannelHandler.register(with: registrar)
        DroneToneChannelHandler.register(with: registrar)

        let metronomeEventChannel = FlutterEventChannel(name: "metro_drone_plugin/metronome/events", binaryMessenger: registrar.messenger())
        let metronomeStreamHandler = MetronomeStreamHandler(metronome: metroDrone.metronome)
        metronomeEventChannel.setStreamHandler(metronomeStreamHandler)

        let droneToneEventChannel = FlutterEventChannel(name: "metro_drone_plugin/drone_tone/events", binaryMessenger: registrar.messenger())
        let droneToneStreamHandler = DroneToneStreamHandler(droneTone: metroDrone.generatedDroneTone)
        droneToneEventChannel.setStreamHandler(droneToneStreamHandler)
    }
}
