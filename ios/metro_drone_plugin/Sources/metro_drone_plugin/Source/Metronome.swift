import Foundation
import AVFoundation
import SwiftUI

class Metronome: ObservableObject {
    // MARK: - Constants
    private static let fadeFramesDuration = 1024
    private static let fadePercentage = 0.1  // 10% of sound frames
    private static let minBPM = 20
    private static let maxBPM = 400
    private static let minDroneDurationRatio = 0.1
    private static let maxDroneDurationRatio = 0.99

    private let audioEngine: AVAudioEngine
    let tickPlayerNode: AVAudioPlayerNode
    private let tapPlayerNode: AVAudioPlayerNode
    private var regularTickBuffer: AVAudioPCMBuffer?
    private var tapBuffer: AVAudioPCMBuffer?
    private var droneBuffer: AVAudioPCMBuffer?
    private let noteBufferLock = NSLock()
    private var _noteBuffer: AVAudioPCMBuffer?
    private var noteBuffer: AVAudioPCMBuffer? {
        get { noteBufferLock.lock(); defer { noteBufferLock.unlock() }; return _noteBuffer }
        set { noteBufferLock.lock(); _noteBuffer = newValue; noteBufferLock.unlock() }
    }
    private var silenceTickBuffer: AVAudioPCMBuffer?
    private var accentTickBuffer: AVAudioPCMBuffer?
    private var strongAccentTickBuffer: AVAudioPCMBuffer?
    private var beatsBuffer: [AVAudioPCMBuffer] = []
    private let beatsBufferLock = NSLock()

    private var tickIndex: Int = 0
    private var tapTimes: [Date] = []
    private var tapTimer: Timer?
    private let tapTempoDetector : DetectTapTempo = DetectTapTempo(timeOut: 1.5, minimumTaps: 3)
    private var startTime: CFTimeInterval?

    // Drone Properties
    private let renderer: OfflineRenderer
    private var soundType: SoundType = .sine
    private var note: UInt8 = 60
    private var velocity: UInt8 = 127
    
    // Metronome Properties
    @Published var flash: Bool = false
    @Published var isPlaying: Bool = false {
        didSet {
            onFieldUpdated?("isPlaying", isPlaying)
        }
    }
    @Published var currentTick: Int = 0

    // Unified configuration structure
    @Published var configuration: MetronomeConfiguration = .default {
        didSet {
            // Notify Flutter about configuration changes
            onFieldUpdated?("bpm", configuration.bpm)
            onFieldUpdated?("timeSignatureNumerator", configuration.timeSignatureNumerator)
            onFieldUpdated?("timeSignatureDenominator", configuration.timeSignatureDenominator)
            onFieldUpdated?("tickTypes", configuration.tickTypes.map { String(describing: $0) })
            onFieldUpdated?("subdivision", [
                "name": configuration.subdivision.name,
                "description": configuration.subdivision.description,
                "restPattern": configuration.subdivision.restPattern,
                "durationPattern": configuration.subdivision.durationPattern,
            ])
            onFieldUpdated?("droneDurationRatio", configuration.droneDurationRatio)
            onFieldUpdated?("isDroning", configuration.isDroning)

            // Handle time signature numerator changes
            if oldValue.timeSignatureNumerator != configuration.timeSignatureNumerator {
                if isPlaying {
                    self.stop()
                    self.start()
                }
            }

            // Regenerate buffers only once when configuration changes
            if oldValue != configuration {
                prepareBeatsBufferAsync()
            }
        }
    }

    // Computed properties for backward compatibility
    var bpm: Int {
        get { configuration.bpm }
        set {
            var newConfig = configuration
            newConfig.bpm = max(Self.minBPM, min(newValue, Self.maxBPM))
            configuration = newConfig
        }
    }

    var timeSignatureNumerator: Int {
        get { configuration.timeSignatureNumerator }
        set {
            var newConfig = configuration
            newConfig.timeSignatureNumerator = newValue
            // Adjust tickTypes count to match new numerator
            if newValue > newConfig.tickTypes.count {
                newConfig.tickTypes.append(contentsOf: Array(repeating: .regular, count: newValue - newConfig.tickTypes.count))
            } else if newValue < newConfig.tickTypes.count {
                newConfig.tickTypes = Array(newConfig.tickTypes.prefix(newValue))
            }
            configuration = newConfig
        }
    }

