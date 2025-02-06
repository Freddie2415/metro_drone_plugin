import Foundation

public struct MNoteCalculator {

    public struct Standard {
        public static var frequency = 440.0
        public static let octave    = 4
    }

    public static var letters: [MNote.Letter] = [
        .A,
        .ASharp,
        .B,
        .C,
        .CSharp,
        .D,
        .DSharp,
        .E,
        .F,
        .FSharp,
        .G,
        .GSharp
    ]

    // MARK: - Bounds

    public static var indexBounds: ClosedRange<Int> {
        let minimum = try! index(forFrequency: MFrequencyValidator.minimumFrequency)
        let maximum = try! index(forFrequency: MFrequencyValidator.maximumFrequency)

        return minimum ... maximum
    }

    public static var octaveBounds: ClosedRange<Int> {
        let bounds = indexBounds
        let minimum = try! octave(forIndex: bounds.lowerBound)
        let maximum = try! octave(forIndex: bounds.upperBound)

        return minimum ... maximum
    }

    // MARK: - Validators

    public static func isValid(index: Int) -> Bool {
        indexBounds.contains(index)
    }

    public static func validate(index: Int) throws {
        if !isValid(index: index) {
            throw MPitchError.invalidPitchIndex
        }
    }

    public static func isValid(octave: Int) -> Bool {
        octaveBounds.contains(octave)
    }

    public static func validate(octave: Int) throws {
        if !isValid(octave: octave) {
            throw MPitchError.invalidOctave
        }
    }

    // MARK: - Pitch Notations

    public static func frequency(forIndex index: Int) throws -> Double {
        try validate(index: index)

        let count = letters.count
        let power = Double(index) / Double(count)

        return pow(2, power) * Standard.frequency
    }

    public static func letter(forIndex index: Int) throws -> MNote.Letter {
        try validate(index: index)

        let count = letters.count
        var lettersIndex = index < 0
            ? count - abs(index) % count
            : index % count

        if lettersIndex == 12 {
            lettersIndex = 0
        }

        guard (0 ..< letters.count) ~= lettersIndex else {
            throw MPitchError.invalidPitchIndex
        }

        return letters[lettersIndex]
    }

    public static func octave(forIndex index: Int) throws -> Int {
        try validate(index: index)

        let count            = letters.count
        let resNegativeIndex = Standard.octave - (abs(index) + 2) / count
        let resPositiveIndex = Standard.octave + (index + 9) / count

        return index < 0
            ? resNegativeIndex
            : resPositiveIndex
    }

    // MARK: - Pitch Index

    public static func index(forFrequency frequency: Double) throws -> Int {
        try MFrequencyValidator.validate(frequency: frequency)
        let count = Double(letters.count)

        return Int(round(count * log2(frequency / Standard.frequency)))
    }

    public static func index(forLetter letter: MNote.Letter, octave: Int) throws -> Int {
        try validate(octave: octave)

        let count       = letters.count
        let letterIndex = letters.firstIndex(of: letter) ?? 0
        let offset      = letterIndex < 3 ? 0 : count

        return letterIndex + count * (octave - Standard.octave) - offset
    }
}
