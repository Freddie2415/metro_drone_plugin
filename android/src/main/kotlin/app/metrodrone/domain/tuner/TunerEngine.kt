package app.metrodrone.domain.tuner

import be.hogent.tarsos.dsp.AudioEvent
import be.hogent.tarsos.dsp.AudioProcessor
import be.hogent.tarsos.dsp.MicrophoneAudioDispatcher
import be.hogent.tarsos.dsp.pitch.PitchDetectionResult
import be.hogent.tarsos.dsp.pitch.PitchProcessor
import kotlin.math.ln
import kotlin.math.pow
import kotlin.math.roundToInt
import kotlin.math.sqrt

class TunerEngine {
    var onFieldUpdate: ((String, Any) -> Unit)? = null
    private val sampleRate: Int = 44100
    private val bufferSize: Int = 32768
    private val bufferOverlap: Int = 16384

    private var tuningA: Double = 440.0
        set(value) {
            if (field != value) {
                field = value;
                onFieldUpdate?.invoke("tuningFrequency", value)
            }
        }

    data class Result(
        val hz: Float,
        val noteName: String,
        val centsOff: Double,
    )

    private var dispatcher: MicrophoneAudioDispatcher? = null
    private var dispatcherThread: Thread? = null
    private var isRunning = false

    fun updateTuningA(newValue: Double) {
        tuningA = newValue
    }

    fun start(onUpdate: (Result) -> Unit) {
        if (isRunning) {
            stop() // Stop existing session before starting new one
        }
        isRunning = true

        dispatcher = MicrophoneAudioDispatcher(
            sampleRate,
            bufferSize,
            bufferOverlap
        )

        dispatcher?.addAudioProcessor(EnergyGate())

        val processor = PitchProcessor(
            PitchProcessor.PitchEstimationAlgorithm.YIN,
            sampleRate.toFloat(),
            bufferSize
        ) { res: PitchDetectionResult, _: AudioEvent? ->
            if (!isRunning) return@PitchProcessor
            val freq = res.pitch
            val prob = res.probability

            if (freq > 0f && prob >= 0.8f) {
                val (noteName, cents) = toNoteAndCents(freq.toDouble(), tuningA)
                onUpdate(
                    Result(
                        hz = freq,
                        noteName = noteName,
                        centsOff = cents,
                    )
                )
            }
        }


        dispatcher?.addAudioProcessor(processor)
        dispatcherThread = Thread(dispatcher, "Tuner-Dispatcher").apply { start() }
    }

    fun stop() {
        isRunning = false

        // Stop dispatcher to release microphone resources
        dispatcher?.stop()

        // Interrupt the thread
        dispatcherThread?.interrupt()

        // Wait for thread to finish (max 1 second)
        try {
            dispatcherThread?.join(1000)
        } catch (e: InterruptedException) {
            Thread.currentThread().interrupt()
        }

        // Clean up references
        dispatcher = null
        dispatcherThread = null
    }


    private fun toNoteAndCents(freq: Double, a4: Double): Pair<String, Double> {
        val noteNumber = 12 * log2(freq / a4) + 69
        val nearest = noteNumber.roundToInt()
        val noteFreq = a4 * 2.0.pow((nearest - 69) / 12.0)

        val cents = 1200 * log2(freq / noteFreq)
        val name = midiToName(nearest)
        return name to cents
    }

    private fun midiToName(midi: Int): String {
        val names = arrayOf("C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B")
        val name = names[(midi % 12 + 12) % 12]
        val octave = (midi / 12) - 1
        return "$name$octave"
    }

    private fun log2(x: Double): Double = ln(x) / ln(2.0)
}

class EnergyGate(
    private val marginDb: Double = 12.0,
    private val hysteresisDb: Double = 4.0,
    private val releaseFrames: Int = 10,
    private val attenuation: Float = 0f,
    private val emaAlpha: Double = 0.05,
) : AudioProcessor {

    private var noiseFloorDb = -70.0
    private var open = false
    private var tail = 0

    override fun process(ev: AudioEvent): Boolean {
        val buf = ev.floatBuffer
        var sum = 0.0
        for (x in buf) sum += x * x
        val rms = sqrt(sum / buf.size.coerceAtLeast(1))
        val db = if (rms <= 1e-9) -120.0 else 20.0 * ln(rms) / ln(10.0)

        if (!open) {
            noiseFloorDb = (1 - emaAlpha) * noiseFloorDb + emaAlpha * db
        }

        val openThreshold = noiseFloorDb + marginDb
        val closeThreshold = openThreshold - hysteresisDb

        if (!open) {
            if (db >= openThreshold) {
                open = true; tail = releaseFrames
            }
        } else {
            if (db <= closeThreshold) {
                if (tail > 0) tail-- else open = false
            } else {
                tail = releaseFrames
            }
        }

        if (!open) {
            for (i in buf.indices) buf[i] *= attenuation
        }
        return true
    }

    override fun processingFinished() = Unit
}
