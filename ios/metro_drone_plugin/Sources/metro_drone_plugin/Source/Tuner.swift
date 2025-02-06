import SwiftUI
import AVFoundation
import Tuna

class Tuner: ObservableObject, PitchEngineDelegate {
    @Published var currentNote: String = "—"
    @Published var centsOff: Double = 0.0
    @Published var currentOctave: String = "—"
    @Published var frequency: Double = 0.0
    @Published var tuningFrequency: Double = 440.0 {
        didSet {
            MNoteCalculator.Standard.frequency = tuningFrequency
        }
    }
    
    private var pitchEngine: PitchEngine?
    
    init() {
        pitchEngine = PitchEngine(delegate: self)
    }
    
    func start() {
        pitchEngine?.start()
    }
    
    func stop() {
        pitchEngine?.stop()
        reset()
    }
    
    func pitchEngine(_ pitchEngine: PitchEngine, didReceive result: Result<Pitch, Error>) {
        switch result {
        case .success(let pitch):
            do {
                let mPitch = try MPitch(frequency: pitch.frequency)
                self.currentNote = mPitch.note.description
                self.currentOctave = mPitch.note.octave.description
                self.frequency = mPitch.frequency
                self.centsOff = mPitch.closestOffset.cents
            }catch {
                print("MPitchError: \(error.localizedDescription)")
                self.currentNote = "-"
                self.currentOctave = "-"
                self.frequency = 0
                self.centsOff = 0
            }
        case .failure(let error):
            print("Ошибка: \(error.localizedDescription)")
            self.currentNote = "-"
            self.currentOctave = "-"
            self.frequency = 0
            self.centsOff = 0
        }
    }
    
    private func reset() {
        self.currentNote = "—"
        self.currentOctave = "—"
        self.centsOff = 0.0
        self.frequency = 0.0
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
