package dev.mindw.dday.model

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Test
import java.time.Instant
import java.time.ZoneId

class DeadlineCalculatorTest {
    @Test
    fun aoeDeadlineConvertsToKoreanLocalTime() {
        val deadline = fixtureDeadline(
            date = "2026-07-28",
            time = "23:59",
            timezone = "AoE",
        )

        val instant = DeadlineCalculator.instant(deadline)

        assertEquals(Instant.parse("2026-07-29T11:59:00Z"), instant)
        assertEquals(
            20,
            instant?.atZone(ZoneId.of("Asia/Seoul"))?.hour,
        )
    }

    @Test
    fun sameDayDeadlineUsesHourCountdown() {
        val deadline = fixtureDeadline(
            date = "2026-07-29",
            time = "23:59",
            timezone = "Asia/Seoul",
        )

        val display = DeadlineCalculator.display(
            deadline = deadline,
            now = Instant.parse("2026-07-29T01:00:00Z"),
            displayZone = ZoneId.of("Asia/Seoul"),
        )

        assertEquals("H-14", display?.text)
    }

    @Test
    fun invalidTimezoneIsRejected() {
        val deadline = fixtureDeadline(
            date = "2026-07-29",
            time = "23:59",
            timezone = "Not/A-Timezone",
        )

        assertNull(DeadlineCalculator.display(deadline))
    }

    private fun fixtureDeadline(
        date: String,
        time: String,
        timezone: String,
    ) = ConferenceDeadline(
        id = "fixture",
        label = "Deadline",
        date = date,
        time = time,
        timezone = timezone,
        type = DeadlineKind.Submission,
        isPrimary = true,
    )
}
