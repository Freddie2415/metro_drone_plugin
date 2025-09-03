package app.metrodrone.domain.drone.models

data class Octave(
    val value: Int
) {

    companion object {

        val default = Octave(4)
    }
}
