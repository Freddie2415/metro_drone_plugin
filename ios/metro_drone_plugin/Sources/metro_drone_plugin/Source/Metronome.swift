import Foundation
import AVFoundation
import SwiftUI

class Metronome: ObservableObject {
    private let audioEngine: AVAudioEngine
    private let tickPlayerNode: AVAudioPlayerNode
    private let tapPlayerNode: AVAudioPlayerNode
    private var regularTickBuffer: AVAudioPCMBuffer?
    private var tapBuffer: AVAudioPCMBuffer?
    private var droneBuffer: AVAudioPCMBuffer?
    private var noteBuffer: AVAudioPCMBuffer?
    private var silenceTickBuffer: AVAudioPCMBuffer?
    private var accentTickBuffer: AVAudioPCMBuffer?
    private var strongAccentTickBuffer: AVAudioPCMBuffer?
    private var beatsBuffer: [AVAudioPCMBuffer] = []
    
    private var tickIndex: Int = 0
    private var tapTimes: [Date] = []
    private var tapTimer: Timer?
    private let tapTempoDetector : DetectTapTempo = DetectTapTempo(timeOut: 1.5, minimumTaps: 3)
    private var startTime: CFTimeInterval?
    
    // Drone Properties
    private var isDroning: Bool = false
    private let renderer: OfflineRenderer
    private var soundType: SoundType = .sine
    private var note: UInt8 = 60
    private var velocity: UInt8 = 127
    private var droneDurationRatio: TimeInterval = 0.5 {
        didSet {
            self.onFieldUpdated?("droneDurationRatio", droneDurationRatio)
        }
    }
    
