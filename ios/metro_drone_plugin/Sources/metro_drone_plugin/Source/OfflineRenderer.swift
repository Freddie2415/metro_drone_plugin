//
//  OfflineRenderer.swift
//  metrodrone
//
//  Created by Фаррух Хамракулов on 13/01/25.
//


import AVFoundation

class OfflineRenderer {
    private var audioEngine: AVAudioEngine
    private var sampler: AVAudioUnitSampler

    init() {
        audioEngine = AVAudioEngine()
        sampler = AVAudioUnitSampler()

        // Подключаем семплер к mainMixerNode
        audioEngine.attach(sampler)
        audioEngine.connect(sampler, to: audioEngine.mainMixerNode, format: nil)
    }

    func loadSoundFont(named name: String, preset: UInt8) throws {
        guard let soundFontURL = Bundle.main.url(forResource: name, withExtension: "sf2") else {
            throw NSError(domain: "SoundFontError", code: 1, userInfo: [NSLocalizedDescriptionKey: "SoundFont файл не найден"])
        }
        
        try sampler.loadSoundBankInstrument(at: soundFontURL, program: preset, bankMSB: UInt8(kAUSampler_DefaultMelodicBankMSB), bankLSB: UInt8(kAUSampler_DefaultBankLSB))
    }

    func renderToBuffer(note: UInt8, velocity: UInt8, duration: TimeInterval, outputFormat: AVAudioFormat) throws -> AVAudioPCMBuffer? {
//        let outputFormat = audioEngine.outputNode.outputFormat(forBus: 0)
        let sampleRate = outputFormat.sampleRate
        let frameCount = AVAudioFrameCount(duration * sampleRate)

        // Устанавливаем движок в ручной режим рендеринга
        try audioEngine.enableManualRenderingMode(.offline, format: outputFormat, maximumFrameCount: frameCount)
        
        defer {
            audioEngine.disableManualRenderingMode()
            audioEngine.stop()
        }
        
        // Буфер для рендеринга
        guard let buffer = AVAudioPCMBuffer(pcmFormat: outputFormat, frameCapacity: frameCount) else {
            throw NSError(domain: "BufferError", code: 2, userInfo: [NSLocalizedDescriptionKey: "Не удалось создать аудиобуфер"])
        }

        // Запускаем движок
        try audioEngine.start()

        // Воспроизводим ноту
        sampler.startNote(note, withVelocity: velocity, onChannel: 0)

        // Рендерим звук
        while audioEngine.manualRenderingSampleTime < frameCount {
            let framesToRender = frameCount - AVAudioFrameCount(audioEngine.manualRenderingSampleTime)
            let renderFrames = min(framesToRender, audioEngine.manualRenderingMaximumFrameCount)

            let status = try audioEngine.renderOffline(renderFrames, to: buffer)

            switch status {
            case .success:
                continue
            case .cannotDoInCurrentContext:
                continue
            case .insufficientDataFromInputNode:
                print("Недостаточно данных из входного узла, пропуск кадра")
                continue
            case .error:
                throw NSError(domain: "RenderError", code: 3, userInfo: [NSLocalizedDescriptionKey: "Ошибка рендеринга"])
            @unknown default:
                throw NSError(domain: "RenderError", code: 4, userInfo: [NSLocalizedDescriptionKey: "Неизвестный статус рендеринга"])
            }
        }


        // Останавливаем ноту
        sampler.stopNote(note, onChannel: 0)
        
        // Останавливаем движок
        audioEngine.stop()
        audioEngine.disableManualRenderingMode()

        print("BUFFER RENDERED FROM SOUNDFONT")
        return buffer
    }
    
    func extractBuffer(from buffer: AVAudioPCMBuffer, startTime: TimeInterval, duration: TimeInterval) throws -> AVAudioPCMBuffer? {
//            guard let format = buffer.format else {
//                throw NSError(domain: "BufferError", code: 6, userInfo: [NSLocalizedDescriptionKey: "Буфер не имеет формата"])
//            }

        let format = buffer.format
        let sampleRate = buffer.format.sampleRate
            let startFrame = AVAudioFramePosition(startTime * sampleRate)
            let frameCount = AVAudioFrameCount(duration * sampleRate)

            // Проверяем, что запрашиваемая область находится в пределах буфера
            guard startFrame >= 0, startFrame + AVAudioFramePosition(frameCount) <= AVAudioFramePosition(buffer.frameLength) else {
                throw NSError(domain: "BufferError", code: 7, userInfo: [NSLocalizedDescriptionKey: "Запрашиваемая область находится вне буфера"])
            }

            // Создаем новый буфер для извлеченной части
            guard let newBuffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else {
                throw NSError(domain: "BufferError", code: 8, userInfo: [NSLocalizedDescriptionKey: "Не удалось создать новый буфер"])
            }

            // Копируем данные
            for channel in 0..<Int(format.channelCount) {
                let sourceChannel = buffer.floatChannelData![channel]
                let targetChannel = newBuffer.floatChannelData![channel]

                memcpy(targetChannel, sourceChannel.advanced(by: Int(startFrame)), Int(frameCount) * MemoryLayout<Float>.size)
            }

            newBuffer.frameLength = frameCount
            return newBuffer
        }
}
