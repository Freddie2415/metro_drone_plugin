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

    // MARK: - Unified Configuration
    @Published var configuration: DroneToneConfiguration = .default {
        didSet {
            // Prevent redundant updates
            guard oldValue != configuration else { return }

            // Handle note/octave/tuning changes
            if oldValue.note != configuration.note ||
               oldValue.octave != configuration.octave ||
               oldValue.tuningStandard != configuration.tuningStandard ||
               oldValue.soundType != configuration.soundType {
                updateFrequency()
                updateMetronomeBuffer()
            }

            // Handle sound type changes
            if oldValue.soundType != configuration.soundType {
                // Sound type change is handled in configure method
            }

            // Handle pulsing changes
            if oldValue.isPulsing != configuration.isPulsing {
                handlePulsingChange()
            }

            // Notify Flutter about all changes
            onFieldUpdated?("note", configuration.note)
            onFieldUpdated?("octave", configuration.octave)
            onFieldUpdated?("tuningStandard", configuration.tuningStandard)
            onFieldUpdated?("soundType", configuration.soundType.rawValue)
            onFieldUpdated?("isPulsing", configuration.isPulsing)
        }
    }

    // MARK: - Computed Properties (for backward compatibility)
    var currentNote: String {
        get { configuration.note }
        set {
            var newConfig = configuration
            newConfig.note = newValue
            configuration = newConfig
        }
    }

    var currentOctave: Int {
        get { configuration.octave }
        set {
            var newConfig = configuration
            newConfig.octave = newValue
            configuration = newConfig
        }
    }

    var tuningStandartA: Double {
        get { configuration.tuningStandard }
        set {
            var newConfig = configuration
            newConfig.tuningStandard = newValue
            configuration = newConfig
        }
    }

    var soundType: SoundType {
        get { configuration.soundType }
        set {
            var newConfig = configuration
            newConfig.soundType = newValue
            configuration = newConfig
        }
    }

    var isPulsing: Bool {
        get { configuration.isPulsing }
        set {
            var newConfig = configuration
            newConfig.isPulsing = newValue
            configuration = newConfig
        }
    }

    // MARK: - Other Properties
    @Published var frequency: Double = 440.0  // Hz
    @Published var amplitude: Float = 0.5     // From 0.0 to 1.0
    @Published var isPlaying: Bool = false {
        didSet {
            onFieldUpdated?("isPlaying", isPlaying)
        }
    }
    
    // MARK: - Private AudioEngine
    private let engine: AVAudioEngine
    private let metronome: Metronome
    private weak var metroDrone: MetroDrone?
    private var sourceNode: AVAudioSourceNode?
    
    // MARK: - Sample Rate
    private let sampleRate: Double = 44_100
    private let bufferDuration: Double = 3.0 // 3 seconds
    
    // MARK: - Phases
    // Separate phases for each sound type
    private var phaseSine:  Double = 0.0
    private var phaseOrgan = SIMD4<Double>(0, 0, 0, 0) // for 4 harmonics (SIMD4 to avoid COW race condition)
    private var phaseCello: Double = 0.0

    // To smooth volume during start/stop
    // Simple envelope: fadeIn/fadeOut
    private var currentAmplitudeScale: Float = 0.0

    // Fade-in/out duration in seconds
    private let fadeTime: Double = 0.02
    // How much to increase/decrease volume per sample during start/stop
    private lazy var fadeInPerSample:  Float = Float(1.0 / (sampleRate * fadeTime))
    private lazy var fadeOutPerSample: Float = Float(1.0 / (sampleRate * fadeTime))
    
    private let waveTableManager = WaveTableManager(tableSize: 4096)

    // MARK: - Debouncing
    private let debounceQueue = DispatchQueue(label: "app.metronome.droneToneDebounce", qos: .userInitiated)
    private var bufferUpdateWorkItem: DispatchWorkItem?
    private var latestUpdateToken: UInt = 0

    // MARK: - Init
    init(audioEngine: AVAudioEngine, metronome: Metronome, metroDrone: MetroDrone? = nil) {
        self.engine = audioEngine
        self.metronome = metronome
        self.metroDrone = metroDrone
        setupSourceNode()
    }

    deinit {
        stopDrone()
        bufferUpdateWorkItem?.cancel()
        bufferUpdateWorkItem = nil
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
                    sampleValue = self.generateOrganSample()
//                case .cello:
//                    sampleValue = self.generateCelloSample()
                }

                // Apply simple envelope (fade in/out) to the resulting sample
                let finalSample = sampleValue * self.applyFadeEnvelope()

                // Write finalSample to both channels
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

    /// 1. Sine Wave — continuous phase
    private func generateSineSample() -> Float {
        let phaseIncrement = 2.0 * .pi * frequency / sampleRate
        
        let sample = Float(sin(phaseSine)) * amplitude
        phaseSine += phaseIncrement
        
        if phaseSine > 2.0 * .pi {
            phaseSine -= 2.0 * .pi
        }
        
        return sample
    }
    
    /// 2. Organ (additive synthesis). Each harmonic has its own phase
    private func generateOrganSample() -> Float {
        // Frequency multipliers for harmonics
        let harmonics = [1.0, 2.0, 3.0, 4.0]
        // Relative amplitudes
        let amplitudes: [Float] = [1.0, 0.5, 0.25, 0.125]

        var sample: Float = 0.0

        // Each harmonic has its own phase
        for i in 0..<harmonics.count {
            let harmFreq  = frequency * harmonics[i]
            let increment = 2.0 * .pi * harmFreq / sampleRate

            // Generate current harmonic sample
            let harmSample = sin(phaseOrgan[i]) * Double(amplitudes[i])
            sample += Float(harmSample) * amplitude

            // Update phase
            phaseOrgan[i] += increment
            if phaseOrgan[i] > 2.0 * .pi {
                phaseOrgan[i] -= 2.0 * .pi
            }
        }

        // Avoid clipping
        return max(min(sample, 1.0), -1.0)
    }
    
    /// 3. Cello — sawtooth wave + vibrato + tremolo, continuous phase
    private func generateCelloSample() -> Float {
        // --- Vibrato parameters
        let vibratoRate: Double = 5.0     // Vibrato frequency (Hz)
        let vibratoDepth: Double = 0.01   // Vibrato depth (frequency variation)

        // --- Tremolo parameters
        let tremoloRate: Double = 3.0
        let tremoloDepth: Double = 0.2

        // Generate vibrato
        let incrementBase = 2.0 * .pi * frequency / sampleRate
        // "Time" step for phase: here phaseCello changes uniformly, without jumps
        // But we add frequency correction by vibratoDepth:

        // vibratoValue: oscillates in range [-vibratoDepth, +vibratoDepth]
        let vibratoValue = sin(phaseCello * (vibratoRate / frequency)) * vibratoDepth
        // => effectiveFrequency = frequency * (1 + vibratoValue)
        // => effective phase increment ~ incrementBase * (1 + vibratoValue)

        // Update phase:
        let actualIncrement = incrementBase * (1.0 + vibratoValue)
        phaseCello += actualIncrement
        if phaseCello > 2.0 * .pi {
            phaseCello -= 2.0 * .pi
        }

        // Sawtooth wave based on phaseCello
        // Convert phaseCello to range [0..1]:
        let fraction = phaseCello / (2.0 * .pi)
        var sawWave = 2.0 * (fraction - floor(fraction + 0.5))

        // Smooth the sawtooth wave
        sawWave *= 0.8

        // Tremolo = amplitude modulation
        // Use phaseCello as "time" reference
        // We'll create a separate "phase" for tremolo, but can simplify
        let tremPhase = (phaseCello * (tremoloRate / vibratoRate)) // frequency ratio
        let tremValue = 1.0 - (sin(tremPhase) * tremoloDepth)

        // Additional harmonics (1st, 2nd, 3rd)
        // Can "tie" them to the same phase, but multiply phaseCello by 2, 3...
        let harmonic1 = sin(phaseCello) * 0.3
        let harmonic2 = sin(2.0 * phaseCello) * 0.2
        let harmonic3 = sin(3.0 * phaseCello) * 0.1

        let total = (sawWave + harmonic1 + harmonic2 + harmonic3) * Double(tremValue)

        let sample = Float(total) * amplitude
        return max(min(sample, 1.0), -1.0)
    }
    
    // MARK: - Fade Envelope

    /// Simple "envelope" for smooth start/stop
    private func applyFadeEnvelope() -> Float {
        // If drone is playing — try to reach 1.0
        // If drone is stopped — go to 0.0
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

        // Use async version to prevent main thread blocking (fixes MODACITY-NG)
        metroDrone?.requestAudioEngine(for: "GeneratedDroneTone") { [weak self] in
            guard let self = self else { return }
            guard !self.isPlaying else { return } // Double-check in case called twice

            self.phaseSine = 0.0
            self.phaseOrgan = SIMD4<Double>(0, 0, 0, 0)
            self.phaseCello = 0.0
            // Prepare for smooth fade-in
            // currentAmplitudeScale may be > 0 if just stopped
            // but we restart from 0.0
            self.currentAmplitudeScale = 0.0

            self.isPlaying = true
            self.sourceNode?.volume = 1.0
        }
    }
    
    func stopDrone() {
        guard isPlaying else { return }

        // Set flag to false => applyFadeEnvelope() will start decreasing currentAmplitudeScale
        isPlaying = false

        // Don't reset phases immediately, don't reset volume!
        // Wait in background thread until volume reaches zero
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }

            // Wait until smooth fade-out completes
            while self.currentAmplitudeScale > 0.0 {
                // Small sleep in microseconds to avoid wasting CPU cycles
                usleep(2000) // 2ms, for example
            }

            // When currentAmplitudeScale == 0, we can stop the engine
            // and/or reset phases
            self.phaseSine = 0.0
            self.phaseOrgan = SIMD4<Double>(0, 0, 0, 0)
            self.phaseCello = 0.0

            // If you want to stop the engine:
            self.sourceNode?.volume = 0.0
            self.metroDrone?.releaseAudioEngine(for: "GeneratedDroneTone")
        }

        print("Generated drone tone stopped.")
    }
    
    func setSoundType(sound: SoundType) {
        if sound == configuration.soundType { return }

        let isDroning = self.metronome.isDroning;
        self.metronome.setPulsarMode(isPulsing: !isDroning)

        var newConfig = configuration
        newConfig.soundType = sound
        configuration = newConfig

        self.metronome.setPulsarMode(isPulsing: isDroning)
    }
    
    func setPulsing(_ pulsing: Bool) {
        var newConfig = configuration
        newConfig.isPulsing = pulsing
        configuration = newConfig
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
        
        // Select base wave table
        let waveTable: [Float]
        switch soundType {
        case .sine:
            waveTable = waveTableManager.sineTable
        case .organ:
            waveTable = waveTableManager.organTable
        }
        // For table index
        var phaseIndex: Float = 0.0

        // Mask (if table size is power of 2)
        let mask = waveTableManager.tableSize - 1
        
        for channel in 0..<channelCount {
            guard let bufferPointer = buffer.floatChannelData?[channel] else { continue }
            
            for frame in 0..<Int(frameCount) {
                // Based on effectiveFreq, calculate table step
                let increment = Float(frequency) * tableSize / Float(sampleRate)

                // Read from table
                let idx = Int(phaseIndex) & mask
                var sampleValue = waveTable[idx]

                sampleValue *= amplitude
                bufferPointer[frame] = sampleValue

                // Update phase in table
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
        var newConfig = configuration
        newConfig.note = note
        newConfig.octave = octave
        configuration = newConfig
    }

    /// Batch configuration method for optimized parameter setting
    /// Call this method to set multiple parameters at once, triggering updates only once
    func configure(
        note: String? = nil,
        octave: Int? = nil,
        tuningStandard: Double? = nil,
        soundType: SoundType? = nil,
        isPulsing: Bool? = nil
    ) {
        var newConfig = configuration

        if let note = note {
            newConfig.note = note
            print("DroneTone note configured to: \(note)")
        }

        if let octave = octave {
            newConfig.octave = octave
            print("DroneTone octave configured to: \(octave)")
        }

        if let tuningStandard = tuningStandard {
            newConfig.tuningStandard = tuningStandard
            print("DroneTone tuningStandard configured to: \(tuningStandard)")
        }

        if let soundType = soundType {
            newConfig.soundType = soundType
            print("DroneTone soundType configured to: \(soundType)")
        }

        if let isPulsing = isPulsing {
            newConfig.isPulsing = isPulsing
            print("DroneTone isPulsing configured to: \(isPulsing)")
        }

        // Update configuration atomically - this triggers didSet which handles all updates
        if newConfig != configuration {
            configuration = newConfig
            print("DroneTone configured - configuration updated")
        }
    }

    // MARK: - Private Helper Methods

    private func updateFrequency() {
        frequency = MIDIHelper.frequency(
            note: configuration.note,
            octave: configuration.octave,
            tuningStandard: configuration.tuningStandard
        )
    }

    private func updateMetronomeBuffer() {
        // 1) Increment version token - new change
        latestUpdateToken &+= 1
        let token = latestUpdateToken

        // 2) Cancel previous task (if it hasn't started yet)
        bufferUpdateWorkItem?.cancel()

        // 3) Create new task with debouncing (50ms)
        let workItem = DispatchWorkItem { [weak self] in
            guard let self = self else { return }

            // CHECK 1: Is version token current?
            guard token == self.latestUpdateToken else {
                print("⚠️ updateMetronomeBuffer: token is outdated (\(token) != \(self.latestUpdateToken))")
                return
            }

            // CHECK 2: Is pulsing mode enabled?
            guard self.configuration.isPulsing else {
                print("⚠️ updateMetronomeBuffer: isPulsing = false, skipping generation")
                return
            }

            print("✅ updateMetronomeBuffer: starting buffer generation (token: \(token))")

            // Heavy operation - generating 3-second buffer
            guard let buffer = self.createNoteBuffer() else {
                print("⚠️ updateMetronomeBuffer: failed to create buffer")
                return
            }

            // CHECK 3: Is token still current after generation?
            guard token == self.latestUpdateToken else {
                print("⚠️ updateMetronomeBuffer: token is outdated after generation (\(token) != \(self.latestUpdateToken))")
                return
            }

            // CHECK 4: Is pulsing mode still enabled?
            guard self.configuration.isPulsing else {
                print("⚠️ updateMetronomeBuffer: isPulsing disabled during generation")
                return
            }

            print("✅ updateMetronomeBuffer: sending buffer to metronome (token: \(token))")
            self.metronome.setNoteBuffer(buffer: buffer)
        }

        // Save current workItem for identity check (===)
        bufferUpdateWorkItem = workItem

        // 4) Run on SERIAL queue with 50ms debouncing
        debounceQueue.asyncAfter(deadline: .now() + 0.05, execute: workItem)
    }

    private func handlePulsingChange() {
        if configuration.isPulsing {
            stopDrone()
            updateMetronomeBuffer()
        }
        metronome.setPulsarMode(isPulsing: configuration.isPulsing)
    }
}


/// Store tables (one period per wave)
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

    // MARK: - Table Generators

    /// 1. Simple sine wave
    private static func generateSineTable(tableSize: Int) -> [Float] {
        (0..<tableSize).map { i in
            let phase = 2.0 * .pi * Double(i) / Double(tableSize)
            return Float(sin(phase))
        }
    }
    
    /// 2. Organ (4 harmonics)
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

        // Normalize (so maximum is <= 1.0)
        if let maxVal = table.map({ abs($0) }).max(), maxVal > 0.0001 {
            for k in 0..<tableSize {
                table[k] /= maxVal
            }
        }

        return table
    }
    
    /// 3. Cello — basic sawtooth + harmonics
    ///    (Without tremolo/vibrato — we'll add them when reading the table)
    private static func generateCelloTable(tableSize: Int) -> [Float] {
        var table = [Float](repeating: 0.0, count: tableSize)

        for i in 0..<tableSize {
            // Sawtooth wave
            let fraction = Double(i) / Double(tableSize)
            var saw = 2.0 * (fraction - floor(fraction + 0.5))
            // Weaken the saw so harmonics have more influence
            saw *= 0.8

            // Add simple harmonics
            let phase = 2.0 * .pi * fraction
            let h1 = 0.3 * sin(phase)
            let h2 = 0.2 * sin(2.0 * phase)
            let h3 = 0.1 * sin(3.0 * phase)

            let total = saw + h1 + h2 + h3
            table[i] = Float(total)
        }

        // Normalization
        if let maxVal = table.map({ abs($0) }).max(), maxVal > 0.0001 {
            for k in 0..<tableSize {
                table[k] /= maxVal
            }
        }

        return table
    }
}
