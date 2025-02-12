import SwiftUI
import AVFoundation

class Tuner: ObservableObject, PitchEngineDelegate {
    @Published var currentNote: String = "—"
    @Published var centsOff: Double = 0.0
    @Published var currentOctave: String = "—"
    @Published var frequency: Double = 0.0
    @Published var tuningFrequency: Double = 440.0 {
        didSet {
            NoteCalculator.Standard.frequency = tuningFrequency
        }
    }

    public var onFieldUpdated: ((String, Any) -> Void)?

    private var pitchEngine: PitchEngine?

    init() {
        pitchEngine = PitchEngine(delegate: self)
    }

    func start() {
        pitchEngine?.levelThreshold = -30
        pitchEngine?.start()
    }

    func stop() {
        pitchEngine?.stop()
        reset()
    }

    // MARK: - PitchEngineDelegate
    func pitchEngine(_ pitchEngine: PitchEngine, didReceive result: Result<Pitch, Error>) {
        switch result {
        case .success(let pitch):
            self.currentNote = pitch.note.description
            self.currentOctave = pitch.note.octave.description
            self.frequency = pitch.frequency
            self.centsOff = pitch.closestOffset.cents

            self.onFieldUpdated?("pitch", [
                "note": self.currentNote,
                "octave": self.currentOctave,
                "frequency": self.frequency,
                "closestOffsetCents": self.centsOff,
            ])
        case .failure(let error):
            print("Error: \(error.localizedDescription)")
            reset()
        }
    }
    
    private func reset() {
        self.currentNote = "—"
        self.currentOctave = "—"
        self.centsOff = 0.0
        self.frequency = 0.0

       self.onFieldUpdated?("pitch", [
            "note": self.currentNote,
            "octave": self.currentOctave,
            "frequency": self.frequency,
            "closestOffsetCents": self.centsOff,
        ])
    }
    
    private func configureAudioSession() {
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playAndRecord, mode: .measurement, options: [.mixWithOthers, .allowBluetooth, .defaultToSpeaker])
            try session.setActive(true, options: .notifyOthersOnDeactivation)
            try session.setPreferredSampleRate(44100) // Убедитесь, что используется 44,100 Гц
            print("Audio session configured successfully.")
        } catch {
            print("Ошибка настройки AVAudioSession: \(error.localizedDescription)")
        }
    }

}
