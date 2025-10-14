//
//  MetronomeConfiguration.swift
//  metro_drone_plugin
//
//  Configuration structure for metronome parameters
//

import Foundation

struct MetronomeConfiguration: Equatable {
    var bpm: Int
    var timeSignatureNumerator: Int
    var timeSignatureDenominator: Int
    var tickTypes: [TickType]
    var subdivision: Subdivision
    var droneDurationRatio: Double
    var isDroning: Bool

    /// Default metronome configuration
    static var `default`: MetronomeConfiguration {
        return MetronomeConfiguration(
            bpm: 120,
            timeSignatureNumerator: 4,
            timeSignatureDenominator: 4,
            tickTypes: Array(repeating: .regular, count: 4),
            subdivision: Subdivision(
                name: "Quarter Notes",
                description: "One quarter note per beat",
                restPattern: [true],
                durationPattern: [1.0]
            ),
            droneDurationRatio: 0.5,
            isDroning: false
        )
    }

    /// Custom equality check for TickType arrays
    static func == (lhs: MetronomeConfiguration, rhs: MetronomeConfiguration) -> Bool {
        return lhs.bpm == rhs.bpm &&
               lhs.timeSignatureNumerator == rhs.timeSignatureNumerator &&
               lhs.timeSignatureDenominator == rhs.timeSignatureDenominator &&
               lhs.tickTypes == rhs.tickTypes &&
               lhs.subdivision == rhs.subdivision &&
               lhs.droneDurationRatio == rhs.droneDurationRatio &&
               lhs.isDroning == rhs.isDroning
    }
}
