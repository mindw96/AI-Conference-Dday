package dev.mindw.dday.model

import java.time.Duration
import java.time.DateTimeException
import java.time.Instant
import java.time.LocalDate
import java.time.LocalDateTime
import java.time.LocalTime
import java.time.ZoneId
import java.time.ZoneOffset
import java.time.ZonedDateTime
import java.time.format.DateTimeFormatter
import java.time.temporal.ChronoUnit
import java.util.Locale

enum class ConferenceSubcategory(val rawValue: String) {
    MachineLearning("ml"),
    ComputerVision("cv"),
    Nlp("nlp"),
    GeneralAi("general-ai");

    companion object {
        fun fromRawValue(value: String): ConferenceSubcategory =
            entries.firstOrNull { it.rawValue == value } ?: GeneralAi
    }
}

enum class DeadlineKind(val rawValue: String) {
    Abstract("abstract"),
    Submission("submission"),
    Supplementary("supplementary"),
    Notification("notification"),
    CameraReady("camera-ready"),
    ConferenceStart("conference-start"),
    ConferenceEnd("conference-end");

    companion object {
        fun fromRawValue(value: String): DeadlineKind =
            entries.firstOrNull { it.rawValue == value } ?: Submission
    }
}

data class ConferenceDeadline(
    val id: String,
    val label: String,
    val date: String,
    val time: String?,
    val timezone: String,
    val type: DeadlineKind,
    val isPrimary: Boolean,
)

data class Conference(
    val id: String,
    val name: String,
    val fullName: String,
    val year: Int,
    val fields: List<String>,
    val subcategory: ConferenceSubcategory,
    val location: String,
    val websiteUrl: String,
    val sourceUrl: String,
    val sourceCheckedAt: String,
    val timezone: String,
    val deadlines: List<ConferenceDeadline>,
)

data class CustomDeadline(
    val id: String,
    val name: String,
    val label: String,
    val date: String,
    val time: String,
    val timezone: String,
)

sealed interface DeadlineSource {
    data class ConferenceSource(
        val conferenceId: String,
        val deadlineId: String,
    ) : DeadlineSource

    data class CustomSource(val id: String) : DeadlineSource
}

data class DeadlineDisplay(
    val text: String,
    val days: Long,
    val remainingSeconds: Long,
    val deadlineInstant: Instant,
)

data class DeadlineSummary(
    val id: String,
    val title: String,
    val subtitle: String,
    val deadlineLabel: String,
    val sourceDateText: String,
    val websiteUrl: String?,
    val sourceUrl: String?,
    val source: DeadlineSource,
    val kind: DeadlineKind,
    val display: DeadlineDisplay,
) {
    fun localDateText(locale: Locale = Locale.getDefault()): String {
        val formatter = DateTimeFormatter.ofPattern("MMM d 'at' h:mm a z", locale)
        return display.deadlineInstant
            .atZone(ZoneId.systemDefault())
            .format(formatter)
    }
}

data class CalendarEventDraft(
    val title: String,
    val startMillis: Long,
    val endMillis: Long,
    val allDay: Boolean,
    val description: String,
    val url: String?,
)

enum class AppLanguage(val rawValue: String) {
    System("system"),
    English("english"),
    Korean("korean");

    companion object {
        fun fromRawValue(value: String?): AppLanguage =
            entries.firstOrNull { it.rawValue == value } ?: System
    }
}

enum class WidgetBackground(val rawValue: String) {
    System("system"),
    White("white"),
    Black("black"),
    Navy("navy");

    companion object {
        fun fromRawValue(value: String?): WidgetBackground =
            entries.firstOrNull { it.rawValue == value } ?: System
    }
}

enum class WidgetTextColor(val rawValue: String) {
    Auto("auto"),
    Black("black"),
    White("white");

    companion object {
        fun fromRawValue(value: String?): WidgetTextColor =
            entries.firstOrNull { it.rawValue == value } ?: Auto
    }
}

object DeadlineCalculator {
    private val defaultTime = LocalTime.of(23, 59)

    fun display(
        deadline: ConferenceDeadline,
        now: Instant = Instant.now(),
        displayZone: ZoneId = ZoneId.systemDefault(),
    ): DeadlineDisplay? {
        val deadlineInstant = instant(deadline) ?: return null
        val today = now.atZone(displayZone).toLocalDate()
        val deadlineDay = deadlineInstant.atZone(displayZone).toLocalDate()
        val days = ChronoUnit.DAYS.between(today, deadlineDay)
        val remainingSeconds = Duration.between(now, deadlineInstant).seconds
        val text = when {
            days == 0L && remainingSeconds > 0 -> countdownText(remainingSeconds)
            days > 0 -> "D-$days"
            days == 0L -> "D-Day"
            else -> "D+${-days}"
        }

        return DeadlineDisplay(
            text = text,
            days = days,
            remainingSeconds = remainingSeconds,
            deadlineInstant = deadlineInstant,
        )
    }

    fun instant(deadline: ConferenceDeadline): Instant? {
        return try {
            val date = LocalDate.parse(deadline.date)
            val time = deadline.time?.let(LocalTime::parse) ?: defaultTime
            val zone = resolveZone(deadline.timezone)
            ZonedDateTime.of(LocalDateTime.of(date, time), zone).toInstant()
        } catch (_: DateTimeException) {
            null
        }
    }

    fun resolveZone(identifier: String): ZoneId =
        if (identifier.equals("AoE", ignoreCase = true)) {
            ZoneOffset.ofHours(-12)
        } else {
            ZoneId.of(identifier)
        }

    private fun countdownText(remainingSeconds: Long): String {
        val totalMinutes = maxOf(1L, (remainingSeconds + 59) / 60)
        return if (totalMinutes >= 60) {
            val hours = (totalMinutes + 59) / 60
            "H-$hours"
        } else {
            "M-$totalMinutes"
        }
    }
}

fun Conference.summaryFor(
    deadline: ConferenceDeadline,
    now: Instant = Instant.now(),
): DeadlineSummary? {
    val display = DeadlineCalculator.display(deadline, now) ?: return null
    return DeadlineSummary(
        id = "$id-${deadline.id}",
        title = name,
        subtitle = fullName,
        deadlineLabel = deadline.label,
        sourceDateText = "${deadline.date} ${deadline.time ?: "23:59"} ${deadline.timezone}",
        websiteUrl = websiteUrl,
        sourceUrl = sourceUrl,
        source = DeadlineSource.ConferenceSource(id, deadline.id),
        kind = deadline.type,
        display = display,
    )
}

fun CustomDeadline.toSummary(now: Instant = Instant.now()): DeadlineSummary? {
    val deadline = ConferenceDeadline(
        id = "deadline",
        label = label,
        date = date,
        time = time,
        timezone = timezone,
        type = DeadlineKind.Submission,
        isPrimary = true,
    )
    val display = DeadlineCalculator.display(deadline, now) ?: return null
    return DeadlineSummary(
        id = "custom-$id",
        title = name,
        subtitle = label,
        deadlineLabel = label,
        sourceDateText = "$date $time $timezone",
        websiteUrl = null,
        sourceUrl = null,
        source = DeadlineSource.CustomSource(id),
        kind = DeadlineKind.Submission,
        display = display,
    )
}
