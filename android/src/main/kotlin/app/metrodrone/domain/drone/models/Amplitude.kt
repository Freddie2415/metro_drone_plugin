package app.metrodrone.domain.drone.models

data class Amplitude(
    val value: Float,
) {

    companion object {

        val default = Amplitude(0.5f)
    }
}
