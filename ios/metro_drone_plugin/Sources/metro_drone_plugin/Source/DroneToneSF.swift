import AVFoundation

class DroneToneSF: ObservableObject {
    private let metronome: Metronome
    private let audioEngine: AVAudioEngine
    private var sampler = AVAudioUnitSampler()
    private var currentNote: UInt8 = 60
    
    @Published var isPlaying: Bool = false
    @Published var isPulsing: Bool = false
    @Published var soundType: SoundType = .sine
    @Published var duration: Double = 0.5
    
    init(audioEngine: AVAudioEngine, metronome: Metronome) {
        self.audioEngine = audioEngine
        self.metronome = metronome
        setupAudioEngine()
        loadSoundFont()
    }
    
    private func setupAudioEngine() {
        audioEngine.attach(sampler)
        let format = audioEngine.mainMixerNode.outputFormat(forBus: 0)
        audioEngine.connect(sampler, to: audioEngine.mainMixerNode, format: format)
        sampler.volume = 1.0
    }
    

    
    func loadSoundFont() {
        guard let url = Bundle.main.url(forResource: soundType.toString(), withExtension: "sf2") else {
            print("SoundFont \(soundType.toString()) не найден")
            return
        }
        
        do {
            try sampler.loadSoundBankInstrument(
                at: url,
                program: 0,
                bankMSB: UInt8(kAUSampler_DefaultMelodicBankMSB),
                bankLSB: UInt8(kAUSampler_DefaultBankLSB)
            )
        } catch {
            print("Ошибка загрузки SoundFont: \(error.localizedDescription)")
        }
    }
    
    func startDrone() {
        isPlaying = true
        print("Fade audio in")
        sampler.startNote(currentNote, withVelocity: 127, onChannel: 0)
        print("Sampler start note")
    }
    
    func stopDrone() {
        print("fadeAudioOut")
        
        for note in 0...127 {
            sampler.stopNote(UInt8(note), onChannel: 0)
        }
        
        isPlaying = false
        print("drone.isPlaying changed to false")
    }

    func fadeAudioIn() {
        let steps = 1000
        for i in 0...steps {
            self.sampler.volume = Float(i)/Float(steps)
        }
    }
    
    func fadeAudioOut() {
        let steps = 1000
        for i in 0...steps {
            self.sampler.volume = Float(steps - i)/Float(steps)
        }
    }
    
    func setSoundType(sound: SoundType) {
        if sound == soundType { return }
        
        let wasPlaying = isPlaying
        let wasPulsing = isPulsing
        
        if wasPlaying {
            stopDrone()
        }
        
        if wasPulsing {
            setPulsing(false)
        }
        
        soundType = sound
        loadSoundFont()

        if wasPlaying {
            self.startDrone()
        }
        
        if wasPulsing {
            self.setPulsing(true)
        }
    }
    
    func setPulsing(_ pulsing: Bool) {
        isPulsing  = pulsing
        
        if isPulsing {
            stopDrone()
            self.metronome.setNoteBuffer(soundType: soundType, note: currentNote)
            self.metronome.startDroning()
        }else {
            self.metronome.stopDroning()
        }
    }
    
    func setNote(note: String, octave: Int) {
        let note = MIDIHelper.midiNote(for: note, octave: octave)
        currentNote = note
        
        if isPlaying {
            stopDrone()
            startDrone()
        }
        
        if isPulsing {
            self.metronome.setNoteBuffer(soundType: soundType, note: currentNote)
        }
    }
}

enum SoundType: String {
    case sine
    case organ
//    case cello
    
    // Метод для получения строки
    func toString() -> String {
        return self.rawValue
    }
}

struct MIDIHelper {
    static let noteMap: [String: Int] = [
        "C": 0, "C#": 1, "D": 2, "D#": 3, "E": 4,
        "F": 5, "F#": 6, "G": 7, "G#": 8, "A": 9,
        "A#": 10, "B": 11
    ]

    static func midiNote(for note: String, octave: Int) -> UInt8 {
        guard let baseNote = noteMap[note] else { return 0 }
        return UInt8((octave + 1) * 12 + baseNote)
    }
    
    // Вычисление частоты звука
    static func frequency(note: String, octave: Int, tuningStandard: Double = 440.0) -> Double {
        // Получаем MIDI-номер ноты
        let midiNote = Int(midiNote(for: note, octave: octave))
        
        // Используем формулу для вычисления частоты
        return tuningStandard * pow(2.0, Double(midiNote - 69) / 12.0)
    }
}
