package app.metrodrone.domain.metronome.models

enum class BeatPartDuration(
    val size: Float
) {
    ONE(1f),
    ONE_HALF(1f / 2),
    ONE_THIRD(1f / 3),
    ONE_QUARTER(1f / 4),
    ONE_FIFTH(1f / 5),
    ONE_SEVENTH(1f / 7),
    TWO_THIRDS(2f / 3),
    THREE_QUARTERS(3f / 4),
    ;
}