    // Metronome Properties
    @Published var flash: Bool = false
    @Published var bpm: Int = 120 {
        didSet {
            onFieldUpdated?("bpm", bpm)
        }
    }
    @Published var isPlaying: Bool = false {
        didSet {
            onFieldUpdated?("isPlaying", isPlaying)
        }
    }
    @Published var timeSignatureNumerator: Int = 4 {
        didSet {
            if timeSignatureNumerator > tickTypes.count {
                // Добавляем новые элементы (по умолчанию `.regular`)
                tickTypes.append(contentsOf: Array(repeating: .regular, count: timeSignatureNumerator - tickTypes.count))
            } else if timeSignatureNumerator < tickTypes.count {
                // Срезаем лишние элементы
                tickTypes = Array(tickTypes.prefix(timeSignatureNumerator))
            }
            
            if isPlaying {
                self.stop()
                self.start()
            }

            onFieldUpdated?("timeSignatureNumerator", timeSignatureNumerator)
            onFieldUpdated?("tickTypes", tickTypes.map { String(describing: $0) })
        }
    }
    @Published var timeSignatureDenominator: Int = 4 {
        didSet {
            self.onFieldUpdated?("timeSignatureDenominator", timeSignatureDenominator)
        }
    }
    @Published var currentTick: Int = 0
    @Published var tickTypes: [TickType] = Array(repeating: .accent, count: 4)
    @Published var subdivision: Subdivision = Subdivision(
        name: "Quarter Notes",
        description: "One quarter note per beat",
        restPattern: [true],
        durationPattern: [1.0]
    ) {
        didSet{
            onFieldUpdated?("subdivision", [
                "name": subdivision.name,
                "description": subdivision.description,
                "restPattern": subdivision.restPattern,
                "durationPattern": subdivision.durationPattern,
            ])
            self.prepareBeatsBuffer()
        }
    }
    @Published var subdivisions: [Subdivision] = [
        // 1
        Subdivision(
            name: "Quarter Notes",
            description: "One quarter note per beat",
            restPattern: [true],
            durationPattern: [1.0]
        ),
        // 2
        Subdivision(
            name: "Eighth Notes",
            description: "Two eighth notes",
            restPattern: [true, true],
            durationPattern: [0.5, 0.5]
        ),
        // 3
        Subdivision(
            name: "Sixteenth Notes",
            description: "Four equal sixteenth notes",
            restPattern: [true, true, true, true],
            durationPattern: [0.25, 0.25, 0.25, 0.25]
        ),
        // 4
        Subdivision(
            name: "Triplet",
            description: "Three equal triplets",
            restPattern: [true, true, true],
            durationPattern: [0.34, 0.33, 0.33]
        ),
        // 5
        Subdivision(
            name: "Swing",
            description: "Swing eighth notes (2/3 + 1/3)",
            restPattern: [true, true],
            durationPattern: [0.66, 0.34]
        ),
        // 6
        Subdivision(
            name: "Rest and Eighth Note",
            description: "Rest followed by an eighth note",
            restPattern: [false, true],
            durationPattern: [0.5, 0.5]
        ),
        // 7
        Subdivision(
            name: "Dotted Eighth and Sixteenth",
            description: "Dotted eighth and one sixteenth note",
            restPattern: [true, true],
            durationPattern: [0.75, 0.25]
        ),
        // 8
        Subdivision(
            name: "16th Note & Dotted Eighth",
            description: "One sixteenth note and one dotted eighth",
            restPattern: [true, true],
            durationPattern: [0.25, 0.75]
        ),
        // 9
        Subdivision(
            name: "2 Sixteenth Notes & Eighth Note",
            description: "Two sixteenth notes and one eighth note",
            restPattern: [true, true, true],
            durationPattern: [0.25, 0.25, 0.5]
        ),
        // 10
        Subdivision(
            name: "Eighth Note & 2 Sixteenth Notes",
            description: "One eighth note and two sixteenth notes",
            restPattern: [true, true, true],
            durationPattern: [0.5, 0.25, 0.25]
        ),
        // 11
        Subdivision(
            name: "16th Rest, 16th Note, 16th Rest, 16th Note",
            description: "Alternating silence and sixteenth notes",
            restPattern: [false, true, false, true],
            durationPattern: [0.25, 0.25, 0.25, 0.25]
        ),
        // 12
        Subdivision(
            name: "16th Note, Eighth Note, 16th Note",
            description: "Sixteenth, eighth, and sixteenth notes",
            restPattern: [true, true, true],
            durationPattern: [0.25, 0.5, 0.25]
        ),
        // 13
        Subdivision(
            name: "2 Triplets & Triplet Rest",
            description: "Two triplets followed by a rest",
            restPattern: [true, true, false],
            durationPattern: [0.34, 0.33, 0.33]
        ),
        // 14
        Subdivision(
            name: "Triplet Rest & 2 Triplets",
            description: "Rest for triplet and two triplet notes",
            restPattern: [false, true, true],
            durationPattern: [0.34, 0.33, 0.33]
        ),
        // 15
        Subdivision(
            name: "Triplet Rest, Triplet, Triplet Rest",
            description: "Rest, triplet, and rest",
            restPattern: [false, true, false],
            durationPattern: [0.34, 0.33, 0.33]
        ),
        // 16
        Subdivision(
            name: "Quintuplets",
            description: "Five equal notes in one beat",
            restPattern: [true, true, true, true, true],
            durationPattern: [0.2, 0.2, 0.2, 0.2, 0.2]
        ),
        // 17
        Subdivision(
            name: "Septuplets",
            description: "Seven equal notes in one beat",
            restPattern: [true, true, true, true, true, true, true],
            durationPattern: [0.143, 0.143, 0.143, 0.143, 0.143, 0.143, 0.142]
        )
    ]
    
    
    // ================
    // MARK: - New Scheduling Props
    // ================
    private var bufferSampleRate: Double = 44100.0     // <-- NEW (установим в init)
    private let syncQueue = DispatchQueue(label: "MetronomeQueue")  // <-- NEW

    private var nextBeatSampleTime: Double = 0.0       // <-- NEW
    private var beatsScheduled: Int = 0                // <-- NEW
    private var beatsToScheduleAhead: Int = 2          // <-- NEW (можете менять)
    private var scheduleBeatIndex = 0
    private let mainMixerFormat: AVAudioFormat

    public var onFieldUpdated: ((String, Any) -> Void)?
    public var onTickUpdated: ((Int) -> Void)?

