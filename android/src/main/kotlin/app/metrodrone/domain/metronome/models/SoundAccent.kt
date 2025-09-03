package app.metrodrone.domain.metronome.models

enum class SoundAccent {
    MUTE,
    DEFAULT,
    ACCENT,
    STRONG,
    ;

    val next: SoundAccent
        get() = when (this) {
            MUTE -> DEFAULT
            DEFAULT -> ACCENT
            ACCENT -> STRONG
            STRONG -> MUTE
        }
}
