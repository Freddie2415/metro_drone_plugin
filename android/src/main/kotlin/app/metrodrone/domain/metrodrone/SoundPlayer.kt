package app.metrodrone.domain.metrodrone

import android.media.AudioAttributes
import android.media.AudioFormat
import android.media.AudioManager
import android.media.AudioTrack
import android.util.Log

class SoundPlayer {

    private val lock = Any()
    private var isReleased = false

    private val channelConfig = AudioFormat.CHANNEL_OUT_MONO
    private val encoding = AudioFormat.ENCODING_PCM_16BIT
    private val bufferSize = AudioTrack.getMinBufferSize(
        /* sampleRateInHz = */ SAMPLE_RATE,
        /* channelConfig = */ channelConfig,
        /* audioFormat = */ encoding
    ) * 4

    private var audioTrack: AudioTrack? = createAudioTrack()

    private fun createAudioTrack(): AudioTrack? {
        return try {
            AudioTrack(
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
        } catch (e: Exception) {
            Log.e(TAG, "Failed to create AudioTrack", e)
            null
        }
    }

    fun playArray(array: ShortArray): Boolean {
        if (array.isEmpty()) return true
        synchronized(lock) {
            if (isReleased) return false
            val track = audioTrack ?: return false

            // Check if AudioTrack is in valid state
            if (track.state != AudioTrack.STATE_INITIALIZED) {
                Log.w(TAG, "AudioTrack not initialized, recreating...")
                recreateAudioTrack()
                return false
            }

            // Ensure AudioTrack is playing
            if (track.playState != AudioTrack.PLAYSTATE_PLAYING) {
                try {
                    track.play()
                } catch (e: Exception) {
                    Log.e(TAG, "Failed to start AudioTrack", e)
                    recreateAudioTrack()
                    return false
                }
            }

            val result = track.write(array, 0, array.size)
            if (result < 0) {
                Log.e(TAG, "AudioTrack write error: $result")
                return false
            }
            return true
        }
    }

    fun reset() {
        synchronized(lock) {
            if (isReleased) return
            val track = audioTrack ?: return
            try {
                track.flush()
                if (track.state == AudioTrack.STATE_INITIALIZED) {
                    track.play()
                }
            } catch (e: Exception) {
                Log.e(TAG, "Failed to reset AudioTrack", e)
                recreateAudioTrack()
            }
        }
    }

    fun stop() {
        synchronized(lock) {
            if (isReleased) return
            val track = audioTrack ?: return
            try {
                if (track.playState == AudioTrack.PLAYSTATE_PLAYING) {
                    track.pause()
                    track.flush()
                }
            } catch (e: Exception) {
                Log.e(TAG, "Failed to stop AudioTrack", e)
            }
            Unit
        }
    }

    fun warmUp() {
        val silence = ShortArray(6000)
        synchronized(lock) {
            if (isReleased) return
            val track = audioTrack ?: return
            repeat(3) {
                track.write(silence, 0, silence.size)
            }
        }
    }

    fun release() {
        synchronized(lock) {
            if (isReleased) return
            isReleased = true
            try {
                audioTrack?.stop()
                audioTrack?.release()
            } catch (e: Exception) {
                Log.e(TAG, "Failed to release AudioTrack", e)
            }
            audioTrack = null
        }
    }

    private fun recreateAudioTrack() {
        // Must be called within synchronized(lock)
        try {
            audioTrack?.release()
        } catch (e: Exception) {
            Log.e(TAG, "Failed to release old AudioTrack", e)
        }
        audioTrack = createAudioTrack()
    }

    companion object {
        const val SAMPLE_RATE = 44100
        private const val TAG = "SoundPlayer"
    }
}