    init(audioEngine: AVAudioEngine) {
        self.audioEngine = audioEngine
        self.renderer = OfflineRenderer()
        self.tickPlayerNode = AVAudioPlayerNode()
        self.tapPlayerNode = AVAudioPlayerNode()
        
        do {
            mainMixerFormat = audioEngine.mainMixerNode.outputFormat(forBus: 0)
            self.bufferSampleRate = mainMixerFormat.sampleRate

            #if SWIFT_PACKAGE
            let resourceBundle = Bundle.module
            #else
            let bundle = Bundle(for: Self.self)
            guard let resourceBundleURL = bundle.url(forResource: "metro_drone_plugin", withExtension: "bundle"),
                  let resourceBundle = Bundle(url: resourceBundleURL) else {
                fatalError("⚠️ Ошибка: не найден ресурсный бандл metro_drone_plugin.bundle")
            }
            #endif

            guard let tickSoundFileURL = resourceBundle.url(forResource: "tick_sound", withExtension: "wav"),
                  let accentTickSoundFileURL = resourceBundle.url(forResource: "accent_sound", withExtension: "wav"),
                  let strongAccentTickSoundFileURL = resourceBundle.url(forResource: "strong_accent_sound", withExtension: "wav"),
                  let tapSoundFileURL = resourceBundle.url(forResource: "tap_sound", withExtension: "wav") else {
                fatalError("⚠️ Ошибка: не удалось загрузить один или несколько звуковых файлов")
            }
            
            self.regularTickBuffer = try createAndResampleBuffer(from: tickSoundFileURL, toFormat: mainMixerFormat)
            self.accentTickBuffer = try createAndResampleBuffer(from: accentTickSoundFileURL, toFormat: mainMixerFormat)
            self.strongAccentTickBuffer = try createAndResampleBuffer(from: strongAccentTickSoundFileURL, toFormat: mainMixerFormat)
            self.tapBuffer = try createAndResampleBuffer(from: tapSoundFileURL, toFormat: mainMixerFormat)
            self.silenceTickBuffer = try createAndResampleBuffer(from: tickSoundFileURL, toFormat: mainMixerFormat)
            
            
            print("regularTickBuffer: \(calculateBufferDuration(buffer: regularTickBuffer!))")
            print("accentTickBuffer: \(calculateBufferDuration(buffer: accentTickBuffer!))")
            print("strongAccentTickBuffer: \(calculateBufferDuration(buffer: strongAccentTickBuffer!))")
            print("tapBuffer: \(calculateBufferDuration(buffer: tapBuffer!))")
            print("silenceTickBuffer: \(calculateBufferDuration(buffer: silenceTickBuffer!))")
        } catch {
            print("Error initializing buffers: \(error)")
        }

        
        setupAudioEngine()
    }
    
    func calculateBufferDuration(buffer: AVAudioPCMBuffer) -> Double {
        let format = buffer.format.sampleRate
        return Double(buffer.frameLength) / format
    }
    
    deinit {
        dispose()
    }
    
    func dispose() {
        stop()
        tapTimer?.invalidate()
        audioEngine.stop()
        tickPlayerNode.stop()
        tapPlayerNode.stop()

        regularTickBuffer = nil
        tapBuffer = nil
        droneBuffer = nil
        noteBuffer = nil
        silenceTickBuffer = nil
        accentTickBuffer = nil
        strongAccentTickBuffer = nil
        beatsBuffer.removeAll()

        print("Audio engine and buffers disposed.")
    }
    
    private func setupAudioEngine() {
        audioEngine.attach(tickPlayerNode)
        audioEngine.attach(tapPlayerNode)

        // Подключаем `playerNode` и `tapPlayerNode` к микшеру
        audioEngine.connect(tickPlayerNode, to: audioEngine.mainMixerNode, format: mainMixerFormat)
        audioEngine.connect(tapPlayerNode, to: audioEngine.mainMixerNode, format: mainMixerFormat)
    }
    
