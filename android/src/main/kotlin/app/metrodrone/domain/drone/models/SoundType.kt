package app.metrodrone.domain.drone.models

enum class SoundType(val naming: String) {
    SINE("Sine"),
    ORGAN("Organ"),
    CELLO("Cello");

    companion object {

        val default = SINE
    }
}
