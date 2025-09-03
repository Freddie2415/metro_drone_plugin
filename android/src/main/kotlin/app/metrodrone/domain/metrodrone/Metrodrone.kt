package app.metrodrone.domain.metrodrone

import app.metrodrone.domain.clicker.MetronomeClicker
import app.metrodrone.domain.drone.Drone
import app.metrodrone.domain.metronome.Metronome
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.launch

class Metrodrone(
    val metronome: Metronome,
    val drone: Drone,
    val metronomeSoundPlayer: SoundPlayer,
    val droneSoundPlayer: SoundPlayer,
    val clicker: MetronomeClicker,
) {

    val beatFlow = MutableStateFlow(-1)

    fun startMetronome() {
        metronomeSoundPlayer.reset()
        metronomeSoundPlayer.warmUp()
        metronome.start { beatIndex, samples ->
            CoroutineScope(Dispatchers.Default).launch { metronomeSoundPlayer.playArray(samples) }
            CoroutineScope(Dispatchers.Main).launch { beatFlow.value = beatIndex }
        }
    }

    fun stopMetronome() {
        metronome.stop()
        beatFlow.value = -1
    }

    fun startDrone() {
        droneSoundPlayer.reset()
        drone.start { samples ->
            droneSoundPlayer.playArray(samples)
        }
    }

    fun stopDrone() {
        drone.stop()
    }
}
