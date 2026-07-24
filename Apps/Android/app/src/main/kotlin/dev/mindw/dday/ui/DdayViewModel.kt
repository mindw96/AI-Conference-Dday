package dev.mindw.dday.ui

import android.app.Application
import android.content.Context
import androidx.lifecycle.AndroidViewModel
import androidx.lifecycle.viewModelScope
import dev.mindw.dday.data.DdayPreferenceKeys
import dev.mindw.dday.data.ConferenceRepository
import dev.mindw.dday.model.AppLanguage
import dev.mindw.dday.model.CalendarEventDraft
import dev.mindw.dday.model.Conference
import dev.mindw.dday.model.ConferenceSubcategory
import dev.mindw.dday.model.CustomDeadline
import dev.mindw.dday.model.DeadlineKind
import dev.mindw.dday.model.DeadlineSource
import dev.mindw.dday.model.DeadlineSummary
import dev.mindw.dday.model.WidgetBackground
import dev.mindw.dday.model.WidgetTextColor
import dev.mindw.dday.model.summaryFor
import dev.mindw.dday.model.toSummary
import dev.mindw.dday.widget.DdayWidgetProvider
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.isActive
import kotlinx.coroutines.launch
import org.json.JSONArray
import org.json.JSONObject
import java.time.Instant
import java.time.LocalDate
import java.time.LocalTime
import java.time.ZoneOffset
import java.util.UUID

data class DdayUiState(
    val conferences: List<Conference> = emptyList(),
    val customDeadlines: List<CustomDeadline> = emptyList(),
    val selectedCategories: Set<ConferenceSubcategory> =
        setOf(ConferenceSubcategory.MachineLearning),
    val selectedSource: DeadlineSource? = null,
    val language: AppLanguage = AppLanguage.System,
    val widgetBackground: WidgetBackground = WidgetBackground.System,
    val widgetTextColor: WidgetTextColor = WidgetTextColor.Auto,
    val now: Instant = Instant.now(),
    val isLoading: Boolean = true,
    val errorMessage: String? = null,
    val isUpdating: Boolean = false,
    val updateStatus: UpdateStatus = UpdateStatus.Idle,
)

sealed interface UpdateStatus {
    data object Idle : UpdateStatus
    data object Success : UpdateStatus
    data class Failure(val message: String) : UpdateStatus
}

class DdayViewModel(application: Application) : AndroidViewModel(application) {
    private val repository = ConferenceRepository(application)
    private val preferences =
        application.getSharedPreferences(DdayPreferenceKeys.FILE_NAME, Context.MODE_PRIVATE)

    private val _state = MutableStateFlow(
        DdayUiState(
            customDeadlines = loadCustomDeadlines(),
            selectedCategories = loadSelectedCategories(),
            selectedSource = loadSelectedSource(),
            language = AppLanguage.fromRawValue(
                preferences.getString(DdayPreferenceKeys.LANGUAGE, null),
            ),
            widgetBackground = WidgetBackground.fromRawValue(
                preferences.getString(DdayPreferenceKeys.WIDGET_BACKGROUND, null),
            ),
            widgetTextColor = WidgetTextColor.fromRawValue(
                preferences.getString(DdayPreferenceKeys.WIDGET_TEXT_COLOR, null),
            ),
        ),
    )
    val state: StateFlow<DdayUiState> = _state.asStateFlow()

    init {
        loadConferences()
        viewModelScope.launch {
            while (isActive) {
                val waitMillis = 60_000L - (System.currentTimeMillis() % 60_000L)
                delay(waitMillis)
                _state.update { it.copy(now = Instant.now()) }
            }
        }
    }

    fun featuredSummary(): DeadlineSummary? =
        state.value.selectedSource?.let(::summaryForSource)

    fun customSummaries(): List<DeadlineSummary> =
        state.value.customDeadlines
            .mapNotNull { it.toSummary(state.value.now) }
            .sortedBy { it.display.deadlineInstant }

    fun upcomingSummaries(category: ConferenceSubcategory): List<DeadlineSummary> =
        state.value.conferences
            .asSequence()
            .filter { it.subcategory == category }
            .flatMap { conference ->
                conference.deadlines
                    .mapNotNull { conference.summaryFor(it, state.value.now) }
                    .asSequence()
            }
            .filter { it.display.remainingSeconds > 0 }
            .sortedBy { it.display.deadlineInstant }
            .toList()

