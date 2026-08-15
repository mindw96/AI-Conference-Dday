import Combine
import DdayCore
import Foundation
import WidgetKit

@MainActor
final class MobileAppModel: ObservableObject {
    private enum Key {
        static let selectedSourceKind = "mobileSelectedSourceKind"
        static let selectedConferenceID = "mobileSelectedConferenceID"
        static let selectedDeadlineID = "mobileSelectedDeadlineID"
        static let selectedCustomDeadlineID = "mobileSelectedCustomDeadlineID"
        static let selectedSubcategory = "mobileSelectedSubcategory"
        static let selectedSubcategories = "mobileSelectedSubcategories"
        static let notificationsEnabled = "mobileNotificationsEnabled"
    }

    @Published private(set) var store: ConferenceStore?
    @Published private(set) var errorMessage: String?
    @Published private(set) var selectedSubcategories: [ConferenceSubcategory]
    @Published private(set) var userDeadlines: [UserDeadline] = []
    @Published private(set) var selectedSource: MobileDeadlineSource?
    @Published private(set) var isUpdatingData = false
    @Published private(set) var updateMessage: String?
    @Published private(set) var notificationsEnabled = false
    @Published private(set) var notificationMessage: String?
    @Published private(set) var widgetAppearance: MobileWidgetAppearance = .standard
    @Published var appLanguage: AppLanguage {
        didSet {
            settingsStore.appLanguage = appLanguage
            Task {
                await refreshNotificationsIfNeeded()
            }
        }
    }

    private let loader: MobileConferenceLoader
    private let calculator = DeadlineCalculator()
    private let settingsStore: SettingsStore
    private let userDeadlineStore: UserDeadlineStore
    private let widgetSnapshotStore: MobileWidgetSnapshotStore
    private let notificationScheduler: MobileNotificationScheduler
    private let defaults: UserDefaults

    var text: MobileAppText {
        MobileAppText(language: appLanguage)
    }

    init(
        loader: MobileConferenceLoader = MobileConferenceLoader(),
        settingsStore: SettingsStore = SettingsStore(),
        userDeadlineStore: UserDeadlineStore = UserDeadlineStore(),
        widgetSnapshotStore: MobileWidgetSnapshotStore = MobileWidgetSnapshotStore(),
        notificationScheduler: MobileNotificationScheduler = MobileNotificationScheduler(),
        defaults: UserDefaults = .standard
    ) {
        self.loader = loader
        self.settingsStore = settingsStore
        self.userDeadlineStore = userDeadlineStore
        self.widgetSnapshotStore = widgetSnapshotStore
        self.notificationScheduler = notificationScheduler
        self.defaults = defaults
        appLanguage = settingsStore.appLanguage
        selectedSubcategories = Self.loadSelectedSubcategories(defaults: defaults)
        selectedSource = Self.loadSelectedSource(defaults: defaults)
        widgetAppearance = widgetSnapshotStore.loadAppearance()
        notificationsEnabled = defaults.bool(forKey: Key.notificationsEnabled)
        load()
        Task {
            await refreshNotificationsIfNeeded()
        }
    }

    func load() {
        do {
            store = try loader.loadPreferredStore()
            userDeadlines = userDeadlineStore.deadlines
            errorMessage = nil
            syncWidgetSnapshot()
        } catch {
            store = nil
            errorMessage = error.localizedDescription
        }
    }

    var featuredSummary: MobileDeadlineSummary? {
        selectedSummary
    }

    var activeConferences: [Conference] {
        store?.conferences.filter { nextSummary(for: $0) != nil } ?? []
    }

    var customDeadlineSummaries: [MobileDeadlineSummary] {
        userDeadlines
            .compactMap(summary(for:))
            .sorted { $0.display.deadlineDate < $1.display.deadlineDate }
    }

    var selectedSummary: MobileDeadlineSummary? {
        guard let selectedSource else {
            return nil
        }

        return summary(for: selectedSource)
    }

