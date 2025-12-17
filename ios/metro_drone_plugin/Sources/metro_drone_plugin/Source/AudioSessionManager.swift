import AVFoundation

final class AudioSessionManager {
    static let shared = AudioSessionManager()

    #if os(iOS)
    private let session = AVAudioSession.sharedInstance()
    private var isConfigured = false
    #endif

    private init() {}

    /// Configure audio session once for the entire app lifecycle
    /// This supports ALL scenarios:
    /// - Flutter audio recording (from microphone)
    /// - Flutter audio playback (recorded sound)
    /// - Metronome/Drone playback
    /// - Tuner pitch detection
    /// - External music from other apps (mixWithOthers)
    /// - Bluetooth headsets/AirPods/wired headphones
    func configureOnce() {
        #if os(iOS)
        guard !isConfigured else {
            print("AudioSessionManager: Already configured, skipping")
            return
        }

        do {
            // Universal configuration for music practice app
            // playAndRecord: supports both Flutter recording AND plugin playback/tuner
            // default mode: natural sound processing (can be changed to .measurement for tuner)
            // mixWithOthers: allows external music apps to play simultaneously
            try session.setCategory(
                .playAndRecord,
                mode: .default,
                options: [
                    .mixWithOthers,           // Mix with other apps (background music)
                    .allowBluetooth,          // Bluetooth support
                    .allowBluetoothA2DP,      // High-quality Bluetooth audio
                    .allowAirPlay,            // AirPlay support
                    .defaultToSpeaker         // Use speaker by default (not earpiece)
                ]
            )

            // High-quality audio
            try session.setPreferredSampleRate(44100)
            try session.setPreferredIOBufferDuration(0.01) // 10ms - good balance

            // Activate the session
            try session.setActive(true, options: .notifyOthersOnDeactivation)

            isConfigured = true
            print("AudioSessionManager: Configured once (.playAndRecord, .default, mixWithOthers, 44.1kHz)")
            print("AudioSessionManager: Supports Flutter recording + plugin playback + external music")
        } catch {
            print("AudioSessionManager Error: \(error.localizedDescription)")
        }
        #endif
    }

    /// Switch mode to .measurement for tuner (accurate pitch detection)
    /// Only changes the mode, not the category - keeps recording active
    func enableTunerMode() {
        #if os(iOS)
        do {
            // Only change mode to .measurement - keeps .playAndRecord category
            // This disables system audio processing for accurate frequencies
            // Flutter recording continues to work!
            try session.setCategory(
                .playAndRecord,
                mode: .measurement,
                options: [
                    .mixWithOthers,
                    .allowBluetooth,
                    .allowBluetoothA2DP,
                    .allowAirPlay,
                    .defaultToSpeaker
                ]
            )
            try session.setPreferredIOBufferDuration(0.005) // 5ms for low latency
            print("AudioSessionManager: Switched to .measurement mode for tuner")
        } catch {
            print("AudioSessionManager Error (tuner mode): \(error.localizedDescription)")
        }
        #endif
    }

    /// Switch mode back to .default when tuner stops
    /// Restores natural sound processing for recording/playback
    func disableTunerMode() {
        #if os(iOS)
        do {
            // Return to .default mode - keeps .playAndRecord category
            // Flutter recording continues to work!
            try session.setCategory(
                .playAndRecord,
                mode: .default,
                options: [
                    .mixWithOthers,
                    .allowBluetooth,
                    .allowBluetoothA2DP,
                    .allowAirPlay,
                    .defaultToSpeaker
                ]
            )
            try session.setPreferredIOBufferDuration(0.01) // 10ms back to normal
            print("AudioSessionManager: Switched back to .default mode")
        } catch {
            print("AudioSessionManager Error (default mode): \(error.localizedDescription)")
        }
        #endif
    }
}
