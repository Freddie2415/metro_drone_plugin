package app.metrodrone.domain.metrodrone

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.media.AudioAttributes
import android.media.AudioDeviceCallback
import android.media.AudioDeviceInfo
import android.media.AudioFocusRequest
import android.media.AudioManager
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.util.Log
import app.metrodrone.domain.drone.Drone
import app.metrodrone.domain.metronome.Metronome
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.launch

class Metrodrone(
    val metronome: Metronome,
    val drone: Drone,
    val metronomeSoundPlayer: SoundPlayer,
    val droneSoundPlayer: SoundPlayer,
) {
    // Single scope for all audio operations - prevents coroutine leaks
    private var audioScope: CoroutineScope? = null
    private val mainHandler = Handler(Looper.getMainLooper())

    // Audio Focus management
    private var audioManager: AudioManager? = null
    private var audioFocusRequest: AudioFocusRequest? = null
    private var hasAudioFocus = false

    // Audio route change handling (headphones connect/disconnect)
    private var appContext: Context? = null
    private var noisyAudioReceiver: BroadcastReceiver? = null
    private var audioDeviceCallback: AudioDeviceCallback? = null
    private var isNoisyReceiverRegistered = false

    private val audioFocusChangeListener = AudioManager.OnAudioFocusChangeListener { focusChange ->
        // Metronome should NEVER stop due to audio focus changes from other apps.
        // Musicians need the metronome to keep playing even when other audio is playing.
        when (focusChange) {
            AudioManager.AUDIOFOCUS_GAIN -> {
                Log.d(TAG, "Audio focus gained")
                hasAudioFocus = true
            }
            AudioManager.AUDIOFOCUS_LOSS -> {
                Log.d(TAG, "Audio focus lost permanently - continuing playback (metronome priority)")
                hasAudioFocus = false
                // Do NOT stop - metronome must keep playing
            }
            AudioManager.AUDIOFOCUS_LOSS_TRANSIENT -> {
                Log.d(TAG, "Audio focus lost transiently - continuing playback (metronome priority)")
                hasAudioFocus = false
                // Do NOT stop - metronome must keep playing
            }
            AudioManager.AUDIOFOCUS_LOSS_TRANSIENT_CAN_DUCK -> {
                Log.d(TAG, "Audio focus loss with duck - continuing at full volume (metronome priority)")
                hasAudioFocus = false
                // Do NOT stop or duck - metronome needs full volume
            }
        }
    }

    fun initialize(context: Context) {
        appContext = context.applicationContext
        audioManager = context.getSystemService(Context.AUDIO_SERVICE) as? AudioManager
        setupAudioRouteChangeHandling()
    }

    // MARK: - Audio Route Change Handling (Headphones connect/disconnect)
    private fun setupAudioRouteChangeHandling() {
        // Register for ACTION_AUDIO_BECOMING_NOISY (headphones unplugged)
        noisyAudioReceiver = object : BroadcastReceiver() {
            override fun onReceive(context: Context?, intent: Intent?) {
                if (intent?.action == AudioManager.ACTION_AUDIO_BECOMING_NOISY) {
                    Log.d(TAG, "Audio becoming noisy - headphones unplugged")
                    handleAudioRouteChange()
                }
            }
        }

        // Register for new device connections (API 23+)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            audioDeviceCallback = object : AudioDeviceCallback() {
                override fun onAudioDevicesAdded(addedDevices: Array<out AudioDeviceInfo>?) {
                    addedDevices?.forEach { device ->
                        if (isHeadphoneDevice(device)) {
                            Log.d(TAG, "Headphones connected: ${device.productName}")
                            handleAudioRouteChange()
                        }
                    }
                }

                override fun onAudioDevicesRemoved(removedDevices: Array<out AudioDeviceInfo>?) {
                    removedDevices?.forEach { device ->
                        if (isHeadphoneDevice(device)) {
                            Log.d(TAG, "Headphones disconnected: ${device.productName}")
                            // ACTION_AUDIO_BECOMING_NOISY handles this case
                        }
                    }
                }
            }
            audioManager?.registerAudioDeviceCallback(audioDeviceCallback, mainHandler)
        }
    }

    private fun isHeadphoneDevice(device: AudioDeviceInfo): Boolean {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            return device.type == AudioDeviceInfo.TYPE_WIRED_HEADSET ||
                    device.type == AudioDeviceInfo.TYPE_WIRED_HEADPHONES ||
                    device.type == AudioDeviceInfo.TYPE_BLUETOOTH_A2DP ||
                    device.type == AudioDeviceInfo.TYPE_BLUETOOTH_SCO ||
                    device.type == AudioDeviceInfo.TYPE_USB_HEADSET
        }
        return false
    }

    private fun registerNoisyReceiver() {
        if (isNoisyReceiverRegistered) return
        val context = appContext ?: return
        val receiver = noisyAudioReceiver ?: return

        try {
            val filter = IntentFilter(AudioManager.ACTION_AUDIO_BECOMING_NOISY)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                context.registerReceiver(receiver, filter, Context.RECEIVER_NOT_EXPORTED)
            } else {
                context.registerReceiver(receiver, filter)
            }
            isNoisyReceiverRegistered = true
            Log.d(TAG, "Registered noisy audio receiver")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to register noisy receiver", e)
        }
    }

    private fun unregisterNoisyReceiver() {
        if (!isNoisyReceiverRegistered) return
        val context = appContext ?: return
        val receiver = noisyAudioReceiver ?: return

        try {
            context.unregisterReceiver(receiver)
            isNoisyReceiverRegistered = false
            Log.d(TAG, "Unregistered noisy audio receiver")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to unregister noisy receiver", e)
        }
    }

    private fun handleAudioRouteChange() {
        val metronomeWasPlaying = metronome.isPlaying
        val droneWasPlaying = drone.isPlaying

        if (!metronomeWasPlaying && !droneWasPlaying) {
            Log.d(TAG, "Audio route changed but nothing playing, ignoring")
            return
        }

        Log.d(TAG, "Handling audio route change. Metronome: $metronomeWasPlaying, Drone: $droneWasPlaying")

        // Stop playback
        if (metronomeWasPlaying) {
            metronome.stop()
            metronomeSoundPlayer.stop()
        }
        if (droneWasPlaying) {
            drone.stop()
            droneSoundPlayer.stop()
        }

        // Restart after a short delay to allow audio system to reconfigure
        mainHandler.postDelayed({
            if (metronomeWasPlaying) {
                Log.d(TAG, "Restarting metronome after route change")
                startMetronome()
            }
            if (droneWasPlaying) {
                Log.d(TAG, "Restarting drone after route change")
                startDrone()
            }
        }, 100)
    }

    private fun requestAudioFocus(): Boolean {
        val manager = audioManager ?: return true // If no manager, proceed anyway

        if (hasAudioFocus) return true

        val result = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val focusRequest = AudioFocusRequest.Builder(AudioManager.AUDIOFOCUS_GAIN)
                .setAudioAttributes(
                    AudioAttributes.Builder()
                        .setUsage(AudioAttributes.USAGE_MEDIA)
                        .setContentType(AudioAttributes.CONTENT_TYPE_MUSIC)
                        .build()
                )
                .setOnAudioFocusChangeListener(audioFocusChangeListener, mainHandler)
                .build()
            audioFocusRequest = focusRequest
            manager.requestAudioFocus(focusRequest)
        } else {
            @Suppress("DEPRECATION")
            manager.requestAudioFocus(
                audioFocusChangeListener,
                AudioManager.STREAM_MUSIC,
                AudioManager.AUDIOFOCUS_GAIN
            )
        }

        hasAudioFocus = result == AudioManager.AUDIOFOCUS_REQUEST_GRANTED
        Log.d(TAG, "Audio focus request result: $hasAudioFocus")
        return hasAudioFocus
    }

    private fun abandonAudioFocus() {
        val manager = audioManager ?: return

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            audioFocusRequest?.let { manager.abandonAudioFocusRequest(it) }
        } else {
            @Suppress("DEPRECATION")
            manager.abandonAudioFocus(audioFocusChangeListener)
        }
        hasAudioFocus = false
        audioFocusRequest = null
    }

    private fun getOrCreateScope(): CoroutineScope {
        return audioScope ?: CoroutineScope(SupervisorJob() + Dispatchers.Default).also {
            audioScope = it
        }
    }

    fun startMetronome() {
        if (!requestAudioFocus()) {
            Log.w(TAG, "Failed to acquire audio focus for metronome")
            // Continue anyway - some devices may not require focus
        }

        // Register for audio route changes while playing
        registerNoisyReceiver()

        metronomeSoundPlayer.reset()
        metronomeSoundPlayer.warmUp()
        val scope = getOrCreateScope()
        metronome.start { beatIndex, samples ->
            scope.launch(Dispatchers.Default) {
                metronomeSoundPlayer.playArray(samples)
            }
            mainHandler.post {
                metronome.onTickUpdated?.invoke(beatIndex)
            }
        }
    }

    fun stopMetronome() {
        metronome.stop()
        metronomeSoundPlayer.stop()

        // Only abandon focus and unregister receiver if drone is also not playing
        if (!drone.isPlaying) {
            abandonAudioFocus()
            unregisterNoisyReceiver()
            cancelScope()
        }
    }

    fun prepareAudioEngine() {
        metronomeSoundPlayer.warmUp()
    }

    fun startDrone() {
        if (!requestAudioFocus()) {
            Log.w(TAG, "Failed to acquire audio focus for drone")
        }

        // Register for audio route changes while playing
        registerNoisyReceiver()

        droneSoundPlayer.reset()
        drone.start { samples ->
            droneSoundPlayer.playArray(samples)
        }
    }

    fun stopDrone() {
        drone.stop()
        droneSoundPlayer.stop()

        // Only abandon focus and unregister receiver if metronome is also not playing
        if (!metronome.isPlaying) {
            abandonAudioFocus()
            unregisterNoisyReceiver()
            cancelScope()
        }
    }

    private fun cancelScope() {
        audioScope?.cancel()
        audioScope = null
    }

    fun release() {
        stopMetronome()
        stopDrone()
        abandonAudioFocus()
        unregisterNoisyReceiver()

        // Unregister audio device callback
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            audioDeviceCallback?.let { callback ->
                audioManager?.unregisterAudioDeviceCallback(callback)
            }
        }
        audioDeviceCallback = null
        noisyAudioReceiver = null

        cancelScope()
        metronomeSoundPlayer.release()
        droneSoundPlayer.release()
        metronome.cleanup()
        appContext = null
    }

    companion object {
        private const val TAG = "Metrodrone"
    }
}