    func conferences(in subcategory: ConferenceSubcategory) -> [Conference] {
        activeConferences.filter { $0.subcategory == subcategory }
    }

    func pastConferences(in subcategory: ConferenceSubcategory) -> [Conference] {
        (store?.conferences ?? [])
            .filter { $0.subcategory == subcategory }
            .filter { nextSummary(for: $0) == nil }
    }

    var firstSelectedSubcategory: ConferenceSubcategory {
        selectedSubcategories.first ?? .ml
    }

    func summary(for conference: Conference) -> MobileDeadlineSummary? {
        nextSummary(for: conference) ?? fallbackSummary(for: conference)
    }

    func summaries(for conference: Conference) -> [MobileDeadlineSummary] {
        conference.deadlines
            .compactMap { deadline in
                summary(for: conference, deadline: deadline)
            }
            .sorted { $0.display.deadlineDate < $1.display.deadlineDate }
    }

    func upcomingSummaries(in subcategory: ConferenceSubcategory) -> [MobileDeadlineSummary] {
        store?.conferences
            .filter { $0.subcategory == subcategory }
            .flatMap(upcomingSummaries(for:))
            .sorted { $0.display.deadlineDate < $1.display.deadlineDate } ?? []
    }

    func isSubcategorySelected(_ subcategory: ConferenceSubcategory) -> Bool {
        selectedSubcategories.contains(subcategory)
    }

    func toggleSubcategory(_ subcategory: ConferenceSubcategory) {
        var updatedSubcategories = selectedSubcategories

        if updatedSubcategories.contains(subcategory) {
            guard updatedSubcategories.count > 1 else {
                return
            }

            updatedSubcategories.removeAll { $0 == subcategory }
        } else {
            updatedSubcategories.append(subcategory)
        }

        selectedSubcategories = ConferenceSubcategory.allCases.filter {
            updatedSubcategories.contains($0)
        }
        saveSelectedSubcategories()
    }

    func selectedCategoryConferences() -> [Conference] {
        selectedSubcategories.flatMap { conferences(in: $0) }
    }

    func selectedCategoryPastConferences() -> [Conference] {
        selectedSubcategories.flatMap { pastConferences(in: $0) }
    }

    private func saveSelectedSubcategories() {
        let rawValues = selectedSubcategories.map(\.rawValue)
        guard !rawValues.isEmpty else {
            return
        }

        defaults.set(rawValues, forKey: Key.selectedSubcategories)
        defaults.set(rawValues[0], forKey: Key.selectedSubcategory)
    }

    func setWidgetBackground(_ background: MobileWidgetBackground) {
        guard widgetAppearance.background != background else {
            return
        }

        widgetAppearance.background = background
        saveWidgetAppearance()
    }

    func setWidgetTextColor(_ textColor: MobileWidgetTextColor) {
        guard widgetAppearance.textColor != textColor else {
            return
        }

        widgetAppearance.textColor = textColor
        saveWidgetAppearance()
    }

    func select(_ source: MobileDeadlineSource) {
        selectedSource = source
        saveSelectedSource(source)
        syncWidgetSnapshot(reload: true)
        Task {
            await refreshNotificationsIfNeeded()
        }
    }

    func isSelected(_ source: MobileDeadlineSource) -> Bool {
        selectedSource == source
    }

    func addCustomDeadline(
        name: String,
        label: String,
        date: Date,
        timezone: CustomDeadlineTimezone
    ) {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedLabel = label.trimmingCharacters(in: .whitespacesAndNewlines)
        let deadline = UserDeadline(
            id: UUID().uuidString,
            name: trimmedName,
            label: trimmedLabel.isEmpty ? "Deadline" : trimmedLabel,
            date: Self.dateFormatter.string(from: date),
            time: Self.timeFormatter.string(from: date),
            timezone: timezone.deadlineTimezoneIdentifier,
            createdAt: Date()
        )

        userDeadlineStore.add(deadline)
        userDeadlines = userDeadlineStore.deadlines
        select(.custom(id: deadline.id))
    }

