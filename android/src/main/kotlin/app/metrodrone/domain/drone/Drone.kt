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
        set(value) {
            if (field != value) {
                field = value
                onFieldUpdate?.invoke("note", value.name)
            }
        }
    var octave = Octave.default
        set(value) {
            if (field != value) {
                field = value
                onFieldUpdate?.invoke("octave", value.value)
            }
        }
    var amplitude = Amplitude.default
    var soundType = SoundType.default
        set(value) {
            if (field != value) {
                field = value
                onFieldUpdate?.invoke("soundType", value.naming)
            }
        }
    var tuning = Tuning.default
        set(value) {
            if (field != value) {
                field = value
                onFieldUpdate?.invoke("tuningStandard", value.value)
            }
        }
    var durationRatio = DurationRatio.default
        set(value) {
            field = value
            onFieldUpdate?.invoke("droneDurationRatio", value.value)
        }

    var onFieldUpdate: ((String, Any) -> Unit)? = null
    var isPlaying: Boolean = false
        private set(value) {
            if (field != value) {
                field = value
                onFieldUpdate?.invoke("isPlaying", value)
            }
        }
    var isPulsing: Boolean = false
        set(value) {
            if (field != value) {
                field = value;
                onFieldUpdate?.invoke("isPulsing", value)
            }
        }

    fun start(
        onNextSamples: (ShortArray) -> Unit,
    ) {
        stop()
        droneSoundGen.resetPhases()
        playingJob = droneJob(onNextSamples)
        isPlaying = true;
    }

    fun stop() {
        playingJob?.cancel()
        playingJob = null
        isPlaying = false;
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
