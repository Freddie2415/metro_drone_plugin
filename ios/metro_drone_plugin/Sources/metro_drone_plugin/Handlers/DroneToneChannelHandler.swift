import Flutter
import UIKit

class DroneToneChannelHandler: NSObject, FlutterPlugin {
    private let droneTone: GeneratedDroneTone2
    private var methodHandlers: [String: (FlutterMethodCall, @escaping FlutterResult) -> Void] = [:]

    init(droneTone: GeneratedDroneTone2) {
        self.droneTone = droneTone
        super.init()
    }

    static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "metro_drone_plugin/drone_tone", binaryMessenger: registrar.messenger())
        let instance = DroneToneChannelHandler(droneTone: MetroDronePlugin.metroDrone.generatedDroneTone)
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
        self.methodHandlers["setPulsing"] = self.handleSetPulsing
        self.methodHandlers["setNote"] = self.handleSetNote
        self.methodHandlers["setTuningStandard"] = self.handleTuningStandard
        self.methodHandlers["setSoundType"] = self.handleSetSoundType
    }

    private func handleStart(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        self.droneTone.startDrone()
        result("start")
    }

    private func handleStop(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        self.droneTone.stopDrone()
        result("stop")
    }

    private func handleSetPulsing(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        if let isPulsing = call.arguments as? Bool {
            self.droneTone.setPulsing(isPulsing)
            result("isPulsing set to \(isPulsing)")
        } else {
            result(FlutterError(code: "INVALID_ARGUMENTS", message: "isPulsing value missing", details: nil))
        }
    }

    private func handleSetNote(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        if let args = call.arguments as? [String: Any] {
            guard let note = args["note"] as? String,
                  let octave = args["octave"] as? Int else {
                result(FlutterError(code: "INVALID_ARGUMENTS", message: "handleSetNote values missing or incorrect", details: nil))
                return
            }

            self.droneTone.setNote(note: note, octave: octave)
            result("Set Note \(note) \(octave)")
        } else {
            result(FlutterError(code: "INVALID_ARGUMENTS", message: "Invalid argument format", details: nil))
        }
    }

    private func handleTuningStandard(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        if let tuningStandard = call.arguments as? Double {
            self.droneTone.tuningStandartA = tuningStandard
            result("tuningStandardA set to \(tuningStandard)")
        } else {
            result(FlutterError(code: "INVALID_ARGUMENTS", message: "tuningStandard value missing", details: nil))
        }
    }

    private func handleSetSoundType(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        if let soundTypeString = call.arguments as? String {
            let soundType = soundTypeString == "sine" ? SoundType.sine : SoundType.organ
            self.droneTone.setSoundType(sound: soundType)
            result("set sound type to \(soundType)")
        } else {
            result(FlutterError(code: "INVALID_ARGUMENTS", message: "isPulsing value missing", details: nil))
        }
    }
}