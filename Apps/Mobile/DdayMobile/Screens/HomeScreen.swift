import SwiftUI

struct HomeScreen: View {
    @EnvironmentObject private var model: MobileAppModel
    @StateObject private var calendarWriter = MobileCalendarEventWriter()
    @State private var calendarAlert: CalendarAddAlert?

    var body: some View {
        NavigationStack {
            TimelineView(.periodic(from: .now, by: 60)) { _ in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 24) {
                        if let errorMessage = model.errorMessage {
                            ContentUnavailableView(
                                model.text.conferenceDataUnavailable,
                                systemImage: "exclamationmark.triangle",
                                description: Text(errorMessage)
                            )
                        } else if let summary = model.featuredSummary {
                            DeadlineHero(summary: summary)
                        } else {
                            ContentUnavailableView(
                                model.text.noMainDday,
                                systemImage: "pin",
                                description: Text(model.text.noMainDdayDescription)
                            )
                        }

                        if model.errorMessage == nil {
                            UpcomingDeadlinesSection(onAddToCalendar: addToCalendar)
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle(model.text.homeTitle)
            .alert(item: $calendarAlert) { alert in
                Alert(
                    title: Text(alert.title),
                    message: Text(alert.message),
                    dismissButton: .default(Text(model.text.ok))
                )
            }
        }
    }

    private func addToCalendar(_ summary: MobileDeadlineSummary) {
        guard let draft = model.calendarEventDraft(for: summary) else {
            calendarAlert = CalendarAddAlert(
                title: model.text.calendarEventAddFailed,
                message: model.text.conferenceDataUnavailable
            )
            return
        }

        Task { @MainActor in
            do {
                try await calendarWriter.add(draft)
                calendarAlert = CalendarAddAlert(
                    title: model.text.calendarEventAdded,
                    message: draft.title
                )
            } catch MobileCalendarEventWriterError.accessDenied {
                calendarAlert = CalendarAddAlert(
                    title: model.text.calendarEventAddFailed,
                    message: model.text.calendarAccessDenied
                )
            } catch {
                calendarAlert = CalendarAddAlert(
                    title: model.text.calendarEventAddFailed,
                    message: error.localizedDescription
                )
            }
        }
    }
}

private struct CalendarAddAlert: Identifiable {
    let id = UUID()
    let title: String
    let message: String
}

private struct DeadlineHero: View {
    @EnvironmentObject private var model: MobileAppModel
    let summary: MobileDeadlineSummary

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(model.text.mainDeadline)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)

            Text(summary.title)
                .font(.title)
                .fontWeight(.bold)

            DeadlineBadgeView(text: summary.display.text)

            VStack(alignment: .leading, spacing: 6) {
                Text(summary.deadlineLabel)
                    .font(.headline)
                Text(summary.localDateText)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

private struct UpcomingDeadlinesSection: View {
    @EnvironmentObject private var model: MobileAppModel
    @State private var collapsedGroupIDs: Set<String> = []
    let onAddToCalendar: (MobileDeadlineSummary) -> Void

    var body: some View {
        let groups = deadlineGroups

        if groups.isEmpty {
            ContentUnavailableView(
                model.text.noUpcomingDeadlines,
                systemImage: "calendar.badge.exclamationmark"
            )
        } else {
            VStack(alignment: .leading, spacing: 12) {
                Text(model.text.upcoming)
                    .font(.headline)

                ForEach(groups) { group in
                    UpcomingDeadlineGroup(
                        id: group.id,
                        title: group.title,
                        summaries: group.summaries,
                        collapsedGroupIDs: $collapsedGroupIDs,
                        onAddToCalendar: onAddToCalendar
                    )
                }
            }
        }
    }

    private var deadlineGroups: [UpcomingDeadlineGroupData] {
        var groups: [UpcomingDeadlineGroupData] = []
        let customSummaries = model.customDeadlineSummaries
            .filter { $0.display.remainingSeconds > 0 }
        if !customSummaries.isEmpty {
            groups.append(
                UpcomingDeadlineGroupData(
                    id: "custom",
                    title: model.text.customTitle,
                    summaries: customSummaries
                )
            )
        }

        for subcategory in model.selectedSubcategories {
            let summaries = model.upcomingSummaries(in: subcategory)
            if !summaries.isEmpty {
                groups.append(
                    UpcomingDeadlineGroupData(
                        id: subcategory.rawValue,
                        title: model.text.subcategoryTitle(subcategory),
                        summaries: summaries
                    )
                )
            }
        }

        return groups
    }
}

private struct UpcomingDeadlineGroupData: Identifiable {
    let id: String
    let title: String
    let summaries: [MobileDeadlineSummary]
}

private struct UpcomingDeadlineGroup: View {
    let id: String
    let title: String
    let summaries: [MobileDeadlineSummary]
    @Binding var collapsedGroupIDs: Set<String>
    let onAddToCalendar: (MobileDeadlineSummary) -> Void

    private var isExpanded: Bool {
        !collapsedGroupIDs.contains(id)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button {
                withAnimation(.snappy) {
                    if isExpanded {
                        collapsedGroupIDs.insert(id)
                    } else {
                        collapsedGroupIDs.remove(id)
                    }
                }
            } label: {
                HStack(spacing: 8) {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.semibold)

                    Text("\(summaries.count)")
                        .font(.caption2.monospacedDigit())
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(Color(.tertiarySystemFill))
                        .clipShape(Capsule())

                    Spacer()

                    Image(systemName: "chevron.down")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .rotationEffect(.degrees(isExpanded ? 0 : -90))
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)

            if isExpanded {
                ForEach(summaries) { summary in
                    UpcomingDeadlineRow(
                        summary: summary,
                        onAddToCalendar: onAddToCalendar
                    )
                }
            }
        }
    }
}

private struct UpcomingDeadlineRow: View {
    @EnvironmentObject private var model: MobileAppModel
    let summary: MobileDeadlineSummary
    let onAddToCalendar: (MobileDeadlineSummary) -> Void

    var body: some View {
        HStack(spacing: 10) {
            Button {
                model.select(summary.source)
            } label: {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(summary.title)
                            .fontWeight(.semibold)
                        Text(summary.deadlineLabel)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Text(summary.display.text)
                        .font(.headline.monospacedDigit())
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Button {
                onAddToCalendar(summary)
            } label: {
                Image(systemName: "calendar.badge.plus")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .frame(width: 34, height: 34)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(model.text.addToCalendar)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

#Preview {
    HomeScreen()
        .environmentObject(MobileAppModel())
}
