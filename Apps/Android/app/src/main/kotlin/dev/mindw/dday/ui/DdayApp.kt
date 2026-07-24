package dev.mindw.dday.ui

import android.app.DatePickerDialog
import android.app.TimePickerDialog
import android.content.ActivityNotFoundException
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.provider.CalendarContract
import androidx.annotation.DrawableRes
import androidx.compose.animation.AnimatedVisibility
import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.WindowInsets
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.safeDrawing
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.Button
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.FilterChip
import androidx.compose.material3.FilledIconButton
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.ModalBottomSheet
import androidx.compose.material3.NavigationBar
import androidx.compose.material3.NavigationBarItem
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Scaffold
import androidx.compose.material3.SnackbarHost
import androidx.compose.material3.SnackbarHostState
import androidx.compose.material3.Surface
import androidx.compose.material3.Switch
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateMapOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.lifecycle.viewmodel.compose.viewModel
import dev.mindw.dday.R
import dev.mindw.dday.model.AppLanguage
import dev.mindw.dday.model.CalendarEventDraft
import dev.mindw.dday.model.Conference
import dev.mindw.dday.model.ConferenceSubcategory
import dev.mindw.dday.model.DeadlineSource
import dev.mindw.dday.model.DeadlineSummary
import dev.mindw.dday.model.WidgetBackground
import dev.mindw.dday.model.WidgetTextColor
import kotlinx.coroutines.launch
import java.net.URI
import java.time.LocalDate
import java.time.LocalTime

private enum class AppTab(
    @param:DrawableRes val icon: Int,
) {
    Home(R.drawable.ic_home),
    Conferences(R.drawable.ic_calendar),
    Custom(R.drawable.ic_add_box),
    Settings(R.drawable.ic_settings),
}

@Composable
fun DdayApp(viewModel: DdayViewModel = viewModel()) {
    val state by viewModel.state.collectAsStateWithLifecycle()
    val strings = remember(state.language) { AppStrings(state.language) }
    var selectedTab by rememberSaveable { mutableStateOf(AppTab.Home) }
    val snackbarHostState = remember { SnackbarHostState() }
    val scope = rememberCoroutineScope()
    val context = androidx.compose.ui.platform.LocalContext.current

    val addToCalendar: (DeadlineSummary) -> Unit = { summary ->
        val draft = viewModel.calendarDraft(summary)
        if (draft == null || !openCalendar(context, draft)) {
            scope.launch { snackbarHostState.showSnackbar(strings.calendarUnavailable) }
        }
    }

    Scaffold(
        modifier = Modifier.fillMaxSize(),
        contentWindowInsets = WindowInsets.safeDrawing,
        containerColor = MaterialTheme.colorScheme.background,
        snackbarHost = { SnackbarHost(snackbarHostState) },
        bottomBar = {
            NavigationBar(
                containerColor = MaterialTheme.colorScheme.surface.copy(alpha = 0.97f),
            ) {
                AppTab.entries.forEach { tab ->
                    val label = when (tab) {
                        AppTab.Home -> strings.home
                        AppTab.Conferences -> strings.conferences
                        AppTab.Custom -> strings.custom
                        AppTab.Settings -> strings.settings
                    }
                    NavigationBarItem(
                        selected = selectedTab == tab,
                        onClick = { selectedTab = tab },
                        icon = {
                            Icon(
                                painter = painterResource(tab.icon),
                                contentDescription = label,
                                modifier = Modifier.size(23.dp),
                            )
                        },
                        label = {
                            Text(
                                text = label,
                                maxLines = 1,
                                overflow = TextOverflow.Ellipsis,
                            )
                        },
                    )
                }
            }
        },
    ) { padding ->
        Box(
            modifier = Modifier
                .fillMaxSize()
                .padding(padding),
        ) {
            when (selectedTab) {
                AppTab.Home -> HomeScreen(
                    state = state,
                    viewModel = viewModel,
                    strings = strings,
                    onAddToCalendar = addToCalendar,
                )

                AppTab.Conferences -> ConferencesScreen(
                    state = state,
                    viewModel = viewModel,
                    strings = strings,
                )

                AppTab.Custom -> CustomScreen(
                    state = state,
                    viewModel = viewModel,
                    strings = strings,
                )

                AppTab.Settings -> SettingsScreen(
                    state = state,
                    viewModel = viewModel,
                    strings = strings,
                )
            }
        }
    }
}

