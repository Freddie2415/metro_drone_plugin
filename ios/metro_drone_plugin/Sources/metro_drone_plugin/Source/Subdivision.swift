//
//  Subdivision.swift
//  metrodrone
//
//  Created by Фаррух Хамракулов on 06/01/25.
//

struct Subdivision: Hashable {
    let name: String               // Имя subdivision (отображается в UI)
    let description: String        // Описание (дополнительно, если нужно)
    let restPattern: [Bool]        // Паттерн пауз (true = звук, false = пауза)
    let durationPattern: [Double]  // Длительности каждой части (в сумме = 1.0)
}