    func removeCustomDeadline(source: MobileDeadlineSource) {
        guard case .custom(let id) = source else {
            return
        }

        userDeadlineStore.remove(id: id)
        userDeadlines = userDeadlineStore.deadlines
        if selectedSource == source {
            selectedSource = nil
            clearSelectedSource()
        }
        syncWidgetSnapshot(reload: true)
        Task {
            await refreshNotificationsIfNeeded()
        }
    }

    func refreshConferenceData() async {
        isUpdatingData = true
        updateMessage = nil

        do {
            store = try await loader.fetchLatestStore()
            updateMessage = text.updateSucceeded
            syncWidgetSnapshot(reload: true)
            await refreshNotificationsIfNeeded()
        } catch {
            updateMessage = text.updateFailed(error.localizedDescription)
        }

        isUpdatingData = false
    }

    func display(for deadline: ConferenceDeadline) -> DeadlineDisplay? {
        try? calculator.display(for: deadline)
    }

    func calendarEventDraft(for summary: MobileDeadlineSummary) -> MobileCalendarEventDraft? {
        switch summary.source {
        case .conference(let conferenceID, let deadlineID):
            guard let conference = store?.conference(id: conferenceID),
                  let deadline = conference.deadline(id: deadlineID) else {
                return nil
            }

            if deadline.type == .conferenceStart || deadline.type == .conferenceEnd {
                return conferencePeriodCalendarEventDraft(for: conference)
            }

            return deadlineCalendarEventDraft(
                title: "\(conference.name) - \(deadline.label)",
                summary: summary
            )
        case .custom(let id):
            guard userDeadlines.contains(where: { $0.id == id }) else {
                return nil
            }

            return deadlineCalendarEventDraft(
                title: "\(summary.title) - \(summary.deadlineLabel)",
                summary: summary
            )
        }
    }

    func setNotificationsEnabled(_ enabled: Bool) async {
        if enabled {
            let granted = await notificationScheduler.requestAuthorization()
            guard granted else {
                notificationsEnabled = false
                defaults.set(false, forKey: Key.notificationsEnabled)
                notificationMessage = text.notificationPermissionDenied
                await notificationScheduler.clearScheduledReminders()
                return
            }

            notificationsEnabled = true
            defaults.set(true, forKey: Key.notificationsEnabled)
            await refreshNotificationsIfNeeded()
        } else {
            notificationsEnabled = false
            defaults.set(false, forKey: Key.notificationsEnabled)
            notificationMessage = text.notificationsDisabled
            await notificationScheduler.clearScheduledReminders()
        }
    }

    func refreshNotificationsIfNeeded() async {
        guard notificationsEnabled else {
            return
        }

        guard await notificationScheduler.notificationsAllowed() else {
            notificationsEnabled = false
            defaults.set(false, forKey: Key.notificationsEnabled)
            notificationMessage = text.notificationPermissionDenied
            await notificationScheduler.clearScheduledReminders()
            return
        }

        let items = notificationScheduleItems()
        guard !items.isEmpty else {
            notificationMessage = text.noNotificationsToSchedule
            await notificationScheduler.clearScheduledReminders()
            return
        }

        do {
            let count = try await notificationScheduler.schedule(
                items: items,
                language: appLanguage
            )
            notificationMessage = text.notificationsScheduled(count)
        } catch {
            notificationMessage = text.notificationSchedulingFailed(error.localizedDescription)
        }
    }

    private func deadlineCalendarEventDraft(
        title: String,
        summary: MobileDeadlineSummary
    ) -> MobileCalendarEventDraft {
        let startDate = summary.display.deadlineDate
        let endDate = startDate.addingTimeInterval(30 * 60)

        return MobileCalendarEventDraft(
            title: title,
            startDate: startDate,
            endDate: endDate,
            isAllDay: false,
            notes: calendarNotes(for: summary),
            url: summary.websiteURL
        )
    }

