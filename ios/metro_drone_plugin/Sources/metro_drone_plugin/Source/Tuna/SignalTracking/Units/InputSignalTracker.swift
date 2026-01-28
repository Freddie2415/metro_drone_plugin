import AVFoundation

public enum InputSignalTrackerError: Error {
    case inputNodeMissing
}

class InputSignalTracker: SignalTracker {
    weak var delegate: SignalTrackerDelegate?
    var levelThreshold: Float?

    private let bufferSize: AVAudioFrameCount
    private var audioChannel: AVCaptureAudioChannel?
    private let captureSession = AVCaptureSession()
    private var audioEngine: AVAudioEngine?
    #if os(iOS)
    private let session = AVAudioSession.sharedInstance()
    #endif
    private let bus = 0
    private var isAudioSetup = false

    /// The peak level of the signal
    var peakLevel: Float? {
        audioChannel?.peakHoldLevel
    }

    /// The average level of the signal
    var averageLevel: Float? {
        audioChannel?.averagePowerLevel
    }

    /// The tracker mode
    var mode: SignalTrackerMode {
        .record
    }

    // MARK: - Initialization

    required init(bufferSize: AVAudioFrameCount = 16384, delegate: SignalTrackerDelegate? = nil) {
        self.bufferSize = bufferSize
        self.delegate   = delegate
    }

    // MARK: - Tracking

    func start() throws {
        #if targetEnvironment(simulator)
        // If running in the Simulator, audio capture is generally not supported
        print("Cannot start audio capture on the simulator. Returning.")
        return

        #else

        if !isAudioSetup {
            setupAudio()
            isAudioSetup = true
        }

        // Audio session is now managed by AudioSessionManager
        // No need to configure it here

        audioEngine = AVAudioEngine()

        guard let inputNode = audioEngine?.inputNode else {
            throw InputSignalTrackerError.inputNodeMissing
        }

        let format = inputNode.outputFormat(forBus: bus)
        let tapFormat: AVAudioFormat? = (format.sampleRate > 0 && format.channelCount > 0) ? format : nil

        inputNode.installTap(onBus: bus, bufferSize: bufferSize, format: tapFormat) { [weak self] buffer, time in
            guard let self = self else { return }
            guard let averageLevel = self.averageLevel else { return }

            let levelThreshold = self.levelThreshold ?? -1000000.0

            print("averageLevel: \(averageLevel) | levelThreshold: \(levelThreshold)")
            DispatchQueue.main.async {
                if averageLevel > levelThreshold {
                    self.delegate?.signalTracker(self, didReceiveBuffer: buffer, atTime: time)
                } else {
                    self.delegate?.signalTrackerWentBelowLevelThreshold(self)
                }
            }
        }

        try audioEngine?.start()
        captureSession.startRunning()

        guard captureSession.isRunning == true else {
            throw InputSignalTrackerError.inputNodeMissing
        }

        #endif
    }

    func stop() {
        #if targetEnvironment(simulator)

        print("No audio capture to stop on the simulator.")
        return

        #else

        guard audioEngine != nil else {
            return
        }

        audioEngine?.stop()
        audioEngine?.reset()
        audioEngine = nil
        captureSession.stopRunning()

        #endif
    }

    private func setupAudio() {
        #if targetEnvironment(simulator)
        // If running in the Simulator, we can simply log a message or handle it differently
        print("Running on the Simulator: Audio capture is not supported.")
        return
        #else
        // Attempt to retrieve the default audio capture device
        guard let audioDevice = AVCaptureDevice.default(for: .audio) else {
            print("Audio device is not available.")
            return
        }

        do {
            // Create an input from the audio device
            let audioCaptureInput = try AVCaptureDeviceInput(device: audioDevice)

            // Create an audio output
            let audioOutput = AVCaptureAudioDataOutput()

            // Add the input and output to the capture session
            captureSession.addInput(audioCaptureInput)
            captureSession.addOutput(audioOutput)

            // Retrieve the first available connection and its audio channel
            if let connection = audioOutput.connections.first {
                audioChannel = connection.audioChannels.first
            }
        } catch {
            // Print any errors that occur during device input creation
            debugPrint("Error setting up audio device input:", error)
        }
        #endif
    }
}

#if canImport(Combine)
import Combine

@available(OSX 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
class SignalTrackerPublisher {
    let subject = PassthroughSubject<(AVAudioPCMBuffer, AVAudioTime), Error>()
}

@available(OSX 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
extension SignalTrackerPublisher: SignalTrackerDelegate {
    func signalTracker(_ signalTracker: SignalTracker, didReceiveBuffer buffer: AVAudioPCMBuffer, atTime time: AVAudioTime) {
        subject.send((buffer, time))
    }

    func signalTrackerWentBelowLevelThreshold(_ signalTracker: SignalTracker) {

    }
}

#endif
