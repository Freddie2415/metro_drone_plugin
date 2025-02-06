//
//  AudioEngineManager.swift
//  metrodrone
//
//  Created by Фаррух Хамракулов on 09/01/25.
//


import AVFoundation

class AudioEngineManager {
    static let shared = AudioEngineManager()
    
    let engine = AVAudioEngine()
    let mainMixer = AVAudioMixerNode()
    
    private init() {
        // Подключаем главный микшер к выходу
        engine.attach(mainMixer)
        engine.connect(mainMixer, to: engine.outputNode, format: nil)
        
        // Настраиваем AVAudioSession
        configureAudioSession()
        
        start()
    }
    
    private func configureAudioSession() {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker])
            try audioSession.setActive(true)
        } catch {
            print("Ошибка настройки AVAudioSession: \(error.localizedDescription)")
        }
    }
    
    func start() {
        do {
            try engine.start()
        } catch {
            print("Ошибка запуска AudioEngine: \(error.localizedDescription)")
        }
    }
    
    func stop() {
        engine.stop()
    }
}
