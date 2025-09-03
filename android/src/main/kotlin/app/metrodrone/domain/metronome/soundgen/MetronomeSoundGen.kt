package app.metrodrone.domain.metronome.soundgen

import app.metrodrone.domain.core.FixedSizeMap
import app.metrodrone.domain.metronome.models.Beat
import app.metrodrone.domain.metronome.models.BeatPart
import app.metrodrone.domain.metronome.models.SoundAccent
import javax.inject.Inject

class MetronomeSoundGen @Inject constructor(
    private val builder: MetronomeSoundTreeBuilder,
) {

    private val soundCache = FixedSizeMap<SoundCacheKey, ShortArray>(
        maxSize = 16,
    )

    fun generate(
        bpm: Int,
        beat: Beat,
    ): ShortArray {
        var result = shortArrayOf()

        val cacheKey = SoundCacheKey(bpm = bpm, beat = beat)

        if (soundCache.contains(cacheKey)) {
            return soundCache[cacheKey] ?: shortArrayOf()
        }

        beat.parts.forEachIndexed { i, part ->
            val accent = when {
                i == 0 && beat.accent == SoundAccent.STRONG -> beat.accent
                i == 0 && beat.accent == SoundAccent.ACCENT -> beat.accent
                !part.play || beat.accent == SoundAccent.MUTE -> SoundAccent.MUTE
                else -> SoundAccent.DEFAULT
            }

            val sound = generate(bpm = bpm, part = part, accent = accent)

            result += sound
        }

        soundCache.put(cacheKey, result)
        return result
    }

    fun generate(
        bpm: Int,
        part: BeatPart,
        accent: SoundAccent,
    ): ShortArray {
        val isPlay = accent != SoundAccent.MUTE
        val duration = 60f / bpm * part.duration.size
        val sampleCount = (duration * 44100).toInt()
        val array = builder.soundTree.nodes[accent]
            ?.nextNodes
            ?.get(isPlay)?.value as? ShortArray
        return array?.copyOf(sampleCount) ?: shortArrayOf()
    }

    private data class SoundCacheKey(
        val bpm: Int,
        val beat: Beat,
    )
}
