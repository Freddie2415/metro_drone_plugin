package app.metrodrone.domain.metronome.models

enum class Subdivision(
    val title: String,
    val parts: List<BeatPart>
) {

    QUARTER(
        title = "Quarter Notes",
        parts = listOf(
            BeatPart(BeatPartDuration.ONE, true)
        )
    ),
    EIGHTH(
        title = "Eighth Notes",
        parts = listOf(
            BeatPart(BeatPartDuration.ONE_HALF, true),
            BeatPart(BeatPartDuration.ONE_HALF, true)
        )
    ),
    SIXTEENTH(
        title = "Sixteenth Notes",
        parts = listOf(
            BeatPart(BeatPartDuration.ONE_QUARTER, true),
            BeatPart(BeatPartDuration.ONE_QUARTER, true),
            BeatPart(BeatPartDuration.ONE_QUARTER, true),
            BeatPart(BeatPartDuration.ONE_QUARTER, true)
        )
    ),
    TRIPLET(
        title = "Triplet",
        parts = listOf(
            BeatPart(BeatPartDuration.ONE_THIRD, true),
            BeatPart(BeatPartDuration.ONE_THIRD, true),
            BeatPart(BeatPartDuration.ONE_THIRD, true)
        )
    ),
    SWING(
        title = "Swing",
        parts = listOf(
            BeatPart(BeatPartDuration.TWO_THIRDS, true),
            BeatPart(BeatPartDuration.ONE_THIRD, true)
        )
    ),
    REST_AND_EIGHTH(
        title = "Rest and Eighth Note",
        parts = listOf(
            BeatPart(BeatPartDuration.ONE_HALF, false),
            BeatPart(BeatPartDuration.ONE_HALF, true)
        )
    ),
    DOTTED_EIGHTH_AND_SIXTEENTH(
        title = "Dotted Eighth and Sixteenth",
        parts = listOf(
            BeatPart(BeatPartDuration.THREE_QUARTERS, true),
            BeatPart(BeatPartDuration.ONE_QUARTER, true)
        )
    ),
    SIXTEENTH_AND_DOTTED_EIGHTH(
        title = "16th Note & Dotted Eighth",
        parts = listOf(
            BeatPart(BeatPartDuration.ONE_QUARTER, true),
            BeatPart(BeatPartDuration.THREE_QUARTERS, true)
        )
    ),
    TWO_SIXTEENTH_AND_EIGHTH(
        title = "2 Sixteenth Notes & Eighth Note",
        parts = listOf(
            BeatPart(BeatPartDuration.ONE_QUARTER, true),
            BeatPart(BeatPartDuration.ONE_QUARTER, true),
            BeatPart(BeatPartDuration.ONE_HALF, true)
        )
    ),
    EIGHTH_AND_TWO_SIXTEENTH(
        title = "Eighth Note & 2 Sixteenth Notes",
        parts = listOf(
            BeatPart(BeatPartDuration.ONE_HALF, true),
            BeatPart(BeatPartDuration.ONE_QUARTER, true),
            BeatPart(BeatPartDuration.ONE_QUARTER, true)
        )
    ),
    SIXTEENTH_REST_SIXTEENTH_NOTE_SIXTEENTH_REST_SIXTEENTH_NOTE(
        title = "16th Rest, 16th Note, 16th Rest, 16th Note",
        parts = listOf(
            BeatPart(BeatPartDuration.ONE_QUARTER, false),
            BeatPart(BeatPartDuration.ONE_QUARTER, true),
            BeatPart(BeatPartDuration.ONE_QUARTER, false),
            BeatPart(BeatPartDuration.ONE_QUARTER, true)
        )
    ),
    SIXTEENTH_NOTE_EIGHTH_NOTE_SIXTEENTH_NOTE(
        title = "16th Note, Eighth Note, 16th Note",
        parts = listOf(
            BeatPart(BeatPartDuration.ONE_QUARTER, true),
            BeatPart(BeatPartDuration.ONE_HALF, true),
            BeatPart(BeatPartDuration.ONE_QUARTER, true)
        )
    ),
    TWO_TRIPLETS_AND_TRIPLET_REST(
        title = "2 Triplets & Triplet Rest",
        parts = listOf(
            BeatPart(BeatPartDuration.ONE_THIRD, true),
            BeatPart(BeatPartDuration.ONE_THIRD, true),
            BeatPart(BeatPartDuration.ONE_THIRD, false)
        )
    ),
    TRIPLET_REST_AND_TWO_TRIPLETS(
        title = "Triplet Rest & 2 Triplets",
        parts = listOf(
            BeatPart(BeatPartDuration.ONE_THIRD, false),
            BeatPart(BeatPartDuration.ONE_THIRD, true),
            BeatPart(BeatPartDuration.ONE_THIRD, true)
        )
    ),
    TRIPLET_REST_TRIPLET_TRIPLET_REST(
        title = "Triplet Rest, Triplet, Triplet Rest",
        parts = listOf(
            BeatPart(BeatPartDuration.ONE_THIRD, false),
            BeatPart(BeatPartDuration.ONE_THIRD, true),
            BeatPart(BeatPartDuration.ONE_THIRD, false)
        )
    ),
    QUINTUPLETS(
        title = "Quintuplets",
        parts = listOf(
            BeatPart(BeatPartDuration.ONE_FIFTH, true),
            BeatPart(BeatPartDuration.ONE_FIFTH, true),
            BeatPart(BeatPartDuration.ONE_FIFTH, true),
            BeatPart(BeatPartDuration.ONE_FIFTH, true),
            BeatPart(BeatPartDuration.ONE_FIFTH, true)
        )
    ),
    SEPTUPLETS(
        title = "Septuplets",
        parts = listOf(
            BeatPart(BeatPartDuration.ONE_SEVENTH, true),
            BeatPart(BeatPartDuration.ONE_SEVENTH, true),
            BeatPart(BeatPartDuration.ONE_SEVENTH, true),
            BeatPart(BeatPartDuration.ONE_SEVENTH, true),
            BeatPart(BeatPartDuration.ONE_SEVENTH, true),
            BeatPart(BeatPartDuration.ONE_SEVENTH, true),
            BeatPart(BeatPartDuration.ONE_SEVENTH, true)
        )
    )
    ;

    companion object {

        val default = QUARTER
    }
}
