package app.metrodrone.domain.drone.models

sealed class Note(val name: String, val semitoneOffsetFromA: Int) {
    data object C : Note("C", -9)
    data object Cs : Note("C#", -8)
    data object D : Note("D", -7)
    data object Ds : Note("D#", -6)
    data object E : Note("E", -5)
    data object F : Note("F", -4)
    data object Fs : Note("F#", -3)
    data object G : Note("G", -2)
    data object Gs : Note("G#", -1)
    data object A : Note("A", 0)
    data object As : Note("A#", 1)
    data object B : Note("B", 2)

    companion object {

        val default = C

        val list = listOf(
            C,
            Cs,
            D,
            Ds,
            E,
            F,
            Fs,
            G,
            Gs,
            A,
            As,
            B
        )
    }
}
