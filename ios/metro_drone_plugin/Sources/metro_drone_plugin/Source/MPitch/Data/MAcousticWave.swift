public struct MAcousticWave {

    /// The speed of sound in air (m/s)
    public static let speed: Double = 343

    /// The frequency of the wave
    public let frequency: Double

    /// The wavelength
    public let wavelength: Double

    /// The period of the wave
    public let period: Double

    /// Up to 16 harmonic pitches
    public var harmonics: [MPitch] {
        var pitches = [MPitch]()

        do {
            for index in 1...16 {
                try pitches.append(MPitch(frequency: Double(index) * frequency))
            }
        } catch {
            debugPrint(error)
        }

        return pitches
    }

    // MARK: - Initialization

    /// Initialize a wave with a frequency
    /// - Parameter frequency: The frequency of the wave
    /// - Throws: An error in case wavelength or period cannot be calculated
    public init(frequency: Double) throws {
        try MFrequencyValidator.validate(frequency: frequency)
        self.frequency = frequency
        wavelength     = try MWaveCalculator.wavelength(forFrequency: frequency)
        period         = try MWaveCalculator.period(forWavelength: wavelength)
    }

    /// Initialize a wave with a wavelength
    /// - Parameter wavelength: The wavelength
    /// - Throws: An error in case frequency or period cannot be calculated
    public init(wavelength: Double) throws {
        try MWaveCalculator.validate(wavelength: wavelength)
        self.wavelength = wavelength
        frequency       = try MWaveCalculator.frequency(forWavelength: wavelength)
        period          = try MWaveCalculator.period(forWavelength: wavelength)
    }

    /// Initialize a wave with a period
    /// - Parameter period: The period of the wave
    /// - Throws: An error in case wavelength or frequency cannot be calculated
    public init(period: Double) throws {
        try MWaveCalculator.validate(period: period)
        self.period = period
        wavelength  = try MWaveCalculator.wavelength(forPeriod: period)
        frequency   = try MWaveCalculator.frequency(forWavelength: wavelength)
    }
}
