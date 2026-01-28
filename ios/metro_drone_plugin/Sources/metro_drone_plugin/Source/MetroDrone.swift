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

        // Subscribe to audio route change notifications (headphones connect/disconnect)
        setupRouteChangeNotification()
    }

    // MARK: - Audio Route Change Handling
    private func setupRouteChangeNotification() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleRouteChange),
            name: AVAudioSession.routeChangeNotification,
            object: nil
        )
        print("MetroDrone: Subscribed to audio route change notifications")
    }

    @objc private func handleRouteChange(notification: Notification) {
        guard let userInfo = notification.userInfo,
              let reasonValue = userInfo[AVAudioSessionRouteChangeReasonKey] as? UInt,
              let reason = AVAudioSession.RouteChangeReason(rawValue: reasonValue) else {
            return
        }

        print("MetroDrone: Audio route changed, reason: \(reason.rawValue)")

        switch reason {
        case .newDeviceAvailable:
            // New device connected (headphones, Bluetooth, etc.)
            print("MetroDrone: New audio device connected (headphones plugged in)")
            restartAudioEngineIfNeeded()

        case .oldDeviceUnavailable:
            // Device disconnected (headphones unplugged, etc.)
            print("MetroDrone: Audio device disconnected (headphones unplugged)")
            restartAudioEngineIfNeeded()

        default:
            // Ignore other reasons (categoryChange, override, etc.)
            print("MetroDrone: Ignoring route change reason: \(reason.rawValue)")
            break
        }
    }

    private func restartAudioEngineIfNeeded() {
        // Save state BEFORE any changes
        let metronomeWasPlaying = metronome.isPlaying
        let droneWasPlaying = generatedDroneTone.isPlaying

        // Only restart if something was playing
        guard metronomeWasPlaying || droneWasPlaying else {
            print("MetroDrone: Nothing playing, skipping engine restart")
            return
        }

        print("MetroDrone: Handling audio route change. Metronome: \(metronomeWasPlaying), Drone: \(droneWasPlaying), Engine running: \(audioEngine.isRunning)")

        // Stop components directly without going through releaseAudioEngine
        if metronomeWasPlaying {
            metronome.isPlaying = false
            metronome.tickPlayerNode.stop()
            print("MetroDrone: Stopped metronome player node")
        }

        if droneWasPlaying {
            generatedDroneTone.isPlaying = false
            print("MetroDrone: Stopped drone")
        }

        // Stop and restart audio engine
        if audioEngine.isRunning {
            audioEngine.stop()
            print("MetroDrone: Stopped audio engine for route change")
        }

        // Restart on background queue with small delay
        DispatchQueue.global(qos: .userInitiated).asyncAfter(deadline: .now() + 0.1) { [weak self] in
            guard let self = self else { return }

            do {
                try self.audioEngine.start()
                print("MetroDrone: Audio engine restarted after route change")
            } catch {
                print("MetroDrone: Error restarting audio engine: \(error)")
                return
            }

            // Restart components on main thread
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }

                if metronomeWasPlaying {
                    print("MetroDrone: Restarting metronome")
                    self.metronome.start()
                }

                if droneWasPlaying {
                    print("MetroDrone: Restarting drone")
                    self.generatedDroneTone.startDrone()
                }
            }
        }
    }

    // MARK: - Centralized Audio Engine Management

    /// Async version - prevents main thread blocking (fixes MODACITY-NG App Hanging)
    func requestAudioEngine(for component: String, completion: @escaping () -> Void) {
        audioQueue.async { [weak self] in
            guard let self = self else {
                DispatchQueue.main.async { completion() }
                return
            }

            let wasEmpty = self.activeComponents.isEmpty
            self.activeComponents.insert(component)

            if wasEmpty {
                self.startAudioEngineIfNeeded()
            }

            print("Audio engine requested by: \(component). Active components: \(self.activeComponents)")

            DispatchQueue.main.async {
                completion()
            }
        }
    }

    /// Sync version - for backward compatibility (use only when not on main thread)
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
        audioQueue.async { [weak self] in
            guard let self = self else { return }
            self.activeComponents.remove(component)

            if self.activeComponents.isEmpty {
                self.stopAudioEngineIfPossible()
            }

            print("Audio engine released by: \(component). Active components: \(self.activeComponents)")
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
        // Remove notification observer
        NotificationCenter.default.removeObserver(self, name: AVAudioSession.routeChangeNotification, object: nil)

        audioQueue.sync {
            if audioEngine.isRunning {
                audioEngine.stop()
            }
        }
        print("MetroDrone deinitialized")
    }
}

