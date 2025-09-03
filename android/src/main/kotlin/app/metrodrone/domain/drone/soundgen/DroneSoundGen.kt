package app.metrodrone.domain.drone.soundgen

import app.metrodrone.domain.drone.models.Note
import app.metrodrone.domain.drone.models.SoundType
import kotlin.math.floor
import kotlin.math.pow
import kotlin.math.sin

class DroneSoundGen {

    private var sinePhase = 0.0
    private var organPhases = DoubleArray(4)
    private var celloPhase = 0.0

    fun resetPhases() {
        sinePhase = 0.0
        organPhases = DoubleArray(4)
        celloPhase = 0.0
    }

    fun generate(
        soundType: SoundType,
        note: Note,
        octave: Int,
        amplitude: Float,
        durationSeconds: Double,
        tuningA: Double,
    ): ShortArray {
        val frequency = getFrequency(note, octave, tuningA)
        val sampleCount = (durationSeconds * SAMPLE_RATE).toInt()
        val soundArray = generateWaveform(soundType, frequency, amplitude, sampleCount)
        return soundArray
    }

    fun generateWaveform(
        soundType: SoundType,
        frequency: Double,
        amplitude: Float,
        sampleCount: Int
    ): ShortArray {
        val samples = ShortArray(sampleCount)
        val twoPi = 2 * Math.PI

        val organFreqMultipliers = arrayOf(1.0, 2.0, 3.0, 4.0)
        val organAmplitudes = arrayOf(1.0, 0.5, 0.25, 0.125)

        val vibratoRate = 5.0
        val vibratoDepth = 0.01
        val tremoloRate = 3.0
        val tremoloDepth = 0.2

        for (i in 0 until sampleCount) {
            val value = when (soundType) {
                SoundType.SINE -> {
                    val s = sin(sinePhase)
                    val increment = twoPi * frequency / SAMPLE_RATE
                    sinePhase += increment
                    if (sinePhase > twoPi) sinePhase -= twoPi
                    s
                }

                SoundType.ORGAN -> {
                    var sum = 0.0
                    for (h in organPhases.indices) {
                        val harmFreq = frequency * organFreqMultipliers[h]
                        val increment = twoPi * harmFreq / SAMPLE_RATE
                        val s = sin(organPhases[h]) * organAmplitudes[h]
                        sum += s
                        organPhases[h] += increment
                        if (organPhases[h] > twoPi) organPhases[h] -= twoPi
                    }
                    sum
                }

                SoundType.CELLO -> {
                    val baseIncrement = twoPi * frequency / SAMPLE_RATE
                    val vibrato = sin(celloPhase * (vibratoRate / frequency)) * vibratoDepth
                    val actualIncrement = baseIncrement * (1.0 + vibrato)

                    celloPhase += actualIncrement
                    if (celloPhase > twoPi) celloPhase -= twoPi

                    val fraction = celloPhase / twoPi
                    var sawWave = 2.0 * (fraction - floor(fraction + 0.5))
                    sawWave *= 0.8

                    val tremPhase = celloPhase * (tremoloRate / vibratoRate)
                    val tremValue = 1.0 - sin(tremPhase) * tremoloDepth

                    val h1 = sin(celloPhase) * 0.3
                    val h2 = sin(2.0 * celloPhase) * 0.2
                    val h3 = sin(3.0 * celloPhase) * 0.1

                    (sawWave + h1 + h2 + h3) * tremValue
                }
            }

            val sample = (value * amplitude * Short.MAX_VALUE)
                .toInt()
                .coerceIn(Short.MIN_VALUE.toInt(), Short.MAX_VALUE.toInt())
                .toShort()

            samples[i] = sample
        }

        return samples
    }
    companion object {
        private const val SAMPLE_RATE = 44100

        fun getFrequency(note: Note, octave: Int, tuningA: Double = 440.0): Double {
            val semitoneOffset = note.semitoneOffsetFromA + 12 * (octave - 4)
            return tuningA * 2.0.pow(semitoneOffset / 12.0)
        }
    }
}