@Composable
private fun HomeScreen(
    state: DdayUiState,
    viewModel: DdayViewModel,
    strings: AppStrings,
    onAddToCalendar: (DeadlineSummary) -> Unit,
) {
    val featured = viewModel.featuredSummary()
    val collapsedGroups = remember { mutableStateMapOf<String, Boolean>() }

    LazyColumn(
        modifier = Modifier.fillMaxSize(),
        contentPadding = PaddingValues(horizontal = 20.dp, vertical = 24.dp),
        verticalArrangement = Arrangement.spacedBy(24.dp),
    ) {
        item { PageTitle(strings.appTitle) }

        when {
            state.isLoading -> item {
                Box(
                    modifier = Modifier
                        .fillMaxWidth()
                        .height(220.dp),
                    contentAlignment = Alignment.Center,
                ) {
                    CircularProgressIndicator()
                }
            }

            state.errorMessage != null -> item {
                EmptyStateCard(
                    title = strings.conferenceDataUnavailable,
                    description = state.errorMessage,
                )
            }

            featured != null -> item {
                DeadlineHero(featured, strings)
            }

            else -> item {
                EmptyStateCard(
                    title = strings.chooseMain,
                    description = strings.chooseMainDescription,
                )
            }
        }

        if (!state.isLoading && state.errorMessage == null) {
            val groups = buildList {
                val custom = viewModel.customSummaries()
                    .filter { it.display.remainingSeconds > 0 }
                if (custom.isNotEmpty()) {
                    add(DeadlineGroup("custom", strings.custom, custom))
                }

                ConferenceSubcategory.entries.forEach { category ->
                    if (category in state.selectedCategories) {
                        val summaries = viewModel.upcomingSummaries(category)
                        if (summaries.isNotEmpty()) {
                            add(
                                DeadlineGroup(
                                    category.rawValue,
                                    strings.categoryTitle(category),
                                    summaries,
                                ),
                            )
                        }
                    }
                }
            }

            item {
                Text(
                    text = strings.upcoming,
                    style = MaterialTheme.typography.headlineSmall,
                    fontWeight = FontWeight.Bold,
                )
            }

            if (groups.isEmpty()) {
                item { EmptyStateCard(strings.noUpcoming) }
            } else {
                groups.forEach { group ->
                    item(key = group.id) {
                        val expanded = collapsedGroups[group.id] != true
                        DeadlineGroupSection(
                            group = group,
                            expanded = expanded,
                            onToggle = {
                                collapsedGroups[group.id] = expanded
                            },
                            onSelect = viewModel::select,
                            onAddToCalendar = onAddToCalendar,
                            addToCalendarLabel = strings.addToCalendar,
                        )
                    }
                }
            }
        }
    }
}

private data class DeadlineGroup(
    val id: String,
    val title: String,
    val summaries: List<DeadlineSummary>,
)

@Composable
private fun DeadlineHero(summary: DeadlineSummary, strings: AppStrings) {
    Surface(
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(8.dp),
        color = MaterialTheme.colorScheme.surface,
    ) {
        Column(
            modifier = Modifier.padding(20.dp),
            verticalArrangement = Arrangement.spacedBy(14.dp),
        ) {
            Text(
                text = strings.mainDday,
                style = MaterialTheme.typography.titleMedium,
                fontWeight = FontWeight.SemiBold,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
            )
            Text(
                text = summary.title,
                fontSize = 32.sp,
                fontWeight = FontWeight.Bold,
            )
            Text(
                text = summary.display.text,
                fontSize = 54.sp,
                lineHeight = 58.sp,
                fontWeight = FontWeight.Bold,
            )
            Column(verticalArrangement = Arrangement.spacedBy(4.dp)) {
                Text(
                    text = summary.deadlineLabel,
                    style = MaterialTheme.typography.titleMedium,
                    fontWeight = FontWeight.SemiBold,
                )
                Text(
                    text = summary.localDateText(strings.locale),
                    style = MaterialTheme.typography.bodyLarge,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                )
            }
        }
    }
}