    var timeSignatureDenominator: Int {
        get { configuration.timeSignatureDenominator }
        set {
            var newConfig = configuration
            newConfig.timeSignatureDenominator = newValue
            configuration = newConfig
        }
    }

    var tickTypes: [TickType] {
        get { configuration.tickTypes }
        set {
            var newConfig = configuration
            newConfig.tickTypes = newValue
            configuration = newConfig
        }
    }

    var subdivision: Subdivision {
        get { configuration.subdivision }
        set {
            var newConfig = configuration
            newConfig.subdivision = newValue
            configuration = newConfig
        }
    }

    var isDroning: Bool {
        get { configuration.isDroning }
        set {
            var newConfig = configuration
            newConfig.isDroning = newValue
            configuration = newConfig
        }
    }

    var droneDurationRatio: Double {
        get { configuration.droneDurationRatio }
        set {
            var newConfig = configuration
            newConfig.droneDurationRatio = max(Self.minDroneDurationRatio,
                                               min(Self.maxDroneDurationRatio, newValue))
            configuration = newConfig
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
    private let bufferPrepQueue = DispatchQueue(label: "MetronomeBufferPrepQueue", qos: .userInitiated)
    private var bufferPrepWorkItem: DispatchWorkItem?

    private var nextBeatSampleTime: Double = 0.0       // <-- NEW
    private var beatsScheduled: Int = 0                // <-- NEW
    private var beatsToScheduleAhead: Int = 2          // <-- NEW (можете менять)
    private var scheduleBeatIndex = 0
    private let mainMixerFormat: AVAudioFormat
    private weak var metroDrone: MetroDrone?

    // Thread-safe beat index using atomic operations
    private let bIndexLock = NSLock()
    private var _bIndex: Int = 0
    private var bIndex: Int {
        get {
            bIndexLock.lock()
            defer { bIndexLock.unlock() }
            return _bIndex
        }
        set {
            bIndexLock.lock()
            defer { bIndexLock.unlock() }
            _bIndex = newValue
        }
    }

    public var onFieldUpdated: ((String, Any) -> Void)?
    public var onTickUpdated: ((Int) -> Void)?

    init(audioEngine: AVAudioEngine, metroDrone: MetroDrone? = nil) {
        self.audioEngine = audioEngine
        self.metroDrone = metroDrone
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

    func setMetroDroneReference(_ metroDrone: MetroDrone) {
        self.metroDrone = metroDrone
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

        // Cancel any pending buffer preparation tasks
        bufferPrepWorkItem?.cancel()
        bufferPrepWorkItem = nil

        // audioEngine is owned by MetroDrone, should not be stopped here
        tickPlayerNode.stop()
        tapPlayerNode.stop()

        // Clear callbacks to prevent retain cycles
        onFieldUpdated = nil
        onTickUpdated = nil

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
        guard let converter = AVAudioConverter(from: sourceFormat, to: format) else {
            throw NSError(domain: "Metronome", code: -3, userInfo: [NSLocalizedDescriptionKey: "Failed to create audio converter from \(sourceFormat) to \(format)"])
        }
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

        guard let metroDrone = metroDrone else {
            print("⚠️ Warning: MetroDrone reference is nil, cannot start metronome")
            return
        }

        metroDrone.requestAudioEngine(for: "Metronome")

        isPlaying = true
        tickIndex = 0
        currentTick = 0
        nextBeatSampleTime = 0
        beatsScheduled = 0

        // Async buffer preparation to avoid blocking UI
        bufferPrepQueue.async { [weak self] in
            guard let self = self else { return }

            if self.beatsBuffer.isEmpty {
                self.prepareBeatsBuffer()
            }

            // Schedule beats after buffers are ready
            self.bIndex = 0
            self.syncQueue.async {
                self.scheduleBeats()
            }

            print("Metronome started with BPM: \(self.bpm).")
        }
    }
    
    func stop() {
        guard isPlaying else { return }
        isPlaying = false
        tickPlayerNode.stop()
        beatsScheduled = 0
        nextBeatSampleTime = 0
        tickIndex = 0

        if let metroDrone = metroDrone {
            metroDrone.releaseAudioEngine(for: "Metronome")
        } else {
            print("⚠️ Warning: MetroDrone reference is nil, cannot release audio engine")
        }

        print("Metronome stopped.")
    }

    func setPulsarMode(isPulsing: Bool) {
        isDroning = isPulsing;
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

        // Атомарная замена с синхронизацией
        beatsBufferLock.lock()
        beatsBuffer = preparedBuffers
        beatsBufferLock.unlock()

        print("BEAT BUFFER & DroneBeat BUFFER PREPARED")
    }

    /// Thread-safe async buffer preparation
    /// Always use this method instead of calling prepareBeatsBuffer() directly
    /// to avoid blocking UI and audio threads
    private func prepareBeatsBufferAsync() {
        // Отменяем предыдущую задачу, если она ещё не выполнена
        bufferPrepWorkItem?.cancel()

        let workItem = DispatchWorkItem { [weak self] in
            guard let self = self else { return }
            self.prepareBeatsBuffer()
        }
        bufferPrepWorkItem = workItem

        bufferPrepQueue.async(execute: workItem)
    }

    // ================
    // MARK: - scheduleBeats (по аналогии с Apple)
    // ================
    private func scheduleBeats() {
        // Если не играем или engine остановлен — прерываемся (fix MODACITY-NP)
        guard isPlaying && audioEngine.isRunning else { return }

        // Пока не поставили в очередь нужное количество битов (beatsToScheduleAhead)
        while beatsScheduled < beatsToScheduleAhead && isPlaying && audioEngine.isRunning {
            // Сколько секунд на 1 бит
            let secondsPerBeat = 60.0 / Double(bpm)
            // Переводим секунды в сэмплы
            let samplesPerBeat = secondsPerBeat * bufferSampleRate
            
            // Момент (в сэмплах) когда надо начать проигрывать следующий бит
            let beatSampleTime = AVAudioFramePosition(nextBeatSampleTime)
            // Создаём AVAudioTime для точной привязки
            let playerBeatTime = AVAudioTime(sampleTime: beatSampleTime, atRate: bufferSampleRate)

            // Читаем буфер с синхронизацией
            beatsBufferLock.lock()
            guard !beatsBuffer.isEmpty else {
                beatsBufferLock.unlock()
                return
            }
            let buffer = beatsBuffer[bIndex % beatsBuffer.count]
            beatsBufferLock.unlock()

            bIndex += 1

            // Проверяем состояние перед планированием (fix MODACITY-NP)
            guard isPlaying && audioEngine.isRunning else { return }

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
                DispatchQueue.global(qos: .userInitiated).asyncAfter(deadline: dispatchTime) { [weak self] in
                    guard let self = self, self.isPlaying else { return }
                    // Обновим UI на главной очереди
                    DispatchQueue.main.async { [weak self] in
                        guard let self = self else { return }
                        self.currentTick = callbackTick + 1
                        self.flash.toggle()
                        self.onTickUpdated?(self.currentTick)
                    }
                }
            }
            
            // Если плеер ещё не запущен, то запускаем (fix MODACITY-NP: проверяем engine)
            if !tickPlayerNode.isPlaying && audioEngine.isRunning && isPlaying {
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
                let fadeInDuration = min(Self.fadeFramesDuration, Int(Double(soundFrames) * Self.fadePercentage))
                let fadeOutDuration = min(Self.fadeFramesDuration, Int(Double(soundFrames) * Self.fadePercentage))

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
    
    /// Batch configuration method for optimized buffer preparation
    /// Call this method to set multiple parameters at once, triggering buffer regeneration only once
    func configure(
        bpm: Int? = nil,
        timeSignatureNumerator: Int? = nil,
        timeSignatureDenominator: Int? = nil,
        tickTypes: [TickType]? = nil,
        subdivision: Subdivision? = nil,
        droneDurationRatio: Double? = nil,
        isDroning: Bool? = nil
    ) {
        var newConfig = configuration

        if let bpm = bpm {
            newConfig.bpm = max(Self.minBPM, min(bpm, Self.maxBPM))
            print("BPM configured to: \(newConfig.bpm)")
        }

        if let timeSignatureNumerator = timeSignatureNumerator {
            newConfig.timeSignatureNumerator = timeSignatureNumerator
            // Adjust tickTypes count to match new numerator
            if timeSignatureNumerator > newConfig.tickTypes.count {
                newConfig.tickTypes.append(contentsOf: Array(repeating: .regular, count: timeSignatureNumerator - newConfig.tickTypes.count))
            } else if timeSignatureNumerator < newConfig.tickTypes.count {
                newConfig.tickTypes = Array(newConfig.tickTypes.prefix(timeSignatureNumerator))
            }
            print("TimeSignatureNumerator configured to: \(timeSignatureNumerator)")
        }

        if let timeSignatureDenominator = timeSignatureDenominator {
            newConfig.timeSignatureDenominator = timeSignatureDenominator
            print("TimeSignatureDenominator configured to: \(timeSignatureDenominator)")
        }

        if let tickTypes = tickTypes {
            newConfig.tickTypes = tickTypes
            print("TickTypes configured to: \(tickTypes)")
        }

        if let subdivision = subdivision {
            newConfig.subdivision = subdivision
            print("Subdivision configured to: \(subdivision.name)")
        }

        if let droneDurationRatio = droneDurationRatio {
            newConfig.droneDurationRatio = max(Self.minDroneDurationRatio,
                                              min(Self.maxDroneDurationRatio, droneDurationRatio))
            print("DroneDurationRatio configured to: \(newConfig.droneDurationRatio)")
        }

        if let isDroning = isDroning {
            newConfig.isDroning = isDroning
            print("IsDroning configured to: \(isDroning)")
        }

        // Update configuration atomically - this triggers didSet which handles buffer regeneration
        if newConfig != configuration {
            configuration = newConfig
            print("Metronome configured - configuration updated")
        }
    }

    func setBPM(_ newBPM: Int) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.bpm = max(Self.minBPM, min(newBPM, Self.maxBPM))
            print("BPM set to: \(self.bpm)")
//            if self.isPlaying {
//                DispatchQueue.global(qos: .userInitiated).async { [weak self] in
//                    guard let self = self else { return }
//                    self.prepareBeatsBuffer()
//                    let beatSampleTime = AVAudioFramePosition(self.nextBeatSampleTime)
//                    let playerBeatTime = AVAudioTime(sampleTime: beatSampleTime, atRate: self.bufferSampleRate)
//
//                    self.tickPlayerNode.play(at: playerBeatTime)
//                }
//            }
        }
    }
    
    func setNoteBuffer(soundType: SoundType = .sine, note: UInt8) {
        do {
            // Загружаем SoundFont и первый пресет
            try renderer.loadSoundFont(named: soundType.toString(), preset: 0)

            if let buffer = try renderer.renderToBuffer(note: note, velocity: velocity, duration: 5.0, outputFormat: mainMixerFormat) {
                print("Set note buffer created \(soundType) \(note)! Frames: \(buffer.frameLength)")
                self.noteBuffer = buffer
            }
        } catch {
            print("Ошибка создания буфера: \(error.localizedDescription)")
        }
    }

    func setNoteBuffer(buffer: AVAudioPCMBuffer) {
        self.noteBuffer = buffer
        self.prepareBeatsBufferAsync()
    }
    
    func setDroneDurationRatio(_ newRatio: TimeInterval) {
        self.droneDurationRatio = newRatio
    }
    
    func setNextTickType(tickIndex: Int) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
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
                // Note: configuration.didSet will automatically call prepareBeatsBuffer()
            }
        }
    }
    
    func setTickTypes(tickTypes: [TickType]) {
        self.tickTypes = tickTypes
        // Note: configuration.didSet will automatically call prepareBeatsBuffer()
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

        if let metroDrone = metroDrone, metroDrone.audioEngine.isRunning == false {
            metroDrone.requestAudioEngine(for: "Metronome")
        }

        // playTapSound() // Removed: tap sound causes ~300ms delay. Using haptic feedback only for instant response.
    }

    func prepareAudioEngine() {
        guard let metroDrone = metroDrone else {
            print("⚠️ Warning: MetroDrone reference is nil, cannot prepare audio engine")
            return
        }

        metroDrone.requestAudioEngine(for: "Metronome")
        print("✅ Audio engine prewarmed for metronome and tap tempo")
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