    private func conferencePeriodCalendarEventDraft(for conference: Conference) -> MobileCalendarEventDraft? {
        let startDeadline = conference.deadlines.first { $0.type == .conferenceStart }
        let endDeadline = conference.deadlines.first { $0.type == .conferenceEnd }
        guard let anchorDeadline = startDeadline ?? endDeadline,
              let startDate = allDayDate(for: (startDeadline ?? anchorDeadline).date),
              let endDate = allDayDate(for: (endDeadline ?? anchorDeadline).date) else {
            return nil
        }

        let calendar = Calendar(identifier: .gregorian)
        let orderedStart = min(startDate, endDate)
        let orderedEnd = max(startDate, endDate)
        guard let exclusiveEnd = calendar.date(byAdding: .day, value: 1, to: orderedEnd) else {
            return nil
        }

        let notes = [
            conference.fullName,
            conference.location,
            "\(text.conferenceWebsite): \(conference.websiteUrl.absoluteString)"
        ]
        .filter { !$0.isEmpty }
        .joined(separator: "\n")

        return MobileCalendarEventDraft(
            title: "\(conference.name) - \(text.conferencePeriod)",
            startDate: orderedStart,
            endDate: exclusiveEnd,
            isAllDay: true,
            notes: notes,
            url: conference.websiteUrl
        )
    }

    private func allDayDate(for rawDate: String) -> Date? {
        let parts = rawDate.split(separator: "-").compactMap { Int($0) }
        guard parts.count == 3 else {
            return nil
        }

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .current

        var components = DateComponents()
        components.calendar = calendar
        components.timeZone = .current
        components.year = parts[0]
        components.month = parts[1]
        components.day = parts[2]

        guard components.isValidDate(in: calendar) else {
            return nil
        }

        return components.date
    }

    private func calendarNotes(for summary: MobileDeadlineSummary) -> String {
        var lines = [
            "\(text.localTime): \(summary.localDateText)",
            "\(text.sourceTime): \(summary.sourceDateText)"
        ]

        if let websiteURL = summary.websiteURL {
            lines.append("\(text.conferenceWebsite): \(websiteURL.absoluteString)")
        }

        return lines.joined(separator: "\n")
    }

    private func nextSummary(for conference: Conference) -> MobileDeadlineSummary? {
        upcomingSummaries(for: conference)
            .min { $0.display.deadlineDate < $1.display.deadlineDate }
    }

    private func fallbackSummary(for conference: Conference) -> MobileDeadlineSummary? {
        conference.deadlines
            .compactMap { summary(for: conference, deadline: $0) }
            .max { $0.display.deadlineDate < $1.display.deadlineDate }
    }

    private func upcomingSummaries(for conference: Conference) -> [MobileDeadlineSummary] {
        conference.deadlines
            .compactMap { summary(for: conference, deadline: $0) }
            .filter { $0.display.remainingSeconds > 0 }
    }

    private func summary(
        for conference: Conference,
        deadline: ConferenceDeadline
    ) -> MobileDeadlineSummary? {
        guard let display = try? calculator.display(for: deadline) else {
            return nil
        }

        return MobileDeadlineSummary(
            conference: conference,
            deadline: deadline,
            display: display
        )
    }

    private func summary(for userDeadline: UserDeadline) -> MobileDeadlineSummary? {
        guard let display = try? calculator.display(for: userDeadline.deadline) else {
            return nil
        }

        return MobileDeadlineSummary(
            userDeadline: userDeadline,
            display: display
        )
    }

    private func summary(for source: MobileDeadlineSource) -> MobileDeadlineSummary? {
        switch source {
        case .conference(let conferenceID, let deadlineID):
            guard let conference = store?.conference(id: conferenceID),
                  let deadline = conference.deadline(id: deadlineID) else {
                return nil
            }

            return summary(for: conference, deadline: deadline)
        case .custom(let id):
            guard let userDeadline = userDeadlines.first(where: { $0.id == id }) else {
                return nil
            }

            return summary(for: userDeadline)
        }
    }