    private func createBuffer(from soundFile: URL) throws -> AVAudioPCMBuffer {
        let audioFile = try AVAudioFile(forReading: soundFile)
        let format = audioFile.processingFormat
        print("FORMAT: \(format)")
        let frameCapacity = AVAudioFrameCount(audioFile.length)
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCapacity) else {
            throw NSError(domain: "Metronome", code: -1, userInfo: [NSLocalizedDescriptionKey: "Unable to create buffer"])
        }
        try audioFile.read(into: buffer)
        return buffer
    }
    
    private func createAndResampleBuffer(from soundFile: URL, toFormat format: AVAudioFormat) throws -> AVAudioPCMBuffer {
        // Открываем аудиофайл
        let audioFile = try AVAudioFile(forReading: soundFile)
        
        // Получаем исходный формат файла
        let sourceFormat = audioFile.processingFormat
        let frameCapacity = AVAudioFrameCount(audioFile.length)
        
        // Создаём буфер для исходного формата
        guard let sourceBuffer = AVAudioPCMBuffer(pcmFormat: sourceFormat, frameCapacity: frameCapacity) else {
            throw NSError(domain: "Metronome", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to create AVAudioPCMBuffer"])
        }
        sourceBuffer.frameLength = frameCapacity
        
        // Читаем аудиофайл в буфер
        try audioFile.read(into: sourceBuffer)
        
        // Если формат совпадает, возвращаем исходный буфер
        if sourceFormat.channelCount == format.channelCount && sourceFormat.sampleRate == format.sampleRate {
            return sourceBuffer
        }
        
        // Иначе делаем ресэмплинг
        let converter = AVAudioConverter(from: sourceFormat, to: format)!
        let resampledFrameCapacity = AVAudioFrameCount(Double(sourceBuffer.frameLength) * format.sampleRate / sourceFormat.sampleRate)
        guard let resampledBuffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: resampledFrameCapacity) else {
            throw NSError(domain: "Metronome", code: -2, userInfo: [NSLocalizedDescriptionKey: "Failed to create resampled AVAudioPCMBuffer"])
        }
        resampledBuffer.frameLength = resampledFrameCapacity
        
        // Выполняем конвертацию
        let inputBlock: AVAudioConverterInputBlock = { _, outStatus in
            outStatus.pointee = .haveData
            return sourceBuffer
        }
        
        converter.convert(to: resampledBuffer, error: nil, withInputFrom: inputBlock)
        
        return resampledBuffer
    }
    
    
    private func createSilentBuffer(from soundFile: URL) throws -> AVAudioPCMBuffer? {
        let buffer = try createBuffer(from: soundFile)
        guard let channelData = buffer.floatChannelData else { return nil }
        
        for channel in 0..<Int(buffer.format.channelCount) {
            for frame in 0..<Int(buffer.frameLength) {
                channelData[channel][frame] *= 0.0 // volume
            }
        }
        
        return buffer
    }
    
    func start() {
        guard !isPlaying else { return }

        do {
            try audioEngine.start()
        } catch {
            print("Ошибка при запуске аудио движка: \(error)")
        }

        isPlaying = true
        tickIndex = 0
        currentTick = 0
        nextBeatSampleTime = 0
        beatsScheduled = 0
        
        prepareBeatsBuffer()
        
        // Синхронно запланируем биты
        bIndex = 0
        syncQueue.async {
            self.scheduleBeats()
        }
        
        print("Metronome started with BPM: \(bpm).")
    }
    
    func stop() {
        guard isPlaying else { return }
        isPlaying = false
        tickPlayerNode.stop()
        beatsScheduled = 0
        nextBeatSampleTime = 0
        tickIndex = 0
        print("Metronome stopped.")
    }
    
    func startDroning() {
        isDroning = true
        prepareBeatsBuffer()
    }
    
    func stopDroning() {
        isDroning = false
        prepareBeatsBuffer()
    }
    
    private func resampleBuffer(_ buffer: AVAudioPCMBuffer, toFormat format: AVAudioFormat) -> AVAudioPCMBuffer? {
        let converter = AVAudioConverter(from: buffer.format, to: format)!
        let frameCapacity = AVAudioFrameCount(format.sampleRate * Double(buffer.frameLength) / buffer.format.sampleRate)
        guard let resampledBuffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCapacity) else {
            print("Failed to create resampled buffer.")
            return nil
        }
        resampledBuffer.frameLength = frameCapacity
        
        let inputBlock: AVAudioConverterInputBlock = { _, outStatus in
            outStatus.pointee = .haveData
            return buffer
        }
        
        converter.convert(to: resampledBuffer, error: nil, withInputFrom: inputBlock)
        
        return resampledBuffer
    }

    
    private func prepareBeatsBuffer() {
        var preparedBuffers: [AVAudioPCMBuffer] = []
        var preparedDroneBuffers: [AVAudioPCMBuffer] = []
        
        for beatIndex in 0..<tickTypes.count {
            let beatBuffer: AVAudioPCMBuffer = generateBeatBuffer(
                bpm: bpm,
                tickType: tickTypes[beatIndex],
                subdivision: subdivision,
                beatIndex: beatIndex
            )!
            preparedBuffers.append(beatBuffer)
            
            let droneBuffer: AVAudioPCMBuffer? = generateDroneBuffer(
                bpm: bpm,
                tickType: tickTypes[beatIndex],
                subdivision: subdivision,
                droneDurationRatio: droneDurationRatio
            )
            
            if droneBuffer != nil {
                preparedDroneBuffers.append(droneBuffer!)
            }else {
                preparedDroneBuffers.append(beatBuffer)
            }
            
            if isDroning {
                let mixBuffer = mixAudioBuffers(buffer1: beatBuffer, buffer2: droneBuffer!)
                print("IS DRONING: \(isDroning) MIX BUFFER: \(mixBuffer.debugDescription)")
                preparedBuffers[beatIndex] = mixBuffer  ?? beatBuffer
            }
        }
        
        beatsBuffer = preparedBuffers
        print("BEAT BUFFER & DroneBeat BUFFER PREPARED")
    }
    
    var bIndex: Int = 0
    
    // ================
    // MARK: - scheduleBeats (по аналогии с Apple)
    // ================
    private func scheduleBeats() {
        // Если не играем — прерываемся
        guard isPlaying else { return }
        
        // Пока не поставили в очередь нужное количество битов (beatsToScheduleAhead)
        while beatsScheduled < beatsToScheduleAhead {
            // Сколько секунд на 1 бит
            let secondsPerBeat = 60.0 / Double(bpm)
            // Переводим секунды в сэмплы
            let samplesPerBeat = secondsPerBeat * bufferSampleRate
            
            // Момент (в сэмплах) когда надо начать проигрывать следующий бит
            let beatSampleTime = AVAudioFramePosition(nextBeatSampleTime)
            // Создаём AVAudioTime для точной привязки
            let playerBeatTime = AVAudioTime(sampleTime: beatSampleTime, atRate: bufferSampleRate)
            
            let buffer = beatsBuffer[bIndex % beatsBuffer.count]
            bIndex += 1
            
            // Ставим буфер в очередь
            tickPlayerNode.scheduleBuffer(
                buffer,
                at: playerBeatTime,
                options: .interrupts,
                completionCallbackType: .dataConsumed
            ) { [weak self] _ in
                guard let self = self else { return }
                self.syncQueue.async {
                    self.beatsScheduled -= 1
                    // Попробуем дозапланировать ещё биты (если всё ещё играем)
                    if self.tickIndex + 1 >= self.tickTypes.count {
                        self.tickIndex = 0
                    } else {
                        self.tickIndex += 1
                    }
                    // Переходим к следующему биту
                    self.scheduleBeats()
                }
            }
            
            beatsScheduled += 1
            // ——— Вызов «колбэка» для UI в момент звучания ———
            // Считаем, какой будет текущий бит (для UI)
            let callbackTick = tickIndex
            
            if let nodeBeatTime = tickPlayerNode.nodeTime(forPlayerTime: playerBeatTime) {
                // Узнаём задержку (latency) для более точного расчёта
                let output = audioEngine.outputNode
                let latencyHostTicks = AVAudioTime.hostTime(forSeconds: output.presentationLatency)
                
                // Когда реально прозвучит (учитывая задержку устройства)
                let dispatchTime = DispatchTime(uptimeNanoseconds: nodeBeatTime.hostTime + latencyHostTicks)
                
                // Ставим задачу обновления UI
                DispatchQueue.global(qos: .userInitiated).asyncAfter(deadline: dispatchTime) {
                    guard self.isPlaying else { return }
                    // Обновим UI на главной очереди
                    DispatchQueue.main.async {
                        self.currentTick = callbackTick + 1
                        self.flash.toggle()
                        self.onTickUpdated?(self.currentTick)
                    }
                }
            }
            
            // Если плеер ещё не запущен, то запускаем
            if !tickPlayerNode.isPlaying {
                tickPlayerNode.play()
            }
            
            // ————————————————————————————————
            
            // Сдвигаем `nextBeatSampleTime` (т. е. «куда» будем ставить следующий бит)
            nextBeatSampleTime += samplesPerBeat
        }
    }
    
    func generateDroneBuffer(
        bpm: Int,
        tickType: TickType,
        subdivision: Subdivision,
        droneDurationRatio: Double
    ) -> AVAudioPCMBuffer? {
        guard let droneTickBuffer = self.noteBuffer ?? self.silenceTickBuffer else {
            print("Error: noteBuffer is not initialized.")
            return nil
        }

        let audioFormat = mainMixerFormat
        let sampleRate = audioFormat.sampleRate

        // framesPerTick = сколько фреймов занимает одна доля
        let framesPerTick = Int(sampleRate * 60.0 / Double(bpm))

        // Общая длина буфера = framesPerTick * количество subdivision
        let frameCapacity = framesPerTick

        guard let tactBuffer = AVAudioPCMBuffer(
            pcmFormat: audioFormat,
            frameCapacity: AVAudioFrameCount(frameCapacity)
        ) else {
            print("Error: Failed to create AVAudioPCMBuffer.")
            return nil
        }
        tactBuffer.frameLength = AVAudioFrameCount(frameCapacity)

        // Очищаем буфер нулями (тишиной)
        if let channelData = tactBuffer.floatChannelData {
            for ch in 0..<Int(audioFormat.channelCount) {
                memset(channelData[ch], 0, Int(tactBuffer.frameLength) * MemoryLayout<Float>.size)
            }
        }

        // Бежим по subdivision (например, [0.5, 0.5])
        var subOffset = 0
        for (subIndex, duration) in subdivision.durationPattern.enumerated() {
            let subFrames = Int(Double(framesPerTick) * duration) // Сколько фреймов в этой поддоле
            let soundFrames = Int(Double(subFrames) * droneDurationRatio) // Фреймы звука
//            let silenceFrames = subFrames - soundFrames // Остальные фреймы тишины
            let startFrame = subOffset

            // Проверяем, должен ли звучать звук в этой поддоле
            let tickBuffer: AVAudioPCMBuffer = droneTickBuffer
            let isSilence = tickType == .silence
            let isRest = (subdivision.restPattern[subIndex] == false)
            let isAccent = subIndex == 0 && (tickType == .accent || tickType == .strongAccent)
            let isFirstAccentedBeat = subIndex == 0 && isAccent
            let shouldSound = !isSilence && (!isRest || isFirstAccentedBeat)

            if shouldSound {
                let fadeInDuration = min(1024, soundFrames / 10) // Первые 10% звука или максимум 1024 фреймов
                let fadeOutDuration = min(1024, soundFrames / 10) // Последние 10% звука или максимум 1024 фреймов

                for frame in 0..<soundFrames {
                    let targetFrameIndex = startFrame + frame
                    if targetFrameIndex < frameCapacity {
                        for ch in 0..<Int(audioFormat.channelCount) {
                            var sample = tickBuffer.floatChannelData?[ch][frame % Int(tickBuffer.frameLength)] ?? 0.0
                            
                            // Применяем fade-in
                            if frame < fadeInDuration {
                                sample *= Float(frame) / Float(fadeInDuration)
                            }
                            
                            // Применяем fade-out
                            if frame >= soundFrames - fadeOutDuration {
                                let fadeOutFactor = Float(soundFrames - frame) / Float(fadeOutDuration)
                                sample *= fadeOutFactor
                            }
                            
                            tactBuffer.floatChannelData?[ch][targetFrameIndex] = sample
                        }
                    }
                }
            }

            // Сдвигаем subOffset на длину текущей поддоли
            subOffset += subFrames
        }
        
        return tactBuffer
    }
    
    func generateBeatBuffer(bpm: Int, tickType: TickType, subdivision: Subdivision, beatIndex: Int) -> AVAudioPCMBuffer? {
        let audioFormat = mainMixerFormat
        let sampleRate = audioFormat.sampleRate
        
        // framesPerTick = сколько фреймов занимает одна доля
        let framesPerTick = Int(sampleRate * 60.0 / Double(bpm))
        
        // Всего долей в такте = tickTypes.count (например, 4 при 4/4)
        // Общая длина буфера = framesPerTick * 4 (для 4/4)
        let frameCapacity = framesPerTick
        
        guard let tactBuffer = AVAudioPCMBuffer(
            pcmFormat: audioFormat,
            frameCapacity: AVAudioFrameCount(frameCapacity)
        ) else {
            print("Error: Failed to create AVAudioPCMBuffer.")
            return nil
        }
        tactBuffer.frameLength = AVAudioFrameCount(frameCapacity)
        
        // 2. Очищаем тактовый буфер (на всякий случай) нулями:
        if let channelData = tactBuffer.floatChannelData {
            for ch in 0..<Int(audioFormat.channelCount) {
                memset(channelData[ch], 0, Int(tactBuffer.frameLength) * MemoryLayout<Float>.size)
            }
        }
        
        // Базовый offset в итоговом буфере, с которого начинается эта доля
        let baseOffset = 0 * framesPerTick
        
        // Функция, которая вернёт нужный буфер для первой поддоли и для последующих
        func bufferFor(subIndex: Int) -> AVAudioPCMBuffer? {
            switch tickType {
            case .silence:
                // Все subdivision - silence
                return silenceTickBuffer
            case .regular:
                // Все subdivision - regular
                return regularTickBuffer
            case .accent:
                // Первая поддоля (subIndex == 0) - accent, остальные - regular
                return subIndex == 0 ? accentTickBuffer : regularTickBuffer
            case .strongAccent:
                // Первая поддоля - strongAccent, остальные - regular
                return subIndex == 0 ? strongAccentTickBuffer : regularTickBuffer
            }
        }
        
        // 4. Бежим по субдолям (subdivision), например 2 штуки [0.5, 0.5]
        var subOffset = 0
        for (subIndex, duration) in subdivision.durationPattern.enumerated() {
            
            let subFrames = Int(Double(framesPerTick) * duration) // Сколько фреймов в этой поддоле
            let startFrame = baseOffset + subOffset
            
            // Берём нужный буфер
            let tickBuffer = bufferFor(subIndex: subIndex)
            
            // Проверяем restPattern (если оно у вас используется)
            let isSilence = tickType == .silence
            let isRest = (subdivision.restPattern[subIndex] == false)
            let isAccent = subIndex == 0 && (tickType == .accent || tickType == .strongAccent)
            
            let isFirstAccentedBeat = subIndex == 0 && isAccent
            let shouldSound = !isSilence && (!isRest || isFirstAccentedBeat)
            
            if let tickBuffer = tickBuffer, shouldSound {
                
                // Копируем содержимое tickBuffer в tactBuffer
                // Но tickBuffer может быть короче (или длиннее) subFrames.
                // Обычно wav «короткий», например 10-15ms. Мы можем либо зациклить, либо обрубить...
                // Простейший вариант: копируем min(subFrames, tickBuffer.frameLength) фреймов.
                let framesToCopy = min(subFrames, Int(tickBuffer.frameLength))
                
                for frame in 0..<framesToCopy {
                    let targetFrameIndex = startFrame + frame
                    if targetFrameIndex < frameCapacity {
                        for ch in 0..<Int(audioFormat.channelCount) {
                            let sample = tickBuffer.floatChannelData?[ch][frame] ?? 0.0
                            tactBuffer.floatChannelData?[ch][targetFrameIndex] = sample
                        }
                    }
                }
                
                // Если хотим, чтобы оставшаяся часть subFrames была тишиной, ничего не делаем.
                // Если хотим зациклить звук, нужно вручную продолжить копирование.
            } else {
                // Если isRest == true ИЛИ tickBuffer == nil => тишина
                // (а у нас уже буфер заполнен нулями)
            }
            
            // Сдвигаем subOffset на длину этой поддоли
            subOffset += subFrames
        }
        
        return tactBuffer
    }
    
    func setBPM(_ newBPM: Int) {
        DispatchQueue.main.async {
            self.bpm = max(20, min(newBPM, 400))
            print("BPM set to: \(self.bpm)")
            if self.isPlaying {
                DispatchQueue.global(qos: .userInitiated).async {
                    self.prepareBeatsBuffer()
                    let beatSampleTime = AVAudioFramePosition(self.nextBeatSampleTime)
                    let playerBeatTime = AVAudioTime(sampleTime: beatSampleTime, atRate: self.bufferSampleRate)
                    
                    self.tickPlayerNode.play(at: playerBeatTime)
                }
            }
        }
    }
    
    func setNoteBuffer(soundType: SoundType = .sine, note: UInt8) {
        do {
            // Загружаем SoundFont и первый пресет
            try renderer.loadSoundFont(named: soundType.toString(), preset: 0)
            
            if let buffer = try renderer.renderToBuffer(note: note, velocity: velocity, duration: 5.0, outputFormat: mainMixerFormat) {
                print("Set note buffer created \(soundType) \(note)! Frames: \(buffer.frameLength)")
                self.noteBuffer = buffer
                prepareBeatsBuffer()
            }
        } catch {
            print("Ошибка создания буфера: \(error.localizedDescription)")
        }
    }
    
    func setNoteBuffer(buffer: AVAudioPCMBuffer) {
        self.noteBuffer = buffer
        prepareBeatsBuffer()
    }
    
    func setDroneDurationRatio(_ newRation: TimeInterval) {
        droneDurationRatio = max(0.1, min(0.99, newRation))
        prepareBeatsBuffer()
    }
    
    func setNextTickType(tickIndex: Int) {
        DispatchQueue.main.async {
            guard tickIndex >= 0 && tickIndex < self.tickTypes.count else {
                print("Index out of bounds")
                return
            }
            
            // Получаем текущий тип
            let currentType = self.tickTypes[tickIndex]
            
            // Находим следующий тип циклично
            if let currentIndex = TickType.allCases.firstIndex(of: currentType) {
                let nextIndex = (currentIndex + 1) % TickType.allCases.count
                self.tickTypes[tickIndex] = TickType.allCases[nextIndex]

                self.onFieldUpdated?("tickTypes", self.tickTypes.map { String(describing: $0) })
            }
            
            if self.isPlaying {
                self.prepareBeatsBuffer()
            }
        }
    }
    
    func setTickTypes(tickTypes: [TickType]) {
        self.tickTypes = tickTypes
        self.onFieldUpdated?("tickTypes", tickTypes.map { String(describing: $0) })
        if self.isPlaying {
            self.prepareBeatsBuffer()
        }
    }
    
    func tap() {
        if let bpm = tapTempoDetector.addTap() {
            setBPM(Int(bpm)) // Устанавливаем рассчитанный BPM
            print("Detected BPM from tap: \(bpm)")
            
            tapTimer?.invalidate() // Очищаем предыдущий таймер, если он есть
            
            // Рассчитываем интервал на основе текущего BPM
            let interval = 60.0 / bpm
            
            // Автоматически запускаем метроном через рассчитанный интервал
            tapTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: false) { [weak self] _ in
                guard let self = self else { return }
                if !self.isPlaying {
                    self.start()
                    print("Metronome started with detected BPM.")
                }
            }
        } else {
            print("Not enough taps to calculate BPM.")
        }
        
        playTapSound()
    }
    
    func mixAudioBuffers(buffer1: AVAudioPCMBuffer, buffer2: AVAudioPCMBuffer) -> AVAudioPCMBuffer? {
        guard buffer1.format == buffer2.format else {
            print("Buffers must have the same format to mix.")
            return nil
        }
        
        let format = buffer1.format
        let frameLength = max(buffer1.frameLength, buffer2.frameLength)
        
        guard let mixedBuffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameLength) else {
            print("Failed to create mixed buffer.")
            return nil
        }
        
        mixedBuffer.frameLength = frameLength
        
        let channels = Int(format.channelCount)
        
        for channel in 0..<channels {
            let buffer1Pointer = buffer1.floatChannelData![channel]
            let buffer2Pointer = buffer2.floatChannelData![channel]
            let mixedPointer = mixedBuffer.floatChannelData![channel]
            
            for frame in 0..<Int(frameLength) {
                let sample1 = frame < Int(buffer1.frameLength) ? buffer1Pointer[frame] : 0
                let sample2 = frame < Int(buffer2.frameLength) ? buffer2Pointer[frame] : 0
                
                // Суммируем звуки
                mixedPointer[frame] = sample1 + sample2
            }
        }
        
        return mixedBuffer
    }
    
    private func playTapSound() {
        guard let buffer = tapBuffer else {
            print("Tick buffer is not initialized.")
            return
        }
        tapPlayerNode.stop()
        tapPlayerNode.scheduleBuffer(buffer, at: nil, options: .interrupts, completionHandler: nil)
        tapPlayerNode.play()
        print("Tap sound played.")
    }


}