    fun activeConferences(category: ConferenceSubcategory): List<Conference> =
        state.value.conferences
            .filter { it.subcategory == category }
            .filter { conference ->
                conference.deadlines.any { deadline ->
                    conference.summaryFor(deadline, state.value.now)
                        ?.display
                        ?.remainingSeconds
                        ?.let { it > 0 } == true
                }
            }

    fun pastConferences(category: ConferenceSubcategory): List<Conference> =
        activeConferences(category).mapTo(mutableSetOf()) { it.id }.let { activeIds ->
            state.value.conferences
                .filter { it.subcategory == category }
                .filterNot { it.id in activeIds }
        }

    fun summaries(conference: Conference): List<DeadlineSummary> =
        conference.deadlines
            .mapNotNull { conference.summaryFor(it, state.value.now) }
            .sortedBy { it.display.deadlineInstant }

    fun conferenceSummary(conference: Conference): DeadlineSummary? {
        val summaries = summaries(conference)
        return summaries.firstOrNull { it.display.remainingSeconds > 0 }
            ?: summaries.lastOrNull()
    }

    fun isSelected(source: DeadlineSource): Boolean =
        state.value.selectedSource == source

    fun toggleCategory(category: ConferenceSubcategory) {
        val current = state.value.selectedCategories
        if (category in current && current.size == 1) {
            return
        }

        val updated = if (category in current) current - category else current + category
        _state.update { it.copy(selectedCategories = updated) }
        preferences.edit()
            .putString(
                DdayPreferenceKeys.CATEGORIES,
                updated.joinToString(",") { it.rawValue },
            )
            .apply()
    }

    fun select(source: DeadlineSource) {
        _state.update { it.copy(selectedSource = source) }
        saveSelectedSource(source)
        DdayWidgetProvider.updateAll(getApplication())
    }

    fun setLanguage(language: AppLanguage) {
        _state.update { it.copy(language = language) }
        preferences.edit().putString(DdayPreferenceKeys.LANGUAGE, language.rawValue).apply()
        DdayWidgetProvider.updateAll(getApplication())
    }

    fun setWidgetBackground(background: WidgetBackground) {
        _state.update { it.copy(widgetBackground = background) }
        preferences.edit()
            .putString(DdayPreferenceKeys.WIDGET_BACKGROUND, background.rawValue)
            .apply()
        DdayWidgetProvider.updateAll(getApplication())
    }

    fun setWidgetTextColor(textColor: WidgetTextColor) {
        _state.update { it.copy(widgetTextColor = textColor) }
        preferences.edit()
            .putString(DdayPreferenceKeys.WIDGET_TEXT_COLOR, textColor.rawValue)
            .apply()
        DdayWidgetProvider.updateAll(getApplication())
    }

    fun addCustomDeadline(
        name: String,
        label: String,
        date: LocalDate,
        time: LocalTime,
        useAoe: Boolean,
    ) {
        val trimmedName = name.trim()
        if (trimmedName.isEmpty()) {
            return
        }

        val deadline = CustomDeadline(
            id = UUID.randomUUID().toString(),
            name = trimmedName,
            label = label.trim().ifEmpty { "Deadline" },
            date = date.toString(),
            time = time.withSecond(0).withNano(0).toString(),
            timezone = if (useAoe) "AoE" else java.time.ZoneId.systemDefault().id,
        )
        val updated = state.value.customDeadlines + deadline
        _state.update {
            it.copy(
                customDeadlines = updated,
                selectedSource = DeadlineSource.CustomSource(deadline.id),
            )
        }
        saveCustomDeadlines(updated)
        saveSelectedSource(DeadlineSource.CustomSource(deadline.id))
        DdayWidgetProvider.updateAll(getApplication())
    }

    fun removeCustomDeadline(id: String) {
        val updated = state.value.customDeadlines.filterNot { it.id == id }
        val selectedSource = state.value.selectedSource
        val newSelection =
            if (selectedSource == DeadlineSource.CustomSource(id)) null else selectedSource
        _state.update {
            it.copy(
                customDeadlines = updated,
                selectedSource = newSelection,
            )
        }
        saveCustomDeadlines(updated)
        if (newSelection == null) {
            clearSelectedSource()
        }
        DdayWidgetProvider.updateAll(getApplication())
    }