    private func saveWidgetAppearance() {
        widgetSnapshotStore.saveAppearance(widgetAppearance)
        WidgetCenter.shared.reloadAllTimelines()
    }

    private func syncWidgetSnapshot(reload: Bool = false) {
        guard let summary = selectedSummary else {
            widgetSnapshotStore.clear()
            if reload {
                WidgetCenter.shared.reloadAllTimelines()
            }
            return
        }

        widgetSnapshotStore.save(
            MobileWidgetDeadlineSnapshot(
                title: summary.title,
                deadlineText: summary.display.text,
                deadlineLabel: summary.deadlineLabel,
                localDateText: summary.localDateText,
                sourceDateText: summary.sourceDateText,
                deadlineDate: summary.display.deadlineDate,
                updatedAt: Date()
            )
        )

        if reload {
            WidgetCenter.shared.reloadAllTimelines()
        }
    }

    private func notificationScheduleItems() -> [MobileNotificationScheduleItem] {
        var seenIDs = Set<String>()
        let summaries = ([selectedSummary].compactMap { $0 } + customDeadlineSummaries)
            .filter { $0.display.remainingSeconds > 0 }

        return summaries.compactMap { summary in
            guard seenIDs.insert(summary.id).inserted else {
                return nil
            }

            return MobileNotificationScheduleItem(
                id: summary.id,
                title: summary.title,
                deadlineText: summary.display.text,
                deadlineLabel: summary.deadlineLabel,
                deadlineDate: summary.display.deadlineDate
            )
        }
    }

    private func saveSelectedSource(_ source: MobileDeadlineSource) {
        defaults.set(source.storageKind, forKey: Key.selectedSourceKind)
        switch source {
        case .conference(let conferenceID, let deadlineID):
            defaults.set(conferenceID, forKey: Key.selectedConferenceID)
            defaults.set(deadlineID, forKey: Key.selectedDeadlineID)
            defaults.removeObject(forKey: Key.selectedCustomDeadlineID)
        case .custom(let id):
            defaults.set(id, forKey: Key.selectedCustomDeadlineID)
            defaults.removeObject(forKey: Key.selectedConferenceID)
            defaults.removeObject(forKey: Key.selectedDeadlineID)
        }
    }

    private func clearSelectedSource() {
        defaults.removeObject(forKey: Key.selectedSourceKind)
        defaults.removeObject(forKey: Key.selectedConferenceID)
        defaults.removeObject(forKey: Key.selectedDeadlineID)
        defaults.removeObject(forKey: Key.selectedCustomDeadlineID)
    }

    private static func loadSelectedSource(defaults: UserDefaults) -> MobileDeadlineSource? {
        switch defaults.string(forKey: Key.selectedSourceKind) {
        case "conference":
            guard let conferenceID = defaults.string(forKey: Key.selectedConferenceID),
                  let deadlineID = defaults.string(forKey: Key.selectedDeadlineID) else {
                return nil
            }

            return .conference(conferenceID: conferenceID, deadlineID: deadlineID)
        case "custom":
            guard let id = defaults.string(forKey: Key.selectedCustomDeadlineID) else {
                return nil
            }

            return .custom(id: id)
        default:
            return nil
        }
    }

    private static func loadSelectedSubcategories(defaults: UserDefaults) -> [ConferenceSubcategory] {
        if let rawValues = defaults.stringArray(forKey: Key.selectedSubcategories) {
            let selected = ConferenceSubcategory.allCases.filter { rawValues.contains($0.rawValue) }
            if !selected.isEmpty {
                return selected
            }
        }

        if let rawValue = defaults.string(forKey: Key.selectedSubcategory),
           let subcategory = ConferenceSubcategory(rawValue: rawValue) {
            return [subcategory]
        }

        return [.ml]
    }

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "HH:mm"
        return formatter
    }()
}
