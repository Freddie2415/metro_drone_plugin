package app.metrodrone.domain.metronome.models

data class TimeSignature(
    val tactSize: Int,
    val beatDuration: Int,
) {

    companion object {

        val default = TimeSignature(4, 4)
    }
}
