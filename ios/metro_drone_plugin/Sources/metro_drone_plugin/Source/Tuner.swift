import SwiftUI
import AVFoundation

class Tuner: ObservableObject, PitchEngineDelegate {
    @Published var currentNote: String = ""
    @Published var centsOff: Double = 0.0
    @Published var currentOctave: String = ""
    @Published var frequency: Double = 0.0
    @Published var tuningFrequency: Double = 440.0 {
        didSet {
            NoteCalculator.Standard.frequency = tuningFrequency
            self.onFieldUpdated?("tuningFrequency", tuningFrequency)
        }
    }

    public var onFieldUpdated: ((String, Any) -> Void)?

    private var pitchEngine: PitchEngine?

    init() {
        pitchEngine = PitchEngine(delegate: self)
    }

    deinit {
        pitchEngine?.stop()
        pitchEngine = nil
        onFieldUpdated = nil
        print("Tuner deinitialized")
    }

    func start() {
        // Switch to measurement mode for accurate pitch detection
        // This only changes the mode, not the category - Flutter recording continues!
        AudioSessionManager.shared.enableTunerMode()
        pitchEngine?.levelThreshold = -30
        pitchEngine?.start()
    }

    func stop() {
        pitchEngine?.stop()
        // Switch back to default mode - Flutter recording continues!
        AudioSessionManager.shared.disableTunerMode()
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
        self.currentNote = ""
        self.currentOctave = ""
        self.centsOff = 0.0
        self.frequency = 0.0

       self.onFieldUpdated?("pitch", [
            "note": self.currentNote,
            "octave": self.currentOctave,
            "frequency": self.frequency,
            "closestOffsetCents": self.centsOff,
        ])
    }
}