    fun refreshConferenceData() {
        if (state.value.isUpdating) {
            return
        }

        viewModelScope.launch {
            _state.update { it.copy(isUpdating = true, updateStatus = UpdateStatus.Idle) }
            try {
                val conferences = repository.refresh()
                _state.update {
                    it.copy(
                        conferences = conferences,
                        isUpdating = false,
                        updateStatus = UpdateStatus.Success,
                        errorMessage = null,
                    )
                }
                DdayWidgetProvider.updateAll(getApplication())
            } catch (error: Exception) {
                _state.update {
                    it.copy(
                        isUpdating = false,
                        updateStatus = UpdateStatus.Failure(
                            error.message ?: error.javaClass.simpleName,
                        ),
                    )
                }
                DdayWidgetProvider.updateAll(getApplication())
            }
        }
    }

    fun calendarDraft(summary: DeadlineSummary): CalendarEventDraft? {
        val strings = AppStrings(state.value.language)
        val source = summary.source
        if (source is DeadlineSource.ConferenceSource &&
            (summary.kind == DeadlineKind.ConferenceStart ||
                summary.kind == DeadlineKind.ConferenceEnd)
        ) {
            val conference =
                state.value.conferences.firstOrNull { it.id == source.conferenceId }
                    ?: return null
            return conferencePeriodDraft(conference, strings)
        }

        return CalendarEventDraft(
            title = "${summary.title} - ${summary.deadlineLabel}",
            startMillis = summary.display.deadlineInstant.toEpochMilli(),
            endMillis = summary.display.deadlineInstant.plusSeconds(30 * 60).toEpochMilli(),
            allDay = false,
            description = buildString {
                append("${strings.localTime}: ${summary.localDateText(strings.locale)}")
                append("\n${strings.sourceTime}: ${summary.sourceDateText}")
                summary.websiteUrl?.let {
                    append("\n${strings.conferenceWebsiteLabel}: $it")
                }
            },
            url = summary.websiteUrl,
        )
    }

    private fun conferencePeriodDraft(
        conference: Conference,
        strings: AppStrings,
    ): CalendarEventDraft? {
        val start = conference.deadlines.firstOrNull {
            it.type == DeadlineKind.ConferenceStart
        }
        val end = conference.deadlines.firstOrNull {
            it.type == DeadlineKind.ConferenceEnd
        }
        val anchor = start ?: end ?: return null

        val firstDay = runCatching { LocalDate.parse((start ?: anchor).date) }.getOrNull()
            ?: return null
        val lastDay = runCatching { LocalDate.parse((end ?: anchor).date) }.getOrNull()
            ?: return null
        val orderedStart = minOf(firstDay, lastDay)
        val orderedEnd = maxOf(firstDay, lastDay).plusDays(1)

        return CalendarEventDraft(
            title = "${conference.name} - ${strings.conferencePeriod}",
            startMillis = orderedStart.atStartOfDay(ZoneOffset.UTC).toInstant().toEpochMilli(),
            endMillis = orderedEnd.atStartOfDay(ZoneOffset.UTC).toInstant().toEpochMilli(),
            allDay = true,
            description = buildString {
                append(conference.fullName)
                if (conference.location.isNotBlank()) append("\n${conference.location}")
                append("\n${conference.websiteUrl}")
            },
            url = conference.websiteUrl,
        )
    }

    private fun summaryForSource(source: DeadlineSource): DeadlineSummary? =
        when (source) {
            is DeadlineSource.ConferenceSource -> {
                val conference =
                    state.value.conferences.firstOrNull { it.id == source.conferenceId }
                        ?: return null
                val deadline =
                    conference.deadlines.firstOrNull { it.id == source.deadlineId }
                        ?: return null
                conference.summaryFor(deadline, state.value.now)
            }

            is DeadlineSource.CustomSource ->
                state.value.customDeadlines
                    .firstOrNull { it.id == source.id }
                    ?.toSummary(state.value.now)
        }

