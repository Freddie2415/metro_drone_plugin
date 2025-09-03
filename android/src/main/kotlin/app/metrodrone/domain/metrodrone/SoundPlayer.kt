package app.metrodrone.domain.metrodrone

import android.media.AudioAttributes
import android.media.AudioFormat
import android.media.AudioManager
import android.media.AudioTrack

class SoundPlayer {

    private val lock = Any()

    private val channelConfig = AudioFormat.CHANNEL_OUT_MONO
    private val encoding = AudioFormat.ENCODING_PCM_16BIT
    private val bufferSize = AudioTrack.getMinBufferSize(
        /* sampleRateInHz = */ SAMPLE_RATE,
        /* channelConfig = */ channelConfig,
        /* audioFormat = */ encoding
    ) * 4

    private val audioTrack: AudioTrack = AudioTrack(
        AudioAttributes.Builder()
            .setUsage(AudioAttributes.USAGE_MEDIA)
            .setContentType(AudioAttributes.CONTENT_TYPE_MUSIC)
            .build(),
        AudioFormat.Builder()
            .setSampleRate(SAMPLE_RATE)
            .setEncoding(encoding)
            .setChannelMask(channelConfig)
            .build(),
        bufferSize,
        AudioTrack.MODE_STREAM,
        AudioManager.AUDIO_SESSION_ID_GENERATE
    ).apply { play() }

    fun playArray(array: ShortArray) {
        if (array.isEmpty()) return
        synchronized(lock) {
            audioTrack.write(array, 0, array.size)
        }
    }

    fun reset() {
        synchronized(lock) {
            audioTrack.flush()
            audioTrack.play()
        }
    }

    fun warmUp() {
        val silence = ShortArray(6000)
        synchronized(lock) {
            repeat(3) {
                audioTrack.write(silence, 0, silence.size)
            }
        }
    }

    companion object {
        const val SAMPLE_RATE = 44100
    }
}
