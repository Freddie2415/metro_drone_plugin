//
//  TickType.swift
//  metrodrone
//
//  Created by Фаррух Хамракулов on 06/01/25.
//

enum TickType: CaseIterable {
    case silence
    case regular
    case accent
    case strongAccent

    init?(from string: String) {
        // Удаляем префикс "TickType." если он присутствует
        let prefix = "TickType."
        let rawValue: String
        if string.hasPrefix(prefix) {
            rawValue = String(string.dropFirst(prefix.count))
        } else {
            rawValue = string
        }

        switch rawValue {
        case "silence":
            self = .silence
        case "regular":
            self = .regular
        case "accent":
            self = .accent
        case "strongAccent":
            self = .strongAccent
        default:
            return nil
        }
     }
}
