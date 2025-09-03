package app.metrodrone.domain.drone.soundgen

import app.metrodrone.domain.core.FixedSizeMap
import app.metrodrone.domain.drone.models.Note
import app.metrodrone.domain.drone.models.SoundType
import app.metrodrone.domain.metronome.models.Beat
import app.metrodrone.domain.metronome.models.SoundAccent
import javax.inject.Inject

class DronePulseGen @Inject constructor(
    private val droneSoundGen: DroneSoundGen,
) {

    private data class DroneCacheKey(
        val bpm: Int,
        val beat: Beat,
        val soundType: SoundType,
        val note: Note,
        val octave: Int,
        val amplitude: Float,
        val tuningA: Double,
        val droneDurationRatio: Float,
    )

    private val soundCache = FixedSizeMap<DroneCacheKey, ShortArray>(
        maxSize = 16,
    )

    fun generate(
        bpm: Int,
        beat: Beat,
        soundType: SoundType,
        note: Note,
        octave: Int,
        amplitude: Float,
        tuningA: Double,
        droneDurationRatio: Float,
    ): ShortArray {
        checkCache(
            bpm,
            beat,
            soundType,
            note,
            octave,
            amplitude,
            tuningA,
            droneDurationRatio
        )?.let {
            return it
        }

        val generatedSound = generateDroneBeat(
            bpm = bpm,
            beat = beat,
            soundType = soundType,
            note = note,
            octave = octave,
            amplitude = amplitude,
            tuningA = tuningA,
            droneDurationRatio = droneDurationRatio
        )

        soundCache[DroneCacheKey(
            bpm = bpm,
            beat = beat,
            soundType = soundType,
            note = note,
            octave = octave,
            amplitude = amplitude,
            tuningA = tuningA,
            droneDurationRatio = droneDurationRatio
        )] = generatedSound

        return generatedSound
    }


    fun generateDroneBeat(
        bpm: Int,
        beat: Beat,
        soundType: SoundType,
        note: Note,
        octave: Int,
        amplitude: Float,
        tuningA: Double,
        droneDurationRatio: Float,
    ): ShortArray {
        val frequency = DroneSoundGen.getFrequency(note, octave, tuningA)

        val totalSamples = beat.parts.sumOf {
            val partDurationSeconds = (60.0 / bpm) * it.duration.size
            (partDurationSeconds * SAMPLE_RATE).toInt()
        }

        val result = ShortArray(totalSamples)

        if (beat.accent == SoundAccent.MUTE) {
            return result
        }

        val fadeSamples = 100

        var writePos = 0
        for (part in beat.parts) {
            val partDurationSeconds = (60.0 / bpm) * part.duration.size
            val samplesPerPart = (partDurationSeconds * SAMPLE_RATE).toInt()

            val isSilent = !part.play
            val soundingSamples = if (isSilent) {
                0
            } else {
                (samplesPerPart * droneDurationRatio).toInt()
            }

            val wave = if (soundingSamples > 0) {
                droneSoundGen.generateWaveform(
                    soundType = soundType,
                    frequency = frequency,
                    amplitude = amplitude,
                    sampleCount = soundingSamples
                )
            } else {
                ShortArray(0)
            }

            for (i in 0 until samplesPerPart) {
                val baseSample = if (i < soundingSamples) wave[i] else 0

                val fadedSample = when {
                    // Fade-in
                    i < fadeSamples -> {
                        val factor = i / fadeSamples.toFloat()
                        (baseSample * factor).toInt()
                    }
                    // Fade-out
                    i >= soundingSamples - fadeSamples && i < soundingSamples -> {
                        val factor = (soundingSamples - i) / fadeSamples.toFloat()
                        (baseSample * factor).toInt()
                    }

                    else -> baseSample.toInt()
                }

                result[writePos + i] = fadedSample.toShort()
            }

            writePos += samplesPerPart
        }

        return result
    }

    private fun checkCache(
        bpm: Int,
        beat: Beat,
        soundType: SoundType,
        note: Note,
        octave: Int,
        amplitude: Float,
        tuningA: Double,
        droneDurationRatio: Float
    ): ShortArray? {
        val key = DroneCacheKey(
            bpm = bpm,
            beat = beat,
            soundType = soundType,
            note = note,
            octave = octave,
            amplitude = amplitude,
            tuningA = tuningA,
            droneDurationRatio = droneDurationRatio
        )
        return soundCache[key]
    }

    companion object {
        const val SAMPLE_RATE = 44100
    }
}