    private fun loadConferences() {
        viewModelScope.launch {
            try {
                val conferences = repository.load()
                _state.update {
                    it.copy(
                        conferences = conferences,
                        isLoading = false,
                        errorMessage = null,
                    )
                }
                DdayWidgetProvider.updateAll(getApplication())
            } catch (error: Exception) {
                _state.update {
                    it.copy(
                        isLoading = false,
                        errorMessage = error.message ?: error.javaClass.simpleName,
                    )
                }
            }
        }
    }

    private fun loadSelectedCategories(): Set<ConferenceSubcategory> {
        val values = preferences.getString(DdayPreferenceKeys.CATEGORIES, null)
            ?.split(",")
            ?.toSet()
            .orEmpty()
        val selected = ConferenceSubcategory.entries.filter { it.rawValue in values }.toSet()
        return selected.ifEmpty { setOf(ConferenceSubcategory.MachineLearning) }
    }

    private fun saveSelectedSource(source: DeadlineSource) {
        preferences.edit().apply {
            when (source) {
                is DeadlineSource.ConferenceSource -> {
                    putString(DdayPreferenceKeys.SOURCE_KIND, "conference")
                    putString(DdayPreferenceKeys.CONFERENCE_ID, source.conferenceId)
                    putString(DdayPreferenceKeys.DEADLINE_ID, source.deadlineId)
                    remove(DdayPreferenceKeys.CUSTOM_ID)
                }

                is DeadlineSource.CustomSource -> {
                    putString(DdayPreferenceKeys.SOURCE_KIND, "custom")
                    putString(DdayPreferenceKeys.CUSTOM_ID, source.id)
                    remove(DdayPreferenceKeys.CONFERENCE_ID)
                    remove(DdayPreferenceKeys.DEADLINE_ID)
                }
            }
        }.apply()
    }

    private fun loadSelectedSource(): DeadlineSource? =
        when (preferences.getString(DdayPreferenceKeys.SOURCE_KIND, null)) {
            "conference" -> {
                val conferenceId =
                    preferences.getString(DdayPreferenceKeys.CONFERENCE_ID, null)
                val deadlineId =
                    preferences.getString(DdayPreferenceKeys.DEADLINE_ID, null)
                if (conferenceId != null && deadlineId != null) {
                    DeadlineSource.ConferenceSource(conferenceId, deadlineId)
                } else {
                    null
                }
            }

            "custom" ->
                preferences.getString(DdayPreferenceKeys.CUSTOM_ID, null)
                    ?.let { DeadlineSource.CustomSource(it) }

            else -> null
        }

    private fun clearSelectedSource() {
        preferences.edit()
            .remove(DdayPreferenceKeys.SOURCE_KIND)
            .remove(DdayPreferenceKeys.CONFERENCE_ID)
            .remove(DdayPreferenceKeys.DEADLINE_ID)
            .remove(DdayPreferenceKeys.CUSTOM_ID)
            .apply()
    }

    private fun saveCustomDeadlines(deadlines: List<CustomDeadline>) {
        val json = JSONArray()
        deadlines.forEach { deadline ->
            json.put(
                JSONObject()
                    .put("id", deadline.id)
                    .put("name", deadline.name)
                    .put("label", deadline.label)
                    .put("date", deadline.date)
                    .put("time", deadline.time)
                    .put("timezone", deadline.timezone),
            )
        }
        preferences.edit()
            .putString(DdayPreferenceKeys.CUSTOM_DEADLINES, json.toString())
            .apply()
    }

    private fun loadCustomDeadlines(): List<CustomDeadline> {
        val text =
            preferences.getString(DdayPreferenceKeys.CUSTOM_DEADLINES, null)
                ?: return emptyList()
        return runCatching {
            val json = JSONArray(text)
            buildList(json.length()) {
                for (index in 0 until json.length()) {
                    val item = json.getJSONObject(index)
                    add(
                        CustomDeadline(
                            id = item.getString("id"),
                            name = item.getString("name"),
                            label = item.getString("label"),
                            date = item.getString("date"),
                            time = item.getString("time"),
                            timezone = item.getString("timezone"),
                        ),
                    )
                }
            }
        }.getOrDefault(emptyList())
    }

}
