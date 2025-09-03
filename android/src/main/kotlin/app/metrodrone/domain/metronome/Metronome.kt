package app.metrodrone.domain.metronome

import android.os.SystemClock
import app.metrodrone.domain.drone.Drone
import app.metrodrone.domain.drone.soundgen.DronePulseGen
import app.metrodrone.domain.metronome.models.Beat
import app.metrodrone.domain.metronome.models.Bpm
import app.metrodrone.domain.metronome.models.Subdivision
import app.metrodrone.domain.metronome.models.TimeSignature
import app.metrodrone.domain.metronome.soundgen.MetronomeSoundGen
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.isActive
import kotlinx.coroutines.launch

class Metronome(
    private val metronomeSoundGen: MetronomeSoundGen,
    private val pulsarSoundGen: DronePulseGen,
    private val drone: Drone,
) {

    private val scope: CoroutineScope = CoroutineScope(Dispatchers.Default)
    private var playingJob: Job? = null
    private var subdivision = Subdivision.default
    private var bpm = Bpm.default
    private var timeSignature = TimeSignature.default
    private var beats = Beat.defaultList
    private var pulsarMode = false

    private val beatDurationNanos get() = MINUTE_IN_NANOS / bpm.value

    fun updateBpm(value: Int) {
        bpm = Bpm(value)
    }

    fun updateSubdivision(value: Subdivision) {
        subdivision = value
    }

    fun updateTactSize(value: Int) {
        timeSignature = timeSignature.copy(tactSize = value)
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
    }

    fun stop() {
        playingJob?.cancel()
        playingJob = null
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

                        onBeat(beatIndex, mixAudioArrays(metronomeSamples, droneSamples))
                    } else {
                        onBeat(beatIndex, metronomeSamples)
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
