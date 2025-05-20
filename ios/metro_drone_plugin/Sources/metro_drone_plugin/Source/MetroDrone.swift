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
    let droneTone: DroneToneSF
    let generatedDroneTone: GeneratedDroneTone2

    init() {
        metronome = Metronome(audioEngine: audioEngine)
        droneTone = DroneToneSF(audioEngine: audioEngine, metronome: metronome)
        generatedDroneTone = GeneratedDroneTone2(audioEngine: audioEngine, metronome: metronome)

        configureAudioSession()
        setupAudioEngine()
    }

    func setupAudioEngine() {
        do {
            try audioEngine.start()
            print("MetroDrone Audio engine started successfully.")
        } catch {
            print("Error starting audio engine: \(error)")
        }
    }
    
    func configureAudioSession() {
        do {
            // Получаем экземпляр аудиосессии
            let audioSession = AVAudioSession.sharedInstance()

            // Устанавливаем категорию для воспроизведения звука
            try audioSession.setCategory(.playAndRecord, mode: .default, options: [.mixWithOthers])
            print("setCategory")
            // Активируем аудиосессию
            try audioSession.setActive(true)
            print("setActive")

            print("Аудиосессия настроена и активирована.")
        } catch {
            print("Ошибка настройки аудиосессии: \(error.localizedDescription)")
        }
    }

    func stopAudioEngine() {
        audioEngine.stop()
        print("MetroDrone Audio engine stopped.")
    }

    deinit {
        stopAudioEngine()
        print("MetroDrone deinitialized")
    }
}

