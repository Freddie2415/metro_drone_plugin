import Flutter
import UIKit

public class TunerStreamHandler: NSObject, FlutterStreamHandler {
    private var eventSink: FlutterEventSink?
    private let tuner: Tuner

    init (tuner: Tuner) {
        self.tuner = tuner
        super.init()
    }

    public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        self.eventSink = events

        self.tuner.onFieldUpdated = { [weak self] (field: String, value: Any) in
            self?.eventSink?([field: value])
        }

        print("ON TUNER STREAM LISTEN")

        return nil
    }

    public func onCancel(withArguments arguments: Any?) -> FlutterError? {
        self.tuner.onFieldUpdated = nil
        self.eventSink = nil

        print("ON TUNER STREAM CANCEL")
        return nil
    }
}