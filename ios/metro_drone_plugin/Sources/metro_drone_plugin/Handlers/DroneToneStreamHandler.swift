import Flutter
import UIKit

public class DroneToneStreamHandler: NSObject, FlutterStreamHandler {
    private var eventSink: FlutterEventSink?
    private let droneTone: GeneratedDroneTone2

    init (droneTone: GeneratedDroneTone2) {
        self.droneTone = droneTone
        super.init()
    }

    public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        self.eventSink = events

        self.droneTone.onFieldUpdated = { [weak self] (field: String, value: Any) in
            self?.eventSink?([field: value])
        }

        return nil
    }

    public func onCancel(withArguments arguments: Any?) -> FlutterError? {
        self.droneTone.onFieldUpdated = nil
        self.eventSink = nil
        return nil
    }
}