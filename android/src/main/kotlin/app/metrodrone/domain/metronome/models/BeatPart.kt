package app.metrodrone.domain.metronome.models

data class BeatPart(
    val duration: BeatPartDuration,
    val play: Boolean,
)
