package app.metrodrone.domain.metronome.models

data class Beat(
    val parts: List<BeatPart>,
    val accent: SoundAccent = SoundAccent.DEFAULT,
) {

    companion object {

        val defaultList = List(4) {
            Beat(parts = Subdivision.QUARTER.parts, accent = SoundAccent.DEFAULT)
        }
    }
}
