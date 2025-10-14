import Flutter
import UIKit

class MetronomeChannelHandler: NSObject, FlutterPlugin {
    private let metronome: Metronome
    private var methodHandlers: [String: (FlutterMethodCall, @escaping FlutterResult) -> Void] = [:]

    init(metronome: Metronome) {
        self.metronome = metronome
        super.init()
    }

    static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "metro_drone_plugin/metronome", binaryMessenger: registrar.messenger())
        let instance = MetronomeChannelHandler(metronome: MetroDronePlugin.metroDrone.metronome)
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
        self.methodHandlers["getPlatformVersion"] = self.handleGetPlatformVersion
        self.methodHandlers["start"] = self.handleStart
        self.methodHandlers["stop"] = self.handleStop
        self.methodHandlers["tap"] = self.handleTap
        self.methodHandlers["setBpm"] = self.handleSetBpm
        self.methodHandlers["setSubdivision"] = self.handleSetSubdivision
        self.methodHandlers["setTimeSignatureNumerator"] = self.handleSetTimeSignatureNumerator
        self.methodHandlers["setTimeSignatureDenominator"] = self.handleSetTimeSignatureDenominator
        self.methodHandlers["setNextTickType"] = self.handleSetNextTickType
        self.methodHandlers["setDroneDurationRatio"] = self.handleSetDroneDurationRatio
        self.methodHandlers["setTickTypes"] = self.handleSetTickTypes
        self.methodHandlers["configure"] = self.handleConfigure
    }

    private func handleGetPlatformVersion(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        result("iOS " + UIDevice.current.systemVersion)
    }

    private func handleStart(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        self.metronome.start()
        result("start")
    }

    private func handleStop(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        self.metronome.stop()
        result("stop")
    }

    private func handleTap(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        self.metronome.tap()
        result("tap")
    }

    private func handleSetBpm(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        if let bpm = call.arguments as? Int {
            self.metronome.setBPM(bpm)
            result("BPM set to \(bpm)")
        } else {
            result(FlutterError(code: "INVALID_ARGUMENTS", message: "BPM value missing", details: nil))
        }
    }

    private func handleSetSubdivision(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        print(call.arguments);
        if let args = call.arguments as? [String: Any] {
            guard let name = args["name"] as? String,
                  let description = args["description"] as? String,
                  let restPattern = args["restPattern"] as? [Bool],
                  let durationPattern = args["durationPattern"] as? [Double] else {
                result(FlutterError(code: "INVALID_ARGUMENTS", message: "setSubdivision values missing or incorrect", details: nil))
                return
            }

            self.metronome.subdivision = Subdivision(
                name: name,
                description: description,
                restPattern: restPattern,
                durationPattern: durationPattern
            )
            result("Subdivision updated")
        } else {
            result(FlutterError(code: "INVALID_ARGUMENTS", message: "Invalid argument format", details: nil))
        }
    }

    private func handleSetTimeSignatureNumerator(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        if let value = call.arguments as? Int {
            self.metronome.timeSignatureNumerator = value
            result("timeSignatureNumerator set to \(value)")
        } else {
            result(FlutterError(code: "INVALID_ARGUMENTS", message: "timeSignatureNumerator value missing", details: nil))
        }
    }

    private func handleSetTimeSignatureDenominator(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        if let args = call.arguments as? Int,
            let value = args as? Int {
                self.metronome.timeSignatureDenominator = value
                result("timeSignatureDenominator set to \(value)")
        } else {
            result(FlutterError(code: "INVALID_ARGUMENTS", message: "timeSignatureDenominator value missing", details: nil))
        }
    }

    private func handleSetNextTickType(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        if let args = call.arguments as? Int,
            let value = args as? Int {
                self.metronome.setNextTickType(tickIndex: value)
                result("setNextTickType set to index: \(value)")
        } else {
            result(FlutterError(code: "INVALID_ARGUMENTS", message: "setNextTickType tickIndex missing", details: nil))
        }
    }

    private func handleSetDroneDurationRatio(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        if let droneDurationRatio = call.arguments as? Double {
            self.metronome.setDroneDurationRatio(droneDurationRatio)
            result("DroneDurationRatio set to \(droneDurationRatio)")
        } else {
            result(FlutterError(code: "INVALID_ARGUMENTS", message: "BPM value missing", details: nil))
        }
    }

    private func handleSetTickTypes(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        if let tickTypeStringArray = call.arguments as? [String] {
           let tickTypes: [TickType] = tickTypeStringArray.compactMap { TickType(from: $0) }
           self.metronome.setTickTypes(tickTypes: tickTypes)
           result("tickTypes set to \(tickTypes)")
        } else {
           result(FlutterError(code: "INVALID_ARGUMENTS", message: "BPM value missing", details: nil))
        }
    }

    private func handleConfigure(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any] else {
            result(FlutterError(code: "INVALID_ARGUMENTS",
                              message: "Invalid argument format for configure",
                              details: nil))
            return
        }

        let bpm = args["bpm"] as? Int
        let timeSignatureNumerator = args["timeSignatureNumerator"] as? Int
        let timeSignatureDenominator = args["timeSignatureDenominator"] as? Int
        let droneDurationRatio = args["droneDurationRatio"] as? Double
        let isDroning = args["isDroning"] as? Bool

        var tickTypes: [TickType]? = nil
        if let tickTypeStrings = args["tickTypes"] as? [String] {
            tickTypes = tickTypeStrings.compactMap { TickType(from: $0) }
        }

        var subdivision: Subdivision? = nil
        if let subdivisionMap = args["subdivision"] as? [String: Any],
           let name = subdivisionMap["name"] as? String,
           let description = subdivisionMap["description"] as? String,
           let restPattern = subdivisionMap["restPattern"] as? [Bool],
           let durationPattern = subdivisionMap["durationPattern"] as? [Double] {
            subdivision = Subdivision(
                name: name,
                description: description,
                restPattern: restPattern,
                durationPattern: durationPattern
            )
        }

        self.metronome.configure(
            bpm: bpm,
            timeSignatureNumerator: timeSignatureNumerator,
            timeSignatureDenominator: timeSignatureDenominator,
            tickTypes: tickTypes,
            subdivision: subdivision,
            droneDurationRatio: droneDurationRatio,
            isDroning: isDroning
        )

        result("Metronome configured successfully")
    }
}
