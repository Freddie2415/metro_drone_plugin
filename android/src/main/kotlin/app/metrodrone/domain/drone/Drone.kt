package app.metrodrone.domain.drone

import android.os.SystemClock
import app.metrodrone.domain.drone.models.Amplitude
import app.metrodrone.domain.drone.models.DurationRatio
import app.metrodrone.domain.drone.models.Note
import app.metrodrone.domain.drone.models.Octave
import app.metrodrone.domain.drone.models.SoundType
import app.metrodrone.domain.drone.models.Tuning
import app.metrodrone.domain.drone.soundgen.DroneSoundGen
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.isActive
import kotlinx.coroutines.launch

class Drone(
    private val droneSoundGen: DroneSoundGen,
) {

    private val scope: CoroutineScope = CoroutineScope(Dispatchers.Default)
    private var playingJob: Job? = null
    var note: Note = Note.default
    var octave = Octave.default
    var amplitude = Amplitude.default
    var soundType = SoundType.default
    var tuning = Tuning.default
    var onFieldUpdate: ((String, Any) -> Unit)? = null
    var durationRatio = DurationRatio.default
        set(value) {
            field = value
            onFieldUpdate?.invoke("droneDurationRatio", value.value)
        }

    fun start(
        onNextSamples: (ShortArray) -> Unit,
    ) {
        stop()
        droneSoundGen.resetPhases()
        playingJob = droneJob(onNextSamples)
    }

    fun stop() {
        playingJob?.cancel()
        playingJob = null
    }

    private fun droneJob(
        onNextSamples: (ShortArray) -> Unit,
    ): Job = scope.launch {
        var nextGenerationTime = SystemClock.elapsedRealtimeNanos()
        var now = SystemClock.elapsedRealtimeNanos()
        while (isActive) {

            while (now < nextGenerationTime) {
                now = SystemClock.elapsedRealtimeNanos()
            }

            val sample = droneSoundGen.generate(
                soundType = soundType,
                note = note,
                octave = octave.value,
                amplitude = amplitude.value,
                tuningA = tuning.value,
                durationSeconds = 0.5
            )
            onNextSamples(sample)

            nextGenerationTime += (0.5 * SECOND_IN_NANOS).toLong()
        }
    }


    companion object {
        private const val SECOND_IN_NANOS = 1_000_000_000L
    }
}
