//
//  LiveDroneTone2.swift
//  metrodrone
//
//  Created by Фаррух Хамракулов on 23/01/25.
//


import SwiftUI
import AVFoundation

class GeneratedDroneTone2: ObservableObject {
    public var onFieldUpdated: ((String, Any) -> Void)?

    // MARK: - Published Properties
    @Published var currentNote: String = "A" {
        didSet {
            onFieldUpdated?("note", currentNote)
        }
    }
    @Published var currentOctave: Int = 4 {
        didSet {
            onFieldUpdated?("octave", currentOctave)
        }
    }
    @Published var frequency: Double = 440.0  // Гц
    @Published var tuningStandartA: Double = 440.0  // Гц
    {
        didSet {
            onFieldUpdated?("tuningStandard", tuningStandartA)
            setNote(note: currentNote, octave: currentOctave)
        }
    }
    @Published var amplitude: Float = 0.5     // От 0.0 до 1.0
    @Published var isPlaying: Bool = false {
        didSet {
            onFieldUpdated?("isPlaying", isPlaying)
        }
    }
    @Published var isPulsing: Bool = false {
        didSet {
            onFieldUpdated?("isPulsing", isPulsing)
        }
    }
    @Published var soundType: SoundType = .sine {
        didSet {
            onFieldUpdated?("soundType", soundType.rawValue)
        }
    }
    
    // MARK: - Private AudioEngine
    private let engine: AVAudioEngine
    private let metronome: Metronome
    private weak var metroDrone: MetroDrone?
    private var sourceNode: AVAudioSourceNode?
    
    // MARK: - Sample Rate
    private let sampleRate: Double = 44_100
    private let bufferDuration: Double = 3.0 // 3 секунды
    
    // MARK: - Phases
    // Отдельные фазы для каждого типа звука
    private var phaseSine:  Double = 0.0
    private var phaseOrgan: [Double] = [0.0, 0.0, 0.0, 0.0] // для 4 гармоник
    private var phaseCello: Double = 0.0
    
    // Чтобы сгладить громкость при старте/остановке
    // Простая огибающая: fadeIn/fadeOut
    private var currentAmplitudeScale: Float = 0.0
    
    // Сколько секунд уходит на fade-in/out
    private let fadeTime: Double = 0.02
    // На сколько увеличивать/уменьшать громкость за сэмпл при старте/остановке
    private lazy var fadeInPerSample:  Float = Float(1.0 / (sampleRate * fadeTime))
    private lazy var fadeOutPerSample: Float = Float(1.0 / (sampleRate * fadeTime))
    
    private let waveTableManager = WaveTableManager(tableSize: 4096)
    
    // MARK: - Init
    init(audioEngine: AVAudioEngine, metronome: Metronome, metroDrone: MetroDrone? = nil) {
        self.engine = audioEngine
        self.metronome = metronome
        self.metroDrone = metroDrone
        setupSourceNode()
    }

    deinit {
        stopDrone()
        onFieldUpdated = nil
        if let node = sourceNode {
            engine.detach(node)
        }
        sourceNode = nil
        print("GeneratedDroneTone2 deinitialized")
    }

    func setMetroDroneReference(_ metroDrone: MetroDrone) {
        self.metroDrone = metroDrone
    }
    
    // MARK: - Setup
    private func setupSourceNode() {
        let audioFormat = engine.mainMixerNode.outputFormat(forBus: 0)
        
        sourceNode = AVAudioSourceNode { [weak self] _, _, frameCount, audioBufferList -> OSStatus in
            guard let self = self else { return noErr }
            
            let ablPointer = UnsafeMutableAudioBufferListPointer(audioBufferList)
            
            for frame in 0..<Int(frameCount) {
                let sampleValue: Float
                
                switch self.soundType {
                case .sine:
                    sampleValue = self.generateSineSample()
                case .organ:
                    sampleValue = self.generateOrganSample(phaseOrgan: &phaseOrgan)
//                case .cello:
//                    sampleValue = self.generateCelloSample()
                }
                
                // Применяем простую огибающую (fade in/out) к результирующему сэмплу
                let finalSample = sampleValue * self.applyFadeEnvelope()
                
                // Записываем finalSample в оба канала
                for channel in 0..<Int(audioFormat.channelCount) {
                    let buffer = ablPointer[channel].mData?.assumingMemoryBound(to: Float.self)
                    buffer?[frame] = finalSample
                }
            }
            
            return noErr
        }
        
        if let sourceNode = sourceNode {
            engine.attach(sourceNode)
            engine.connect(sourceNode, to: engine.mainMixerNode, format: audioFormat)
        }
    }
    
