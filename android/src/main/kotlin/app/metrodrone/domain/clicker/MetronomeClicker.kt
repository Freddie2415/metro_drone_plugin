package app.metrodrone.domain.clicker

import javax.inject.Inject

class MetronomeClicker @Inject constructor() {

    private var firstTap: Long? = null
        set(value) {
            secondTap = null
            thirdTap = null
            field = value
        }

    private var secondTap: Long? = null
        set(value) {
            thirdTap = null
            field = value
        }

    private var thirdTap: Long? = null

    fun addTapAndCalcBpm(): Int? {
        val now = System.currentTimeMillis()

        val firstBeatTime = firstTap
        val secondBeatTime = secondTap
        val thirdBeatTime = thirdTap

        if (firstBeatTime == null) {
            firstTap = now
            return null
        }

        if (secondBeatTime == null) {
            if (now - firstBeatTime <= MAX_DURATION_BETWEEN_BEATS) {
                secondTap = now
                return null
            } else {
                firstTap = now
                return null
            }
        }

        if (thirdBeatTime == null)
            if (now - secondBeatTime <= MAX_DURATION_BETWEEN_BEATS) {
                thirdTap = now
                return calcBmp()
            } else {
                secondTap = now
                return null
            }

        firstTap = now
        return null
    }

    private fun calcBmp(): Int? {
        val max = thirdTap ?: return null
        val min = firstTap ?: return null
        val diff = max - min
        val durationBetweenBeats = diff / 2
        return (MINUTE_IN_MILLIS / durationBetweenBeats).toInt()
    }

    companion object {
        private const val MAX_DURATION_BETWEEN_BEATS = 3_000L
        private const val MINUTE_IN_MILLIS = 60_000L
    }
}
