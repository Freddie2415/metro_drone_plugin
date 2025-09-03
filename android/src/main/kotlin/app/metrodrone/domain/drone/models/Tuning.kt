package app.metrodrone.domain.drone.models

data class Tuning(
    val value: Double,
) {

    companion object {
        val default = Tuning(440.0)
    }
}
