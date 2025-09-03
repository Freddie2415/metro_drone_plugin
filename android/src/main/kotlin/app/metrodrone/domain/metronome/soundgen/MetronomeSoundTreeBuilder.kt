package app.metrodrone.domain.metronome.soundgen

import android.content.Context
import io.modacity.metro_drone_plugin.R
import app.metrodrone.domain.core.TreeHead
import app.metrodrone.domain.core.TreeNode
import app.metrodrone.domain.metronome.models.SoundAccent

class MetronomeSoundTreeBuilder(
    private val context: Context
) {
    private val accentSound = createSound(SoundAccent.ACCENT)
    private val strongSound = createSound(SoundAccent.STRONG)
    private val defaultSound = createSound(SoundAccent.DEFAULT)
    private val muteSound = createSound(SoundAccent.MUTE)

    val soundTree = TreeHead<SoundAccent>(
        nodes = SoundAccent.values().associate { accent ->
            val track = when (accent) {
                SoundAccent.ACCENT -> accentSound
                SoundAccent.STRONG -> strongSound
                SoundAccent.DEFAULT -> defaultSound
                SoundAccent.MUTE -> muteSound
            }
            val node = TreeNode<ShortArray, Boolean>(
                name = "Sound for $accent",
                value = track
            )

            accent to node
        }
            .apply { fillIsPlay() }
    )

    private fun Map<SoundAccent, TreeNode<ShortArray, Boolean>>.fillIsPlay() {
        values.forEach { node ->
            val playNode = TreeNode<ShortArray, Float>(
                name = "Play sound for ${node.name}",
                value = node.value,
            )
            val notPlayNode = TreeNode<ShortArray, Float>(
                name = "Do not play sound for ${node.name}",
                value = muteSound,
            )

            val nextNodes: Map<Boolean, TreeNode<ShortArray, Float>> = mapOf(
                true to playNode,
                false to notPlayNode
            )

            node.nextNodes = nextNodes
        }
    }

    private fun createSound(accent: SoundAccent): ShortArray {
        if (accent == SoundAccent.MUTE) return shortArrayOf()

        val resId = when (accent) {
            SoundAccent.DEFAULT -> R.raw.tick_fixed
            SoundAccent.ACCENT -> R.raw.accent_fixed
            SoundAccent.STRONG -> R.raw.strong_accent_fixed
            else -> return shortArrayOf()
        }

        val inputStream = context.resources.openRawResource(resId)
        val fullBytes = inputStream.readBytes()
        inputStream.close()

        val headerSize = 44
        val pcmBytes = fullBytes.copyOfRange(headerSize, fullBytes.size)

        return ShortArray(pcmBytes.size / 2) { i ->
            val lo = pcmBytes[i * 2].toInt() and 0xFF
            val hi = pcmBytes[i * 2 + 1].toInt()
            (hi shl 8 or lo).toShort()
        }
    }
}
