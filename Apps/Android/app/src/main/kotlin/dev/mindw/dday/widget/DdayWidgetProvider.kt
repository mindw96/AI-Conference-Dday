package dev.mindw.dday.widget

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews
import dev.mindw.dday.MainActivity
import dev.mindw.dday.R
import dev.mindw.dday.data.ConferenceRepository
import dev.mindw.dday.data.DdayPreferenceKeys
import dev.mindw.dday.model.AppLanguage
import dev.mindw.dday.model.CustomDeadline
import dev.mindw.dday.model.DeadlineSummary
import dev.mindw.dday.model.WidgetBackground
import dev.mindw.dday.model.WidgetTextColor
import dev.mindw.dday.model.summaryFor
import dev.mindw.dday.model.toSummary
import dev.mindw.dday.ui.AppStrings
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.launch
import org.json.JSONArray
import java.time.Instant

class DdayWidgetProvider : AppWidgetProvider() {
    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        if (intent.action in refreshActions) {
            updateAll(context)
        }
    }

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
    ) {
        val pendingResult = goAsync()
        CoroutineScope(SupervisorJob() + Dispatchers.IO).launch {
            try {
                val snapshot = WidgetSnapshotLoader(context).load()
                appWidgetIds.forEach { appWidgetId ->
                    appWidgetManager.updateAppWidget(
                        appWidgetId,
                        remoteViews(context, snapshot),
                    )
                }
            } finally {
                pendingResult.finish()
            }
        }
    }

    private fun remoteViews(context: Context, snapshot: WidgetSnapshot): RemoteViews =
        RemoteViews(context.packageName, R.layout.dday_widget).apply {
            setInt(
                R.id.widget_root,
                "setBackgroundResource",
                when (snapshot.background) {
                    WidgetBackground.System -> R.drawable.widget_background
                    WidgetBackground.White -> R.drawable.widget_background_white
                    WidgetBackground.Black -> R.drawable.widget_background_black
                    WidgetBackground.Navy -> R.drawable.widget_background_navy
                },
            )
            setTextViewText(R.id.widget_title, snapshot.title)
            setTextViewText(R.id.widget_countdown, snapshot.countdown)
            setTextViewText(R.id.widget_label, snapshot.label)

            val (primaryColor, secondaryColor) = textColors(context, snapshot)
            setTextColor(R.id.widget_title, primaryColor)
            setTextColor(R.id.widget_countdown, primaryColor)
            setTextColor(R.id.widget_label, secondaryColor)

            val openApp = PendingIntent.getActivity(
                context,
                0,
                Intent(context, MainActivity::class.java),
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
            )
            setOnClickPendingIntent(R.id.widget_root, openApp)
        }

    private fun textColors(context: Context, snapshot: WidgetSnapshot): Pair<Int, Int> {
        val colorResources = when (snapshot.textColor) {
            WidgetTextColor.Black ->
                R.color.widget_black to R.color.widget_secondary_black
            WidgetTextColor.White ->
                R.color.widget_white to R.color.widget_secondary_white
            WidgetTextColor.Auto -> when (snapshot.background) {
                WidgetBackground.System ->
                    R.color.widget_text_primary to R.color.widget_text_secondary
                WidgetBackground.White ->
                    R.color.widget_black to R.color.widget_secondary_black
                WidgetBackground.Black, WidgetBackground.Navy ->
                    R.color.widget_white to R.color.widget_secondary_white
            }
        }
        return context.getColor(colorResources.first) to context.getColor(colorResources.second)
    }

    companion object {
        private val refreshActions = setOf(
            Intent.ACTION_DATE_CHANGED,
            Intent.ACTION_TIME_CHANGED,
            Intent.ACTION_TIMEZONE_CHANGED,
            Intent.ACTION_LOCALE_CHANGED,
        )

        fun updateAll(context: Context) {
            val manager = AppWidgetManager.getInstance(context)
            val component = ComponentName(context, DdayWidgetProvider::class.java)
            val widgetIds = manager.getAppWidgetIds(component)
            if (widgetIds.isEmpty()) {
                return
            }

            val intent = Intent(context, DdayWidgetProvider::class.java).apply {
                action = AppWidgetManager.ACTION_APPWIDGET_UPDATE
                putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, widgetIds)
            }
            context.sendBroadcast(intent)
        }
    }
}

private data class WidgetSnapshot(
    val title: String,
    val countdown: String,
    val label: String,
    val background: WidgetBackground,
    val textColor: WidgetTextColor,
)

private class WidgetSnapshotLoader(context: Context) {
    private val appContext = context.applicationContext
    private val preferences =
        appContext.getSharedPreferences(DdayPreferenceKeys.FILE_NAME, Context.MODE_PRIVATE)

    suspend fun load(): WidgetSnapshot {
        val strings = AppStrings(
            AppLanguage.fromRawValue(preferences.getString(DdayPreferenceKeys.LANGUAGE, null)),
        )
        val background = WidgetBackground.fromRawValue(
            preferences.getString(DdayPreferenceKeys.WIDGET_BACKGROUND, null),
        )
        val textColor = WidgetTextColor.fromRawValue(
            preferences.getString(DdayPreferenceKeys.WIDGET_TEXT_COLOR, null),
        )
        val summary = selectedSummary()
        return if (summary != null) {
            WidgetSnapshot(
                title = summary.title,
                countdown = summary.display.text,
                label = summary.deadlineLabel,
                background = background,
                textColor = textColor,
            )
        } else {
            WidgetSnapshot(
                title = "Dday",
                countdown = "—",
                label = strings.chooseMain,
                background = background,
                textColor = textColor,
            )
        }
    }

    private suspend fun selectedSummary(): DeadlineSummary? {
        val now = Instant.now()
        return when (preferences.getString(DdayPreferenceKeys.SOURCE_KIND, null)) {
            "conference" -> {
                val conferenceId =
                    preferences.getString(DdayPreferenceKeys.CONFERENCE_ID, null)
                        ?: return null
                val deadlineId =
                    preferences.getString(DdayPreferenceKeys.DEADLINE_ID, null)
                        ?: return null
                val conference = ConferenceRepository(appContext)
                    .load()
                    .firstOrNull { it.id == conferenceId }
                    ?: return null
                val deadline =
                    conference.deadlines.firstOrNull { it.id == deadlineId }
                        ?: return null
                conference.summaryFor(deadline, now)
            }

            "custom" -> {
                val customId =
                    preferences.getString(DdayPreferenceKeys.CUSTOM_ID, null)
                        ?: return null
                loadCustomDeadlines()
                    .firstOrNull { it.id == customId }
                    ?.toSummary(now)
            }

            else -> null
        }
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
