public struct MNote: CustomStringConvertible {

    /// The letter of a music note in English Notation
    public enum Letter: String, CaseIterable, CustomStringConvertible {
        case C      = "C"
        case CSharp = "C#"
        case D      = "D"
        case DSharp = "D#"
        case E      = "E"
        case F      = "F"
        case FSharp = "F#"
        case G      = "G"
        case GSharp = "G#"
        case A      = "A"
        case ASharp = "A#"
        case B      = "B"

        public var description: String { rawValue }
    }

    /// The index of the note
    public let index: Int

    /// The letter of the note in English Notation
    public let letter: Letter

    /// The octave of the note
    public let octave: Int

    /// The frequency of the note
    public let frequency: Double

    /// The corresponding wave of the note
    public let wave: MAcousticWave

    /// A string description of the note including octave (eg A4)
    public var description: String {
        "\(self.letter)\(self.octave)"
    }

    // MARK: - Initialization

    /// Initialize a Note from an index
    /// - Parameter index: The index of the note
    /// - Throws: An error if the rest of the components cannot be calculated
    public init(index: Int) throws {
        self.index     = index
        letter         = try MNoteCalculator.letter(forIndex: index)
        octave         = try MNoteCalculator.octave(forIndex: index)
        frequency      = try MNoteCalculator.frequency(forIndex: index)
        wave           = try MAcousticWave(frequency: frequency)
    }

    /// Initialize a Note from a frequency
    /// - Parameter frequency: The frequency of the note
    /// - Throws: An error if the rest of the components cannot be calculated
    public init(frequency: Double) throws {
        index          = try MNoteCalculator.index(forFrequency: frequency)
        letter         = try MNoteCalculator.letter(forIndex: index)
        octave         = try MNoteCalculator.octave(forIndex: index)
        self.frequency = try MNoteCalculator.frequency(forIndex: index)
        wave           = try MAcousticWave(frequency: frequency)
    }

    /// Initialize a Note from a Letter & Octave
    /// - Parameters:
    ///   - letter: The letter of the note
    ///   - octave: The octave of the note
    /// - Throws: An error if the rest of the components cannot be calculated
    public init(letter: Letter, octave: Int) throws {
        self.letter    = letter
        self.octave    = octave
        index          = try MNoteCalculator.index(forLetter: letter, octave: octave)
        frequency      = try MNoteCalculator.frequency(forIndex: index)
        wave           = try MAcousticWave(frequency: frequency)
    }

    // MARK: - Neighbor Notes

    /// One semitone lower
    /// - Throws: An error if the semitone is out of bounds
    /// - Returns: A note that is one semitone lower
    public func lower() throws -> MNote {
        try MNote(index: index - 1)
    }

    /// One semitone higher
    /// - Throws: An error if the semitone is out of bounds
    /// - Returns: A note that is one semitone higher
    public func higher() throws -> MNote {
        try MNote(index: index + 1)
    }
}