@Composable
private fun DeadlineGroupSection(
    group: DeadlineGroup,
    expanded: Boolean,
    onToggle: () -> Unit,
    onSelect: (DeadlineSource) -> Unit,
    onAddToCalendar: (DeadlineSummary) -> Unit,
    addToCalendarLabel: String,
) {
    Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .clickable(onClick = onToggle)
                .padding(vertical = 4.dp),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            Text(
                text = group.title,
                style = MaterialTheme.typography.titleSmall,
                fontWeight = FontWeight.SemiBold,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
            )
            Spacer(Modifier.width(8.dp))
            Text(
                text = group.summaries.size.toString(),
                style = MaterialTheme.typography.labelSmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
            )
            Spacer(Modifier.weight(1f))
            Text(
                text = if (expanded) "⌄" else "›",
                style = MaterialTheme.typography.titleLarge,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
            )
        }

        AnimatedVisibility(visible = expanded) {
            Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                group.summaries.forEach { summary ->
                    DeadlineRow(
                        summary = summary,
                        onSelect = { onSelect(summary.source) },
                        onAddToCalendar = { onAddToCalendar(summary) },
                        addToCalendarLabel = addToCalendarLabel,
                    )
                }
            }
        }
    }
}

@Composable
private fun DeadlineRow(
    summary: DeadlineSummary,
    onSelect: () -> Unit,
    onAddToCalendar: () -> Unit,
    addToCalendarLabel: String,
) {
    Surface(
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(8.dp),
        color = MaterialTheme.colorScheme.surface,
    ) {
        Row(
            modifier = Modifier.padding(start = 16.dp, top = 12.dp, bottom = 12.dp, end = 8.dp),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            Row(
                modifier = Modifier
                    .weight(1f)
                    .clickable(onClick = onSelect),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                Column(
                    modifier = Modifier.weight(1f),
                    verticalArrangement = Arrangement.spacedBy(3.dp),
                ) {
                    Text(
                        text = summary.title,
                        style = MaterialTheme.typography.titleMedium,
                        fontWeight = FontWeight.SemiBold,
                    )
                    Text(
                        text = summary.deadlineLabel,
                        style = MaterialTheme.typography.bodySmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant,
                        maxLines = 1,
                        overflow = TextOverflow.Ellipsis,
                    )
                }
                Text(
                    text = summary.display.text,
                    style = MaterialTheme.typography.titleLarge,
                    fontWeight = FontWeight.Bold,
                )
            }

            IconButton(onClick = onAddToCalendar) {
                Icon(
                    painter = painterResource(R.drawable.ic_calendar_add),
                    contentDescription = addToCalendarLabel,
                    tint = MaterialTheme.colorScheme.onSurfaceVariant,
                )
            }
        }
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun ConferencesScreen(
    state: DdayUiState,
    viewModel: DdayViewModel,
    strings: AppStrings,
) {
    var selectedConference by remember { mutableStateOf<Conference?>(null) }

    LazyColumn(
        modifier = Modifier.fillMaxSize(),
        contentPadding = PaddingValues(horizontal = 20.dp, vertical = 24.dp),
        verticalArrangement = Arrangement.spacedBy(18.dp),
    ) {
        item { PageTitle(strings.categories) }
        item {
            Surface(
                modifier = Modifier.fillMaxWidth(),
                shape = RoundedCornerShape(8.dp),
                color = MaterialTheme.colorScheme.surface,
            ) {
                Column {
                    ConferenceSubcategory.entries.forEachIndexed { index, category ->
                        Row(
                            modifier = Modifier
                                .fillMaxWidth()
                                .clickable { viewModel.toggleCategory(category) }
                                .padding(horizontal = 16.dp, vertical = 17.dp),
                            verticalAlignment = Alignment.CenterVertically,
                        ) {
                            Text(
                                text = strings.categoryTitle(category),
                                style = MaterialTheme.typography.bodyLarge,
                            )
                            Spacer(Modifier.weight(1f))
                            if (category in state.selectedCategories) {
                                Text(
                                    text = "✓",
                                    color = MaterialTheme.colorScheme.primary,
                                    fontSize = 24.sp,
                                    fontWeight = FontWeight.Medium,
                                )
                            }
                        }
                        if (index != ConferenceSubcategory.entries.lastIndex) {
                            HorizontalDivider(
                                modifier = Modifier.padding(horizontal = 16.dp),
                                color = MaterialTheme.colorScheme.outlineVariant,
                            )
                        }
                    }
                }
            }
        }

        ConferenceSubcategory.entries.forEach { category ->
            if (category in state.selectedCategories) {
                val active = viewModel.activeConferences(category)
                if (active.isNotEmpty()) {
                    item {
                        SectionTitle(strings.categoryTitle(category))
                    }
                    items(active, key = { it.id }) { conference ->
                        ConferenceRow(
                            conference = conference,
                            summary = viewModel.conferenceSummary(conference),
                            onClick = { selectedConference = conference },
                        )
                    }
                }

                val past = viewModel.pastConferences(category)
                if (past.isNotEmpty()) {
                    item {
                        SectionTitle(
                            "${strings.categoryTitle(category)} · ${strings.pastConferences}",
                        )
                    }
                    items(past, key = { "past-${it.id}" }) { conference ->
                        ConferenceRow(
                            conference = conference,
                            summary = viewModel.conferenceSummary(conference),
                            onClick = { selectedConference = conference },
                        )
                    }
                }
            }
        }
    }

    selectedConference?.let { conference ->
        ConferenceDetailSheet(
            conference = conference,
            summaries = viewModel.summaries(conference),
            strings = strings,
            isSelected = viewModel::isSelected,
            onSelect = viewModel::select,
            onDismiss = { selectedConference = null },
        )
    }
}

@Composable
private fun ConferenceRow(
    conference: Conference,
    summary: DeadlineSummary?,
    onClick: () -> Unit,
) {
    Surface(
        modifier = Modifier
            .fillMaxWidth()
            .clickable(onClick = onClick),
        shape = RoundedCornerShape(8.dp),
        color = MaterialTheme.colorScheme.surface,
    ) {
        Row(
            modifier = Modifier.padding(16.dp),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            Column(
                modifier = Modifier.weight(1f),
                verticalArrangement = Arrangement.spacedBy(3.dp),
            ) {
                Text(
                    text = conference.name,
                    style = MaterialTheme.typography.titleMedium,
                    fontWeight = FontWeight.SemiBold,
                )
                summary?.let {
                    Text(
                        text = it.deadlineLabel,
                        style = MaterialTheme.typography.bodySmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant,
                        maxLines = 1,
                        overflow = TextOverflow.Ellipsis,
                    )
                }
            }
            summary?.let {
                Text(
                    text = it.display.text,
                    style = MaterialTheme.typography.titleLarge,
                    fontWeight = FontWeight.Bold,
                )
            }
        }
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun ConferenceDetailSheet(
    conference: Conference,
    summaries: List<DeadlineSummary>,
    strings: AppStrings,
    isSelected: (DeadlineSource) -> Boolean,
    onSelect: (DeadlineSource) -> Unit,
    onDismiss: () -> Unit,
) {
    val context = androidx.compose.ui.platform.LocalContext.current

    ModalBottomSheet(onDismissRequest = onDismiss) {
        LazyColumn(
            contentPadding = PaddingValues(start = 20.dp, end = 20.dp, bottom = 40.dp),
            verticalArrangement = Arrangement.spacedBy(14.dp),
        ) {
            item {
                Column(verticalArrangement = Arrangement.spacedBy(6.dp)) {
                    Text(
                        text = conference.name,
                        fontSize = 34.sp,
                        fontWeight = FontWeight.Bold,
                    )
                    Text(
                        text = conference.fullName,
                        style = MaterialTheme.typography.titleMedium,
                        fontWeight = FontWeight.SemiBold,
                    )
                    Text(
                        text = "${conference.location} · ${conference.year}",
                        color = MaterialTheme.colorScheme.onSurfaceVariant,
                    )
                }
            }

            item { SectionTitle(strings.deadlines) }

            items(summaries, key = { it.id }) { summary ->
                Surface(
                    modifier = Modifier.fillMaxWidth(),
                    shape = RoundedCornerShape(8.dp),
                    color = MaterialTheme.colorScheme.surfaceVariant,
                ) {
                    Column(
                        modifier = Modifier.padding(16.dp),
                        verticalArrangement = Arrangement.spacedBy(10.dp),
                    ) {
                        Row(verticalAlignment = Alignment.CenterVertically) {
                            Column(
                                modifier = Modifier.weight(1f),
                                verticalArrangement = Arrangement.spacedBy(3.dp),
                            ) {
                                Text(
                                    text = summary.deadlineLabel,
                                    fontWeight = FontWeight.SemiBold,
                                )
                                Text(
                                    text = summary.sourceDateText,
                                    style = MaterialTheme.typography.bodySmall,
                                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                                )
                            }
                            Text(
                                text = summary.display.text,
                                style = MaterialTheme.typography.titleLarge,
                                fontWeight = FontWeight.Bold,
                            )
                        }
                        OutlinedButton(onClick = { onSelect(summary.source) }) {
                            Text(
                                if (isSelected(summary.source)) {
                                    strings.selected
                                } else {
                                    strings.setMainDday
                                },
                            )
                        }
                    }
                }
            }

            item {
                Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                    OutlinedButton(
                        modifier = Modifier.fillMaxWidth(),
                        onClick = { openWebUrl(context, conference.websiteUrl) },
                    ) {
                        Text(strings.conferenceWebsite)
                    }
                    OutlinedButton(
                        modifier = Modifier.fillMaxWidth(),
                        onClick = { openWebUrl(context, conference.sourceUrl) },
                    ) {
                        Text(strings.sourcePage)
                    }
                }
            }
        }
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun CustomScreen(
    state: DdayUiState,
    viewModel: DdayViewModel,
    strings: AppStrings,
) {
    var showAddSheet by rememberSaveable { mutableStateOf(false) }
    val summaries = viewModel.customSummaries()

    LazyColumn(
        modifier = Modifier.fillMaxSize(),
        contentPadding = PaddingValues(horizontal = 20.dp, vertical = 24.dp),
        verticalArrangement = Arrangement.spacedBy(12.dp),
    ) {
        item {
            Row(verticalAlignment = Alignment.CenterVertically) {
                PageTitle(strings.custom, Modifier.weight(1f))
                FilledIconButton(
                    onClick = { showAddSheet = true },
                    shape = CircleShape,
                ) {
                    Icon(
                        painter = painterResource(R.drawable.ic_add_box),
                        contentDescription = strings.addCustom,
                    )
                }
            }
        }

        if (summaries.isEmpty()) {
            item {
                EmptyStateCard(
                    title = strings.noCustom,
                    icon = R.drawable.ic_calendar_add,
                )
            }
        } else {
            items(summaries, key = { it.id }) { summary ->
                Surface(
                    modifier = Modifier.fillMaxWidth(),
                    shape = RoundedCornerShape(8.dp),
                    color = MaterialTheme.colorScheme.surface,
                ) {
                    Column(
                        modifier = Modifier.padding(16.dp),
                        verticalArrangement = Arrangement.spacedBy(10.dp),
                    ) {
                        Row(verticalAlignment = Alignment.CenterVertically) {
                            Column(
                                modifier = Modifier.weight(1f),
                                verticalArrangement = Arrangement.spacedBy(3.dp),
                            ) {
                                Text(
                                    summary.title,
                                    style = MaterialTheme.typography.titleMedium,
                                    fontWeight = FontWeight.SemiBold,
                                )
                                Text(
                                    summary.deadlineLabel,
                                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                                )
                            }
                            Text(
                                summary.display.text,
                                style = MaterialTheme.typography.headlineSmall,
                                fontWeight = FontWeight.Bold,
                            )
                        }
                        Text(
                            summary.localDateText(strings.locale),
                            style = MaterialTheme.typography.bodySmall,
                            color = MaterialTheme.colorScheme.onSurfaceVariant,
                        )
                        Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                            OutlinedButton(onClick = { viewModel.select(summary.source) }) {
                                Text(
                                    if (viewModel.isSelected(summary.source)) {
                                        strings.selected
                                    } else {
                                        strings.setMainDday
                                    },
                                )
                            }
                            TextButton(
                                onClick = {
                                    val source = summary.source as? DeadlineSource.CustomSource
                                    source?.let { viewModel.removeCustomDeadline(it.id) }
                                },
                            ) {
                                Text(strings.delete, color = MaterialTheme.colorScheme.error)
                            }
                        }
                    }
                }
            }
        }
    }

    if (showAddSheet) {
        AddCustomDeadlineSheet(
            strings = strings,
            onSave = { name, label, date, time, useAoe ->
                viewModel.addCustomDeadline(name, label, date, time, useAoe)
                showAddSheet = false
            },
            onDismiss = { showAddSheet = false },
        )
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun AddCustomDeadlineSheet(
    strings: AppStrings,
    onSave: (String, String, LocalDate, LocalTime, Boolean) -> Unit,
    onDismiss: () -> Unit,
) {
    val context = androidx.compose.ui.platform.LocalContext.current
    var name by rememberSaveable { mutableStateOf("") }
    var label by rememberSaveable { mutableStateOf("Deadline") }
    var dateText by rememberSaveable { mutableStateOf(LocalDate.now().plusDays(1).toString()) }
    var timeText by rememberSaveable { mutableStateOf("23:59") }
    var useAoe by rememberSaveable { mutableStateOf(true) }

    ModalBottomSheet(onDismissRequest = onDismiss) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .verticalScroll(rememberScrollState())
                .padding(start = 20.dp, end = 20.dp, bottom = 36.dp),
            verticalArrangement = Arrangement.spacedBy(14.dp),
        ) {
            Text(
                strings.addCustom,
                fontSize = 30.sp,
                fontWeight = FontWeight.Bold,
            )
            OutlinedTextField(
                value = name,
                onValueChange = { name = it },
                label = { Text(strings.name) },
                modifier = Modifier.fillMaxWidth(),
                singleLine = true,
            )
            OutlinedTextField(
                value = label,
                onValueChange = { label = it },
                label = { Text(strings.label) },
                modifier = Modifier.fillMaxWidth(),
                singleLine = true,
            )
            Row(horizontalArrangement = Arrangement.spacedBy(10.dp)) {
                OutlinedButton(
                    modifier = Modifier.weight(1f),
                    onClick = {
                        val date = LocalDate.parse(dateText)
                        DatePickerDialog(
                            context,
                            { _, year, month, day ->
                                dateText = LocalDate.of(year, month + 1, day).toString()
                            },
                            date.year,
                            date.monthValue - 1,
                            date.dayOfMonth,
                        ).show()
                    },
                ) {
                    Text("${strings.date}: $dateText")
                }
                OutlinedButton(
                    modifier = Modifier.weight(1f),
                    onClick = {
                        val time = LocalTime.parse(timeText)
                        TimePickerDialog(
                            context,
                            { _, hour, minute ->
                                timeText = LocalTime.of(hour, minute).toString()
                            },
                            time.hour,
                            time.minute,
                            true,
                        ).show()
                    },
                ) {
                    Text("${strings.time}: $timeText")
                }
            }
            Row(
                modifier = Modifier.fillMaxWidth(),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                Column(Modifier.weight(1f)) {
                    Text(strings.timezone, fontWeight = FontWeight.SemiBold)
                    Text(
                        if (useAoe) "AoE" else strings.localTimezone,
                        color = MaterialTheme.colorScheme.onSurfaceVariant,
                    )
                }
                Switch(checked = useAoe, onCheckedChange = { useAoe = it })
            }
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(10.dp, Alignment.End),
            ) {
                TextButton(onClick = onDismiss) { Text(strings.cancel) }
                Button(
                    enabled = name.isNotBlank(),
                    onClick = {
                        onSave(
                            name,
                            label,
                            LocalDate.parse(dateText),
                            LocalTime.parse(timeText),
                            useAoe,
                        )
                    },
                ) {
                    Text(strings.save)
                }
            }
        }
    }
}

@Composable
private fun SettingsScreen(
    state: DdayUiState,
    viewModel: DdayViewModel,
    strings: AppStrings,
) {
    LazyColumn(
        modifier = Modifier.fillMaxSize(),
        contentPadding = PaddingValues(horizontal = 20.dp, vertical = 24.dp),
        verticalArrangement = Arrangement.spacedBy(18.dp),
    ) {
        item { PageTitle(strings.settings) }
        item { SectionTitle(strings.language) }
        item {
            Surface(
                modifier = Modifier.fillMaxWidth(),
                shape = RoundedCornerShape(8.dp),
                color = MaterialTheme.colorScheme.surface,
            ) {
                Row(
                    modifier = Modifier.padding(12.dp),
                    horizontalArrangement = Arrangement.spacedBy(8.dp),
                ) {
                    AppLanguage.entries.forEach { language ->
                        FilterChip(
                            modifier = Modifier.weight(1f),
                            selected = state.language == language,
                            onClick = { viewModel.setLanguage(language) },
                            label = {
                                Text(
                                    strings.languageTitle(language),
                                    modifier = Modifier.fillMaxWidth(),
                                    maxLines = 1,
                                )
                            },
                        )
                    }
                }
            }
        }

        item { SectionTitle(strings.data) }
        item {
            Surface(
                modifier = Modifier
                    .fillMaxWidth()
                    .clickable(enabled = !state.isUpdating) {
                        viewModel.refreshConferenceData()
                    },
                shape = RoundedCornerShape(8.dp),
                color = MaterialTheme.colorScheme.surface,
            ) {
                Row(
                    modifier = Modifier.padding(16.dp),
                    verticalAlignment = Alignment.CenterVertically,
                ) {
                    Text(
                        if (state.isUpdating) strings.updating else strings.checkUpdates,
                        color = MaterialTheme.colorScheme.primary,
                        style = MaterialTheme.typography.bodyLarge,
                    )
                    Spacer(Modifier.weight(1f))
                    if (state.isUpdating) {
                        CircularProgressIndicator(Modifier.size(22.dp), strokeWidth = 2.dp)
                    }
                }
            }
        }

        when (val status = state.updateStatus) {
            UpdateStatus.Idle -> Unit
            UpdateStatus.Success -> item {
                Text(
                    strings.updateSucceeded,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                )
            }
            is UpdateStatus.Failure -> item {
                Text(
                    strings.updateFailed(status.message),
                    color = MaterialTheme.colorScheme.error,
                )
            }
        }

        item { SectionTitle(strings.widgetAppearance) }
        item {
            Surface(
                modifier = Modifier.fillMaxWidth(),
                shape = RoundedCornerShape(8.dp),
                color = MaterialTheme.colorScheme.surface,
            ) {
                Column(
                    modifier = Modifier.padding(16.dp),
                    verticalArrangement = Arrangement.spacedBy(14.dp),
                ) {
                    Text(
                        text = strings.widgetAppearanceDescription,
                        color = MaterialTheme.colorScheme.onSurfaceVariant,
                        style = MaterialTheme.typography.bodyLarge,
                    )
                    Text(
                        text = strings.background,
                        style = MaterialTheme.typography.titleMedium,
                        fontWeight = FontWeight.Bold,
                    )
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.spacedBy(12.dp),
                    ) {
                        WidgetBackground.entries.forEach { background ->
                            AppearanceOption(
                                modifier = Modifier.weight(1f),
                                label = strings.widgetBackgroundTitle(background),
                                color = when (background) {
                                    WidgetBackground.System -> Color(0xFFE5E5EA)
                                    WidgetBackground.White -> Color.White
                                    WidgetBackground.Black -> Color.Black
                                    WidgetBackground.Navy -> Color(0xFF111C3A)
                                },
                                checkColor = when (background) {
                                    WidgetBackground.Black, WidgetBackground.Navy -> Color.White
                                    else -> Color.Black
                                },
                                selected = state.widgetBackground == background,
                                onClick = { viewModel.setWidgetBackground(background) },
                            )
                        }
                    }
                    HorizontalDivider()
                    Text(
                        text = strings.textColor,
                        style = MaterialTheme.typography.titleMedium,
                        fontWeight = FontWeight.Bold,
                    )
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.spacedBy(12.dp),
                    ) {
                        WidgetTextColor.entries.forEach { textColor ->
                            AppearanceOption(
                                modifier = Modifier.weight(1f),
                                label = strings.widgetTextColorTitle(textColor),
                                color = when (textColor) {
                                    WidgetTextColor.Auto -> Color(0xFFE5E5EA)
                                    WidgetTextColor.Black -> Color.Black
                                    WidgetTextColor.White -> Color.White
                                },
                                checkColor = when (textColor) {
                                    WidgetTextColor.Black -> Color.White
                                    else -> Color.Black
                                },
                                selected = state.widgetTextColor == textColor,
                                onClick = { viewModel.setWidgetTextColor(textColor) },
                            )
                        }
                        Spacer(Modifier.weight(1f))
                    }
                }
            }
        }

        item { SectionTitle(strings.privacy) }
        item {
            Surface(
                modifier = Modifier.fillMaxWidth(),
                shape = RoundedCornerShape(8.dp),
                color = MaterialTheme.colorScheme.surface,
            ) {
                Text(
                    text = strings.privacyBody,
                    modifier = Modifier.padding(16.dp),
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                    style = MaterialTheme.typography.bodyLarge,
                )
            }
        }
    }
}

@Composable
private fun AppearanceOption(
    label: String,
    color: Color,
    checkColor: Color,
    selected: Boolean,
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
) {
    Column(
        modifier = modifier,
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(6.dp),
    ) {
        Surface(
            modifier = Modifier
                .fillMaxWidth()
                .height(54.dp),
            onClick = onClick,
            shape = RoundedCornerShape(8.dp),
            color = color,
            border = BorderStroke(
                width = if (selected) 3.dp else 1.dp,
                color = if (selected) {
                    MaterialTheme.colorScheme.primary
                } else {
                    MaterialTheme.colorScheme.outlineVariant
                },
            ),
        ) {
            Box(contentAlignment = Alignment.Center) {
                if (selected) {
                    Text(
                        text = "\u2713",
                        color = checkColor,
                        fontSize = 28.sp,
                        fontWeight = FontWeight.Bold,
                    )
                }
            }
        }
        Text(
            text = label,
            style = MaterialTheme.typography.labelMedium,
            maxLines = 1,
        )
    }
}

@Composable
private fun PageTitle(
    text: String,
    modifier: Modifier = Modifier,
) {
    Text(
        text = text,
        modifier = modifier,
        fontSize = 42.sp,
        lineHeight = 46.sp,
        fontWeight = FontWeight.Bold,
    )
}

@Composable
private fun SectionTitle(text: String) {
    Text(
        text = text,
        style = MaterialTheme.typography.titleLarge,
        fontWeight = FontWeight.Bold,
    )
}

@Composable
private fun EmptyStateCard(
    title: String,
    description: String? = null,
    @DrawableRes icon: Int? = null,
) {
    Surface(
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(8.dp),
        color = MaterialTheme.colorScheme.surface,
    ) {
        Column(
            modifier = Modifier.padding(horizontal = 22.dp, vertical = 34.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(12.dp),
        ) {
            icon?.let {
                Icon(
                    painter = painterResource(it),
                    contentDescription = null,
                    modifier = Modifier.size(46.dp),
                    tint = MaterialTheme.colorScheme.onSurfaceVariant,
                )
            }
            Text(
                text = title,
                style = MaterialTheme.typography.titleLarge,
                fontWeight = FontWeight.Bold,
            )
            description?.let {
                Text(
                    text = it,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                    style = MaterialTheme.typography.bodyMedium,
                )
            }
        }
    }
}

private fun openCalendar(context: Context, draft: CalendarEventDraft): Boolean {
    val intent = Intent(Intent.ACTION_INSERT).apply {
        data = CalendarContract.Events.CONTENT_URI
        putExtra(CalendarContract.Events.TITLE, draft.title)
        putExtra(CalendarContract.Events.DESCRIPTION, draft.description)
        putExtra(CalendarContract.EXTRA_EVENT_BEGIN_TIME, draft.startMillis)
        putExtra(CalendarContract.EXTRA_EVENT_END_TIME, draft.endMillis)
        putExtra(CalendarContract.EXTRA_EVENT_ALL_DAY, draft.allDay)
    }
    return try {
        context.startActivity(intent)
        true
    } catch (_: ActivityNotFoundException) {
        false
    }
}

private fun openWebUrl(context: Context, rawUrl: String): Boolean {
    val safe = runCatching {
        val uri = URI(rawUrl)
        require(uri.scheme == "https" || uri.scheme == "http")
        uri
    }.getOrNull() ?: return false

    return try {
        context.startActivity(Intent(Intent.ACTION_VIEW, Uri.parse(safe.toString())))
        true
    } catch (_: ActivityNotFoundException) {
        false
    }
}