    // MARK: - Generators
    
    /// 1. Sine Wave — непрерывная фаза
    private func generateSineSample() -> Float {
        let phaseIncrement = 2.0 * .pi * frequency / sampleRate
        
        let sample = Float(sin(phaseSine)) * amplitude
        phaseSine += phaseIncrement
        
        if phaseSine > 2.0 * .pi {
            phaseSine -= 2.0 * .pi
        }
        
        return sample
    }
    
    /// 2. Organ (аддитивный синтез). У каждой гармоники своя фаза
    private func generateOrganSample(phaseOrgan: inout [Double]) -> Float {
        // Множители частоты для гармоник
        let harmonics = [1.0, 2.0, 3.0, 4.0]
        // Относительные амплитуды
        let amplitudes: [Float] = [1.0, 0.5, 0.25, 0.125]
        
        var sample: Float = 0.0
        
        // Для каждой гармоники своя фаза
        for i in 0..<harmonics.count {
            let harmFreq  = frequency * harmonics[i]
            let increment = 2.0 * .pi * harmFreq / sampleRate
            
            // Генерируем текущий сэмпл гармоники
            let harmSample = sin(phaseOrgan[i]) * Double(amplitudes[i])
            sample += Float(harmSample) * amplitude
            
            // Обновляем фазу
            phaseOrgan[i] += increment
            if phaseOrgan[i] > 2.0 * .pi {
                phaseOrgan[i] -= 2.0 * .pi
            }
        }
        
        // Чтобы избежать клиппинга
        return max(min(sample, 1.0), -1.0)
    }
    
    /// 3. Cello — пилообразная волна + вибрато + тремоло, непрерывная фаза
    private func generateCelloSample() -> Float {
        // --- Параметры вибрато
        let vibratoRate: Double = 5.0     // Частота вибрато (Гц)
        let vibratoDepth: Double = 0.01   // Глубина вибрато (изменение частоты)
        
        // --- Параметры тремоло
        let tremoloRate: Double = 3.0
        let tremoloDepth: Double = 0.2
        
        // Генерируем вибрато
        let incrementBase = 2.0 * .pi * frequency / sampleRate
        // "Временной" шаг для фазы: здесь phaseCello меняется равномерно, без скачков
        // Но добавим корректировку частоты на vibratoDepth:
        
        // vibratoValue: колеблется в диапазоне [-vibratoDepth, +vibratoDepth]
        let vibratoValue = sin(phaseCello * (vibratoRate / frequency)) * vibratoDepth
        // => effectiveFrequency = frequency * (1 + vibratoValue)
        // => эффективный приращение фазы ~ incrementBase * (1 + vibratoValue)
        
        // Обновим фазу p:
        let actualIncrement = incrementBase * (1.0 + vibratoValue)
        phaseCello += actualIncrement
        if phaseCello > 2.0 * .pi {
            phaseCello -= 2.0 * .pi
        }
        
        // Пилообразная волна на основе phaseCello
        // Переводим phaseCello в диапазон [0..1]:
        let fraction = phaseCello / (2.0 * .pi)
        var sawWave = 2.0 * (fraction - floor(fraction + 0.5))
        
        // Сглаживаем пилообразную волну
        sawWave *= 0.8
        
        // Тремоло = амплитудная модуляция
        // Используем phaseCello как "молодшего" времени?
        // Предположим, сделаем отдельную "фазу" для тремоло, но можно упростить
        let tremPhase = (phaseCello * (tremoloRate / vibratoRate)) // соотношение частот
        let tremValue = 1.0 - (sin(tremPhase) * tremoloDepth)
        
        // Доп. гармоники (1-я, 2-я, 3-я)
        // Можно "притянуть" их к той же фазе, но умножить phaseCello на 2, 3...
        let harmonic1 = sin(phaseCello) * 0.3
        let harmonic2 = sin(2.0 * phaseCello) * 0.2
        let harmonic3 = sin(3.0 * phaseCello) * 0.1
        
        let total = (sawWave + harmonic1 + harmonic2 + harmonic3) * Double(tremValue)
        
        let sample = Float(total) * amplitude
        return max(min(sample, 1.0), -1.0)
    }
    
