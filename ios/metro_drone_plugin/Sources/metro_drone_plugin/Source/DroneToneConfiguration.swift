//
//  DroneToneConfiguration.swift
//  metro_drone_plugin
//
//  Configuration structure for drone tone parameters
//

import Foundation

struct DroneToneConfiguration: Equatable {
    var note: String
    var octave: Int
    var tuningStandard: Double
    var soundType: SoundType
    var isPulsing: Bool

    /// Default drone tone configuration
    static var `default`: DroneToneConfiguration {
        return DroneToneConfiguration(
            note: "A",
            octave: 4,
            tuningStandard: 440.0,
            soundType: .sine,
            isPulsing: false
        )
    }

    /// Custom equality check
    static func == (lhs: DroneToneConfiguration, rhs: DroneToneConfiguration) -> Bool {
        return lhs.note == rhs.note &&
               lhs.octave == rhs.octave &&
               lhs.tuningStandard == rhs.tuningStandard &&
               lhs.soundType == rhs.soundType &&
               lhs.isPulsing == rhs.isPulsing
    }
}
