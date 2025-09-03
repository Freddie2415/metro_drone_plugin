package app.metrodrone.domain.drone.models

sealed class Note(val name: String, val semitoneOffsetFromA: Int) {
    object C : Note("C", -9)
    object Cs : Note("C#", -8)
    object D : Note("D", -7)
    object Ds : Note("D#", -6)
    object E : Note("E", -5)
    object F : Note("F", -4)
    object Fs : Note("F#", -3)
    object G : Note("G", -2)
    object Gs : Note("G#", -1)
    object A : Note("A", 0)
    object As : Note("A#", 1)
    object B : Note("B", 2)

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
