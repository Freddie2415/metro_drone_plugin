import Flutter
import UIKit

class TunerChannelHandler: NSObject, FlutterPlugin {
    private let tuner: Tuner
    private var methodHandlers: [String: (FlutterMethodCall, @escaping FlutterResult) -> Void] = [:]

    init (tuner: Tuner) {
        self.tuner = tuner;
        super.init()
    }

    static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "metro_drone_plugin/tuner", binaryMessenger: registrar.messenger())
        let instance = TunerChannelHandler(tuner: MetroDronePlugin.tuner)
        instance.registerHandlers()

        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        if let handler = methodHandlers[call.method] {
            handler(call, result)
        } else {
            result(FlutterMethodNotImplemented)
        }
    }

    private func registerHandlers() {
        self.methodHandlers["start"] = self.handleStart
        self.methodHandlers["stop"] = self.handleStop
        self.methodHandlers["setTuningStandard"] = self.handleSetTuningStandard
    }

    private func handleStart(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        self.tuner.start()
        result(true)
    }

    private func handleStop(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        self.tuner.stop()
        result(false)
    }

    private func handleSetTuningStandard(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        if let tuningStandard = call.arguments as? Double {
            self.tuner.tuningFrequency = tuningStandard
            result(tuningStandard)
        } else {
            result(FlutterError(code: "INVALID_ARGUMENTS", message: "tuningStandard value missing", details: nil))
        }
    }
}