    // MARK: - Fade Envelope
    
    /// Простая «огибающая» для плавного старта/остановки
    private func applyFadeEnvelope() -> Float {
        // Если дрон играется — стараемся выйти на 1.0
        // Если дрон остановлен — идём к 0.0
        if isPlaying {
            if currentAmplitudeScale < 1.0 {
                currentAmplitudeScale += fadeInPerSample
                if currentAmplitudeScale > 1.0 {
                    currentAmplitudeScale = 1.0
                }
            }
        } else {
            if currentAmplitudeScale > 0.0 {
                currentAmplitudeScale -= fadeOutPerSample
                if currentAmplitudeScale < 0.0 {
                    currentAmplitudeScale = 0.0
                }
            }
        }
        return currentAmplitudeScale
    }
    
    // MARK: - Control
    
    func startDrone() {
        guard !isPlaying else { return }

        metroDrone?.requestAudioEngine(for: "GeneratedDroneTone")

        phaseSine = 0.0
        phaseOrgan = [0.0, 0.0, 0.0, 0.0] // для 4 гармоник
        phaseCello = 0.0
        // Готовимся к плавному fade-in
        // currentAmplitudeScale может быть > 0, если только что было выключено
        // но мы перезапускаем, допустим с 0.0
        currentAmplitudeScale = 0.0

        isPlaying = true
        self.sourceNode?.volume = 1.0
    }
    
    func stopDrone() {
        guard isPlaying else { return }

        // Переводим флаг в false => applyFadeEnvelope() начнёт уменьшать currentAmplitudeScale
        isPlaying = false

        // Не обнуляем фазы сразу, не сбрасываем volume!
        // Ждём в фоновом потоке, пока громкость дойдёт до нуля
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }

            // Ждём, пока плавный фейд-аут завершится
            while self.currentAmplitudeScale > 0.0 {
                // небольшой «сна» в микросекундах, чтобы не грузить процессор вхолостую
                usleep(2000) // 2ms, например
            }

            // Когда currentAmplitudeScale == 0, можно останавливать движок
            // и/или сбрасывать фазы
            self.phaseSine = 0.0
            self.phaseOrgan = [0.0, 0.0, 0.0, 0.0]
            self.phaseCello = 0.0

            // Если хотите именно остановить engine:
            self.sourceNode?.volume = 0.0
            self.metroDrone?.releaseAudioEngine(for: "GeneratedDroneTone")
        }

        print("Generated drone tone stopped.")
    }
    
    func setSoundType(sound: SoundType) {
        if sound == soundType { return }
        
//        let wasPlaying = isPlaying
        let wasPulsing = isPulsing
        
//        if wasPlaying {
//            stopDrone()
//        }
        
        if wasPulsing {
            setPulsing(false)
        }
        
        soundType = sound
//        loadSoundFont()

//        if wasPlaying {
//            self.startDrone()
//        }
        
        if wasPulsing {
            self.setPulsing(true)
        }
    }
    
    func setPulsing(_ pulsing: Bool) {
        isPulsing  = pulsing
        
        if isPulsing {
            stopDrone()
            let buffer = createNoteBuffer()
            metronome.setNoteBuffer(buffer: buffer!)
            self.metronome.startDroning()
        }else {
            self.metronome.stopDroning()
        }
    }
    
    // MARK: - Create Note Buffer
    private func createNoteBuffer() -> AVAudioPCMBuffer? {
        let format = engine.mainMixerNode.outputFormat(forBus: 0)
        let frameCount = AVAudioFrameCount(sampleRate * bufferDuration)
        
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else {
            return nil
        }
        buffer.frameLength = frameCount
        
        let channelCount = Int(format.channelCount)
        let tableSize = Float(waveTableManager.tableSize)
        
        // Выбираем базовую wave-таблицу
        let waveTable: [Float]
        switch soundType {
        case .sine:
            waveTable = waveTableManager.sineTable
        case .organ:
            waveTable = waveTableManager.organTable
        }
        // Для индекса в таблице
        var phaseIndex: Float = 0.0
        
        // Маска (если размер таблицы — степ. двойки)
        let mask = waveTableManager.tableSize - 1
        
        for channel in 0..<channelCount {
            guard let bufferPointer = buffer.floatChannelData?[channel] else { continue }
            
            for frame in 0..<Int(frameCount) {
                // На основе effectiveFreq вычисляем шаг по таблице
                let increment = Float(frequency) * tableSize / Float(sampleRate)
                
                // Чтение из таблицы
                let idx = Int(phaseIndex) & mask
                var sampleValue = waveTable[idx]
                
                sampleValue *= amplitude
                bufferPointer[frame] = sampleValue
                
                // Обновляем фазу в таблице
                phaseIndex += increment
                if phaseIndex >= tableSize {
                    phaseIndex -= tableSize
                }
            }
        }
        print("DRONE BUFFER READY")
        return buffer
    }
    
    func setNote(note: String, octave: Int) {
        currentNote = note
        currentOctave = octave

        frequency = MIDIHelper.frequency(note: note, octave: octave, tuningStandard: tuningStandartA)

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            if self.isPulsing {
                let buffer = self.createNoteBuffer()
                self.metronome.setNoteBuffer(buffer: buffer!)
            }
        }
    }
}


