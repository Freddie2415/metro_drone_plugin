//
//  MetroDrone.swift
//  metrodrone
//
//  Created by Фаррух Хамракулов on 12/01/25.
//

import AVFoundation

class MetroDrone {
    let audioEngine = AVAudioEngine()
    let metronome: Metronome
    let generatedDroneTone: GeneratedDroneTone2

    // MARK: - Audio Engine Management
    private var activeComponents: Set<String> = []
    private let audioQueue = DispatchQueue(label: "MetroDroneAudioQueue")

    init() {
        metronome = Metronome(audioEngine: audioEngine)
        generatedDroneTone = GeneratedDroneTone2(audioEngine: audioEngine, metronome: metronome)

        metronome.setMetroDroneReference(self)
        generatedDroneTone.setMetroDroneReference(self)
    }

    // MARK: - Centralized Audio Engine Management
    func requestAudioEngine(for component: String) {
        audioQueue.sync {
            let wasEmpty = activeComponents.isEmpty
            activeComponents.insert(component)

            if wasEmpty {
                startAudioEngineIfNeeded()
            }

            print("Audio engine requested by: \(component). Active components: \(activeComponents)")
        }
    }

    func releaseAudioEngine(for component: String) {
        audioQueue.sync {
            activeComponents.remove(component)

            if activeComponents.isEmpty {
                stopAudioEngineIfPossible()
            }

            print("Audio engine released by: \(component). Active components: \(activeComponents)")
        }
    }

    private func startAudioEngineIfNeeded() {
        guard !audioEngine.isRunning else { return }

        do {
            try audioEngine.start()
            print("MetroDrone Audio engine started successfully.")
        } catch {
            print("Error starting audio engine: \(error)")
        }
    }

    private func stopAudioEngineIfPossible() {
        guard audioEngine.isRunning && activeComponents.isEmpty else { return }

        audioEngine.stop()
        print("MetroDrone Audio engine stopped - no active components.")
    }

    deinit {
        audioQueue.sync {
            if audioEngine.isRunning {
                audioEngine.stop()
            }
        }
        print("MetroDrone deinitialized")
    }
}

