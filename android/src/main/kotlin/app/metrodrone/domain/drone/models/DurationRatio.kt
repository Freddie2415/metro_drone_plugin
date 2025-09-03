package app.metrodrone.domain.drone.models

class DurationRatio(
    val value: Double,
) {

    companion object {
        val default = DurationRatio(0.5)
    }
}
