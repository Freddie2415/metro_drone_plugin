package app.metrodrone.domain.metronome

import android.content.Context
import android.media.AudioAttributes
import android.media.SoundPool
import android.os.SystemClock
import android.util.Log
import app.metrodrone.domain.clicker.MetronomeClicker
import app.metrodrone.domain.core.updateAt
import app.metrodrone.domain.drone.Drone
import app.metrodrone.domain.drone.soundgen.DronePulseGen
import app.metrodrone.domain.metronome.models.Beat
import app.metrodrone.domain.metronome.models.Bpm
import app.metrodrone.domain.metronome.models.SoundAccent
import app.metrodrone.domain.metronome.models.Subdivision
import app.metrodrone.domain.metronome.models.TimeSignature
import app.metrodrone.domain.metronome.soundgen.MetronomeSoundGen
import io.modacity.metro_drone_plugin.R
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.isActive
import kotlinx.coroutines.launch
import kotlin.math.min

class Metronome(
    private val context: Context,
    private val metronomeSoundGen: MetronomeSoundGen,
    private val pulsarSoundGen: DronePulseGen,
    private val drone: Drone,
    private val clicker: MetronomeClicker
) {

    private val scope: CoroutineScope = CoroutineScope(Dispatchers.Default)
    private var playingJob: Job? = null
    private var subdivision = Subdivision.default
        set(value) {
            field = value
            val subdivisionMap = mapOf(
                "name" to field.title,
                "description" to field.title,
                "restPattern" to field.parts.map { it.play },
                "durationPattern" to field.parts.map { it.duration.size.toDouble() }
            )
            onFieldUpdate?.invoke("subdivision", subdivisionMap)
        }

    private var bpm = Bpm.default
        set(value) {
            field = value;
            onFieldUpdate?.invoke("bpm", value.value)
        }

    private var timeSignature = TimeSignature.default
        set(value) {
            field = value
            onFieldUpdate?.invoke("timeSignatureNumerator", value.tactSize)
            onFieldUpdate?.invoke("timeSignatureDenominator", value.beatDuration)
        }

    private var beats = Beat.defaultList
        set(value) {
            field = value

            val tickTypes = field.map { beat ->
                when (beat.accent) {
                    SoundAccent.MUTE -> "silence"
                    SoundAccent.DEFAULT -> "regular"
                    SoundAccent.ACCENT -> "accent"
                    SoundAccent.STRONG -> "strongAccent"
                }
            }

            onFieldUpdate?.invoke("tickTypes", tickTypes)
        }

    private var pulsarMode = false
        set(value) {
            field = value
            onFieldUpdate?.invoke("isDroning", value)
        }

    var onFieldUpdate: ((String, Any) -> Unit)? = null
    var onTickUpdated: ((Int) -> Unit)? = null

    private val soundPool: SoundPool
    private val tapSoundId: Int

    private var isPlaying: Boolean = false
        set(value) {
            if (isPlaying != value) {
                field = value
                onFieldUpdate?.invoke("isPlaying", value)
            }
        }

    init {
        val audioAttributes = AudioAttributes.Builder()
            .setUsage(AudioAttributes.USAGE_MEDIA)
            .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
            .build()

        soundPool = SoundPool.Builder()
            .setMaxStreams(20)
            .setAudioAttributes(audioAttributes)
            .build()

        tapSoundId = soundPool.load(context, R.raw.tap_sound, 1)
    }

    private val beatDurationNanos get() = MINUTE_IN_NANOS / bpm.value

    fun updateBpm(value: Int) {
        bpm = Bpm(value)
    }

    fun updateSubdivision(value: Subdivision) {
        subdivision = value
        beats = beats.map { it.copy(parts = subdivision.parts) }
        updateBeats(beats)
        Log.d("Metronome", "Set subdivision: ${subdivision.title}")
    }

    fun updateTactSize(value: Int) {
        timeSignature = timeSignature.copy(tactSize = value)
        Log.d("timeSignatureNumerator", value.toString());
        beats = when {
            value > beats.size -> {
                val diff = value - beats.size
                beats + List(diff) {
                    Beat(
                        parts = subdivision.parts,
                        accent = SoundAccent.DEFAULT
                    )
                }
            }

            value < beats.size -> {
                beats.take(value)
            }

            else -> beats
        }
        updateBeats(beats)
    }

    fun updateBeatDuration(value: Int) {
        timeSignature = timeSignature.copy(beatDuration = value)
    }

    fun updateBeats(value: List<Beat>) {
        beats = value
        timeSignature = timeSignature.copy(tactSize = value.size)
    }

    fun updatePulsarMode(value: Boolean) {
        pulsarMode = value
    }

    fun start(
        onBeat: (
            beatIndex: Int,
            samples: ShortArray,
        ) -> Unit
    ) {
        stop()
        playingJob = metronomeJob(onBeat)
        isPlaying = true
    }

    fun stop() {
        playingJob?.cancel()
        playingJob = null
        isPlaying = false
    }

    fun tap() {
        soundPool.play(tapSoundId, 1.0f, 1.0f, 0, 0, 1.0f)
        clicker.addTapAndCalcBpm()?.let { newBpm ->
            val valueToSet = min(newBpm, Bpm.MAX)
            updateBpm(valueToSet)
        }
    }

    fun setNextTickType(tickIndex: Int) {
        beats = beats.updateAt(tickIndex) { it.copy(accent = it.accent.next) }
        updateBeats(beats)
    }

    fun setTickTypes(tickTypes: List<SoundAccent>) {
        beats = tickTypes.mapIndexed { index, accent ->
            val parts = if (index < beats.size) {
                beats[index].parts
            } else {
                subdivision.parts
            }
            Beat(parts = parts, accent = accent)
        }
        updateBeats(beats)
    }

    fun cleanup() {
        soundPool.release()
    }

    private fun metronomeJob(
        onBeat: (
            beatIndex: Int,
            samples: ShortArray,
        ) -> Unit
    ): Job = scope.launch {
        var nextBeatTime = SystemClock.elapsedRealtimeNanos()
        var now = SystemClock.elapsedRealtimeNanos()
        while (isActive) {
            var beatIndex = 0
            while (beatIndex <= beats.lastIndex) {
                while (isActive && now < nextBeatTime - 1000) {
                    now = SystemClock.elapsedRealtimeNanos()
                }
                if (!isActive) return@launch

                nextBeatTime += beatDurationNanos
                beats.getOrNull(beatIndex)?.let { beat ->
                    val metronomeSamples = metronomeSoundGen.generate(bpm.value, beat)

                    if (pulsarMode) {
                        val droneSamples = pulsarSoundGen.generate(
                            bpm = bpm.value,
                            beat = beat,
                            soundType = drone.soundType,
                            note = drone.note,
                            octave = drone.octave.value,
                            amplitude = drone.amplitude.value,
                            tuningA = drone.tuning.value,
                            droneDurationRatio = drone.durationRatio.value.toFloat(),
                        )

                        onBeat(beatIndex + 1, mixAudioArrays(metronomeSamples, droneSamples))
                    } else {
                        onBeat(beatIndex + 1, metronomeSamples)
                    }
                }

                beatIndex++
            }
        }
    }

    private fun mixAudioArrays(
        array1: ShortArray,
        array2: ShortArray
    ): ShortArray {
        val size = maxOf(array1.size, array2.size)
        val result = ShortArray(size)

        for (i in 0 until size) {
            val sample1 = if (i < array1.size) array1[i].toInt() else 0
            val sample2 = if (i < array2.size) array2[i].toInt() else 0
            val mixed =
                (sample1 + sample2).coerceIn(Short.MIN_VALUE.toInt(), Short.MAX_VALUE.toInt())
            result[i] = mixed.toShort()
        }

        return result
    }

    companion object {
        const val MINUTE_IN_NANOS = 60_000_000_000L
    }
}