/// Храним таблицы (по одному периоду на волну)
struct WaveTableManager {
    let tableSize: Int
    let sineTable:  [Float]
    let organTable: [Float]
    let celloTable: [Float]
    
    init(tableSize: Int = 4096) {
        self.tableSize  = tableSize
        self.sineTable  = Self.generateSineTable(tableSize: tableSize)
        self.organTable = Self.generateOrganTable(tableSize: tableSize)
        self.celloTable = Self.generateCelloTable(tableSize: tableSize)
    }
    
    // MARK: - Генераторы таблиц
    
    /// 1. Простая синусоида
    private static func generateSineTable(tableSize: Int) -> [Float] {
        (0..<tableSize).map { i in
            let phase = 2.0 * .pi * Double(i) / Double(tableSize)
            return Float(sin(phase))
        }
    }
    
    /// 2. Organ (4 гармоники)
    private static func generateOrganTable(tableSize: Int) -> [Float] {
        let amplitudes: [Double] = [1.0, 0.5, 0.25, 0.125]
        let harmonics:  [Double] = [1.0, 2.0, 3.0, 4.0]
        
        var table = [Float](repeating: 0.0, count: tableSize)
        
        for i in 0..<tableSize {
            let basePhase = 2.0 * .pi * Double(i) / Double(tableSize)
            var sum: Double = 0.0
            for h in 0..<harmonics.count {
                sum += amplitudes[h] * sin(harmonics[h] * basePhase)
            }
            table[i] = Float(sum)
        }
        
        // Нормализуем (чтобы максимум был <= 1.0)
        if let maxVal = table.map({ abs($0) }).max(), maxVal > 0.0001 {
            for k in 0..<tableSize {
                table[k] /= maxVal
            }
        }
        
        return table
    }
    
    /// 3. Cello — базовая «пилообразная» + гармоники
    ///    (Без тремоло/вибрато — их добавим при чтении таблицы)
    private static func generateCelloTable(tableSize: Int) -> [Float] {
        var table = [Float](repeating: 0.0, count: tableSize)
        
        for i in 0..<tableSize {
            // Пилообразная волна
            let fraction = Double(i) / Double(tableSize)
            var saw = 2.0 * (fraction - floor(fraction + 0.5))
            // ослабим пилу, чтобы гармоники сильнее влияли
            saw *= 0.8
            
            // добавим простые гармоники
            let phase = 2.0 * .pi * fraction
            let h1 = 0.3 * sin(phase)
            let h2 = 0.2 * sin(2.0 * phase)
            let h3 = 0.1 * sin(3.0 * phase)
            
            let total = saw + h1 + h2 + h3
            table[i] = Float(total)
        }
        
        // Нормализация
        if let maxVal = table.map({ abs($0) }).max(), maxVal > 0.0001 {
            for k in 0..<tableSize {
                table[k] /= maxVal
            }
        }
        
        return table
    }
}
