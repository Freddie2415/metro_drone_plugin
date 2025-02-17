import Flutter
import UIKit

public class MetronomeStreamHandler: NSObject, FlutterStreamHandler {
    private var eventSink: FlutterEventSink?
    private let metronome: Metronome

    init (metronome: Metronome) {
        self.metronome = metronome
        super.init()
    }

    public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        self.eventSink = events

        self.metronome.onFieldUpdated = { [weak self] (field: String, value: Any) in
            self?.eventSink?([field: value])
        }

        return nil
    }

    public func onCancel(withArguments arguments: Any?) -> FlutterError? {
        self.metronome.onFieldUpdated = nil
        self.eventSink = nil
        return nil
    }
}

public class MetronomeTickStreamHandler: NSObject, FlutterStreamHandler {
    private var eventSink: FlutterEventSink?
    private let metronome: Metronome

    init (metronome: Metronome) {
        self.metronome = metronome
        super.init()
    }

    public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        self.eventSink = events

        self.metronome.onTickUpdated = { [weak self] (tickIndex: Int) in
            self?.eventSink?(tickIndex)
        }

        return nil
    }

    public func onCancel(withArguments arguments: Any?) -> FlutterError? {
        self.metronome.onTickUpdated = nil
        self.eventSink = nil
        return nil
    }
}