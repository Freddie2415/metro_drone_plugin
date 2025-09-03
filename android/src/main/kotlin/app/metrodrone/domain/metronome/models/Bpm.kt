package app.metrodrone.domain.metronome.models

data class Bpm(
    val value: Int
) {

    companion object {
        val default = Bpm(60)

        const val MAX = 400
        const val MIN = 20
    }
}
