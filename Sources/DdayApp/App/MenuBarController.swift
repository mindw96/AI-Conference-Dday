import AppKit
import DdayCore
import Foundation

private let userDeadlineConferenceID = "__user_deadline__"

@MainActor
final class MenuBarController: NSObject {
    private let statusItem: NSStatusItem
    private var store: ConferenceStore
    private let calculator: DeadlineCalculator
    private let settings: SettingsStore
    private let userDeadlineStore: UserDeadlineStore
    private let conferenceDataUpdater: ConferenceDataUpdater
    private let appUpdater: AppUpdater
    private let badgeRenderer = StatusBadgeRenderer()
    private var refreshTimer: Timer?
    private var badgeAppearanceWindowController: BadgeAppearanceWindowController?
    private var lastSelectedWebsiteURL: URL?
    private var isUpdatingConferences = false

    private var text: MenuText {
        MenuText(language: settings.appLanguage)
    }

    init(
        store: ConferenceStore,
        calculator: DeadlineCalculator,
        settings: SettingsStore,
        userDeadlineStore: UserDeadlineStore,
        conferenceDataUpdater: ConferenceDataUpdater = ConferenceDataUpdater(),
        appUpdater: AppUpdater? = nil
    ) {
        self.statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        self.store = store
        self.calculator = calculator
        self.settings = settings
        self.userDeadlineStore = userDeadlineStore
        self.conferenceDataUpdater = conferenceDataUpdater
        self.appUpdater = appUpdater ?? AppUpdater()

        super.init()

        configureStatusItem()
        refresh()
        startTimer()
    }

    static func fallback(error: Error) -> MenuBarController {
        let controller = MenuBarController(
            store: ConferenceStore(conferences: []),
            calculator: DeadlineCalculator(),
            settings: SettingsStore(),
            userDeadlineStore: UserDeadlineStore(),
            conferenceDataUpdater: ConferenceDataUpdater()
        )
        controller.statusItem.button?.title = "Dday Error"
        controller.statusItem.menu = controller.errorMenu(error: error)
        return controller
    }

    private func configureStatusItem() {
        statusItem.button?.title = "Dday"
        statusItem.button?.toolTip = text.toolTip
    }

    private func startTimer() {
        let timer = Timer(
            timeInterval: 60,
            repeats: true
        ) { [weak self] _ in
            Task { @MainActor in
                self?.refresh()
            }
        }
        RunLoop.main.add(timer, forMode: .common)
        refreshTimer = timer
    }

    private func refresh() {
        guard let selection = resolvedSelection() else {
            applyMenuBarTitle("Dday")
            statusItem.menu = emptyMenu()
            return
        }

        let displayText = menuBarTitle(selection: selection)
        applyMenuBarTitle(displayText)
        statusItem.menu = menu(selected: selection)
    }

    private func applyMenuBarTitle(_ title: String) {
        guard let button = statusItem.button else {
            return
        }

        button.toolTip = title

        switch settings.menuBarVisualStyle {
        case .plain:
            statusItem.length = NSStatusItem.variableLength
            button.image = nil
            button.imagePosition = .noImage
            button.title = title
        case .badge, .glass:
            let image = badgeRenderer.image(
                for: title,
                style: settings.menuBarVisualStyle,
                glassAppearance: settings.menuBarGlassAppearance
            )
            statusItem.length = image.size.width + 4
            button.title = ""
            button.image = image
            button.imagePosition = .imageOnly
            button.imageScaling = .scaleNone
        }
    }

    private func resolvedSelection() -> SelectedDeadline? {
        if let savedSelection = settings.selectedDeadline {
            if savedSelection.conferenceID == userDeadlineConferenceID,
               let userDeadline = userDeadlineStore.deadline(id: savedSelection.deadlineID) {
                return SelectedDeadline(userDeadline: userDeadline)
            }

            if let saved = store.deadline(selection: savedSelection) {
                return SelectedDeadline(conference: saved.0, deadline: saved.1)
            }
        }

        return nextRelevantSelection()
    }

    private func nextRelevantSelection(now: Date = Date()) -> SelectedDeadline? {
        let officialCandidates = store.conferences.flatMap { conference in
            conference.deadlines.map { deadline in
                SelectedDeadline(conference: conference, deadline: deadline)
            }
        }
        let userCandidates = userDeadlineStore.deadlines.map(SelectedDeadline.init(userDeadline:))
        let candidates = officialCandidates + userCandidates

        let future = candidates
            .compactMap { selection -> (SelectedDeadline, Date)? in
                guard let date = try? calculator.date(for: selection.deadline),
                      date >= now else {
                    return nil
                }

                return (selection, date)
            }
            .sorted { $0.1 < $1.1 }

        if let next = future.first?.0 {
            settings.selectedDeadline = DeadlineSelection(
                conferenceID: next.conferenceID,
                deadlineID: next.deadline.id
            )
            return next
        }

        return candidates.first
    }

    private func menuBarTitle(selection: SelectedDeadline) -> String {
        guard let display = try? calculator.display(for: selection.deadline) else {
            return "\(selection.conferenceName) ?"
        }

        switch settings.menuBarDisplayMode {
        case .ddayOnly:
            return display.text
        case .conferenceAndDday:
            return "\(selection.conferenceName) \(display.text)"
        case .conferenceAndDate:
            return "\(selection.conferenceName) \(localShortDate(for: selection.deadline))"
        }
    }

    private func menu(selected: SelectedDeadline) -> NSMenu {
        let menu = NSMenu()

        if let display = try? calculator.display(for: selected.deadline) {
            let title = "\(selected.conferenceName) \(display.text)"
            menu.addItem(infoItem(title, emphasis: true))
            menu.addItem(infoItem(selected.deadline.label))
            menu.addItem(infoItem(sourceDateText(for: selected.deadline)))
            menu.addItem(infoItem("\(text.local): \(localDateText(for: selected.deadline))"))
        } else {
            menu.addItem(infoItem(text.unableToCalculate))
        }

        menu.addItem(.separator())
        menu.addItem(displayModeMenu())
        menu.addItem(visualStyleMenu())
        menu.addItem(languageMenu())
        menu.addItem(.separator())

        let conferenceGroups = groupedConferences()
        for item in conferenceCategoryMenuItems(conferences: conferenceGroups.current, selected: selected) {
            menu.addItem(item)
        }

        if !conferenceGroups.past.isEmpty {
            menu.addItem(pastConferencesMenu(conferences: conferenceGroups.past, selected: selected))
        }

        menu.addItem(.separator())
        let addCustomItem = NSMenuItem(title: text.addCustomDday, action: #selector(addCustomDday), keyEquivalent: "")
        addCustomItem.target = self
        menu.addItem(addCustomItem)
        if !userDeadlineStore.deadlines.isEmpty {
            menu.addItem(userDeadlineMenu(selected: selected))
        }
        if selected.isUserDefined {
            let removeItem = NSMenuItem(title: text.removeSelectedCustomDday, action: #selector(removeSelectedCustomDday), keyEquivalent: "")
            removeItem.target = self
            menu.addItem(removeItem)
        }

        menu.addItem(.separator())
        let websiteItem = NSMenuItem(title: text.openConferenceWebsite, action: #selector(openConferenceWebsite), keyEquivalent: "")
        websiteItem.target = self
        lastSelectedWebsiteURL = selected.websiteURL
        if selected.websiteURL != nil {
            menu.addItem(websiteItem)
        }

        menu.addItem(conferenceUpdateMenuItem())
        menu.addItem(appUpdater.menuItem(title: text.checkForAppUpdates))

        let refreshItem = NSMenuItem(title: text.refresh, action: #selector(refreshFromMenu), keyEquivalent: "r")
        refreshItem.target = self
        menu.addItem(refreshItem)

        menu.addItem(.separator())
        let quitItem = NSMenuItem(title: text.quit, action: #selector(quit), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)

        return menu
    }

    private func displayModeMenu() -> NSMenuItem {
        let item = NSMenuItem(title: text.menuBarDisplay, action: nil, keyEquivalent: "")
        let submenu = NSMenu()

        for mode in MenuBarDisplayMode.allCases {
            let modeItem = NSMenuItem(
                title: title(for: mode),
                action: #selector(selectDisplayMode(_:)),
                keyEquivalent: ""
            )
            modeItem.target = self
            modeItem.representedObject = mode.rawValue
            modeItem.state = settings.menuBarDisplayMode == mode ? .on : .off
            submenu.addItem(modeItem)
        }

        item.submenu = submenu
        return item
    }

    private func visualStyleMenu() -> NSMenuItem {
        let item = NSMenuItem(title: text.visualStyle, action: nil, keyEquivalent: "")
        let submenu = NSMenu()

        for style in MenuBarVisualStyle.allCases {
            let styleItem = NSMenuItem(
                title: title(for: style),
                action: #selector(selectVisualStyle(_:)),
                keyEquivalent: ""
            )
            styleItem.target = self
            styleItem.representedObject = style.rawValue
            styleItem.state = settings.menuBarVisualStyle == style ? .on : .off
            submenu.addItem(styleItem)
        }

        submenu.addItem(.separator())
        let customizeItem = NSMenuItem(
            title: text.customizeGlassColors,
            action: #selector(showBadgeAppearanceEditor),
            keyEquivalent: ""
        )
        customizeItem.target = self
        submenu.addItem(customizeItem)

        item.submenu = submenu
        return item
    }

    private func languageMenu() -> NSMenuItem {
        let item = NSMenuItem(title: text.language, action: nil, keyEquivalent: "")
        let submenu = NSMenu()

        for language in AppLanguage.allCases {
            let languageItem = NSMenuItem(
                title: title(for: language),
                action: #selector(selectLanguage(_:)),
                keyEquivalent: ""
            )
            languageItem.target = self
            languageItem.representedObject = language.rawValue
            languageItem.state = settings.appLanguage == language ? .on : .off
            submenu.addItem(languageItem)
        }

        item.submenu = submenu
        return item
    }

    private func userDeadlineMenu(selected: SelectedDeadline) -> NSMenuItem {
        let item = NSMenuItem(title: text.customDdays, action: nil, keyEquivalent: "")
        let submenu = NSMenu()

        for userDeadline in userDeadlineStore.deadlines {
            let deadlineItem = NSMenuItem(
                title: userDeadlineMenuTitle(userDeadline),
                action: #selector(selectDeadline(_:)),
                keyEquivalent: ""
            )
            deadlineItem.target = self
                deadlineItem.representedObject = DeadlineMenuSelection(
                conferenceID: userDeadlineConferenceID,
                deadlineID: userDeadline.id
            )
            deadlineItem.state = selected.conferenceID == userDeadlineConferenceID && selected.deadlineID == userDeadline.id ? .on : .off
            submenu.addItem(deadlineItem)
        }

        item.submenu = submenu
        return item
    }

    private func conferenceMenuItem(conference: Conference, selected: SelectedDeadline) -> NSMenuItem {
        let item = NSMenuItem(title: "\(conference.name) \(conference.year)", action: nil, keyEquivalent: "")
        let submenu = NSMenu()

        for deadline in conference.deadlines {
            let deadlineItem = NSMenuItem(
                title: deadlineMenuTitle(conference: conference, deadline: deadline),
                action: #selector(selectDeadline(_:)),
                keyEquivalent: ""
            )
            deadlineItem.target = self
            deadlineItem.representedObject = DeadlineMenuSelection(
                conferenceID: conference.id,
                deadlineID: deadline.id
            )
            deadlineItem.state = selected.conferenceID == conference.id && selected.deadline.id == deadline.id ? .on : .off
            submenu.addItem(deadlineItem)
        }

        item.submenu = submenu
        return item
    }

    private func pastConferencesMenu(conferences: [Conference], selected: SelectedDeadline) -> NSMenuItem {
        let item = NSMenuItem(title: text.pastConferences, action: nil, keyEquivalent: "")
        let submenu = NSMenu()

        for item in conferenceCategoryMenuItems(conferences: conferences, selected: selected) {
            submenu.addItem(item)
        }

        item.submenu = submenu
        return item
    }

    private func conferenceCategoryMenuItems(
        conferences: [Conference],
        selected: SelectedDeadline
    ) -> [NSMenuItem] {
        let grouped = Dictionary(grouping: conferences, by: \.subcategory)

        return ConferenceSubcategory.menuOrder.compactMap { subcategory in
            guard let conferences = grouped[subcategory], !conferences.isEmpty else {
                return nil
            }

            let item = NSMenuItem(title: title(for: subcategory), action: nil, keyEquivalent: "")
            let submenu = NSMenu()

            for conference in conferences.sortedForMenu() {
                submenu.addItem(conferenceMenuItem(conference: conference, selected: selected))
            }

            item.submenu = submenu
            return item
        }
    }

    private func emptyMenu() -> NSMenu {
        let menu = NSMenu()
        menu.addItem(infoItem(text.noConferences))
        menu.addItem(.separator())
        menu.addItem(conferenceUpdateMenuItem())
        menu.addItem(appUpdater.menuItem(title: text.checkForAppUpdates))
        menu.addItem(.separator())
        let quitItem = NSMenuItem(title: text.quit, action: #selector(quit), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)
        return menu
    }

    private func errorMenu(error: Error) -> NSMenu {
        let menu = NSMenu()
        menu.addItem(infoItem(text.couldNotStart, emphasis: true))
        menu.addItem(infoItem(String(describing: error)))
        menu.addItem(.separator())
        let quitItem = NSMenuItem(title: text.quit, action: #selector(quit), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)
        return menu
    }

    private func deadlineMenuTitle(
        conference: Conference,
        deadline: ConferenceDeadline
    ) -> String {
        let dday = (try? calculator.display(for: deadline).text) ?? "?"
        return "\(deadline.label) - \(dday)"
    }

    private func userDeadlineMenuTitle(_ userDeadline: UserDeadline) -> String {
        let dday = (try? calculator.display(for: userDeadline.deadline).text) ?? "?"
        return "\(userDeadline.name) - \(dday)"
    }

    private func groupedConferences(now: Date = Date()) -> (current: [Conference], past: [Conference]) {
        var current: [Conference] = []
        var past: [Conference] = []

        for conference in store.conferences {
            if isPastConference(conference, now: now) {
                past.append(conference)
            } else {
                current.append(conference)
            }
        }

        return (current, past)
    }

    private func isPastConference(_ conference: Conference, now: Date) -> Bool {
        guard !conference.deadlines.isEmpty else {
            return false
        }

        return conference.deadlines.allSatisfy { deadline in
            guard let date = try? calculator.date(for: deadline) else {
                return false
            }

            return date < now
        }
    }

    private func title(for mode: MenuBarDisplayMode) -> String {
        switch mode {
        case .ddayOnly:
            return text.ddayOnly
        case .conferenceAndDday:
            return text.conferenceAndDday
        case .conferenceAndDate:
            return text.conferenceAndDate
        }
    }

    private func sourceDateText(for deadline: ConferenceDeadline) -> String {
        "\(deadline.date) \(deadline.time ?? "23:59") \(deadline.timezone)"
    }

    private func localDateText(for deadline: ConferenceDeadline) -> String {
        guard let date = try? calculator.date(for: deadline) else {
            return sourceDateText(for: deadline)
        }

        let formatter = DateFormatter()
        formatter.locale = .current
        formatter.timeZone = .current
        formatter.dateFormat = "yyyy-MM-dd HH:mm zzz"
        return formatter.string(from: date)
    }

    private func localShortDate(for deadline: ConferenceDeadline) -> String {
        guard let date = try? calculator.date(for: deadline) else {
            return deadline.date
        }

        let formatter = DateFormatter()
        formatter.locale = .current
        formatter.timeZone = .current
        formatter.dateFormat = "MM/dd"
        return formatter.string(from: date)
    }

    private func title(for style: MenuBarVisualStyle) -> String {
        switch style {
        case .plain:
            return text.plainText
        case .badge:
            return text.lightBadge
        case .glass:
            return text.glassBadge
        }
    }

    private func title(for language: AppLanguage) -> String {
        switch language {
        case .system:
            return text.systemLanguage
        case .english:
            return "English"
        case .korean:
            return "한국어"
        }
    }

    private func title(for subcategory: ConferenceSubcategory) -> String {
        switch subcategory {
        case .ml:
            return text.machineLearning
        case .cv:
            return text.computerVision
        case .nlp:
            return text.naturalLanguageProcessing
        case .generalAI:
            return text.generalAI
        }
    }

    private func infoItem(_ title: String, emphasis: Bool = false) -> NSMenuItem {
        let item = NSMenuItem()
        item.isEnabled = false
        item.view = MenuInfoRow(title: title, emphasis: emphasis)
        return item
    }

    private func conferenceUpdateMenuItem() -> NSMenuItem {
        let title = isUpdatingConferences ? text.checkingConferenceUpdates : text.checkConferenceUpdates
        let item = NSMenuItem(title: title, action: #selector(checkConferenceListUpdates), keyEquivalent: "u")
        item.target = self
        item.isEnabled = !isUpdatingConferences
        return item
    }

    @objc private func selectDeadline(_ sender: NSMenuItem) {
        guard let selection = sender.representedObject as? DeadlineMenuSelection else {
            return
        }

        settings.selectedDeadline = DeadlineSelection(
            conferenceID: selection.conferenceID,
            deadlineID: selection.deadlineID
        )
        refresh()
    }

    @objc private func selectDisplayMode(_ sender: NSMenuItem) {
        guard let rawValue = sender.representedObject as? String,
              let mode = MenuBarDisplayMode(rawValue: rawValue) else {
            return
        }

        settings.menuBarDisplayMode = mode
        refresh()
    }

    @objc private func selectVisualStyle(_ sender: NSMenuItem) {
        guard let rawValue = sender.representedObject as? String,
              let style = MenuBarVisualStyle(rawValue: rawValue) else {
            return
        }

        settings.menuBarVisualStyle = style
        refresh()
    }

    @objc private func showBadgeAppearanceEditor() {
        badgeAppearanceWindowController?.close()

        let controller = BadgeAppearanceWindowController(
            appearance: settings.menuBarGlassAppearance,
            language: settings.appLanguage
        ) { [weak self] appearance in
            guard let self else {
                return
            }

            settings.menuBarGlassAppearance = appearance
            settings.menuBarVisualStyle = .glass
            refresh()
        }
        badgeAppearanceWindowController = controller
        controller.present()
    }

    @objc private func selectLanguage(_ sender: NSMenuItem) {
        guard let rawValue = sender.representedObject as? String,
              let language = AppLanguage(rawValue: rawValue) else {
            return
        }

        settings.appLanguage = language
        configureStatusItem()
        refresh()
    }

    @objc private func addCustomDday() {
        let fields = CustomDeadlineFields(text: text)
        let alert = NSAlert()
        alert.messageText = text.addCustomDday
        alert.informativeText = text.customDdayHelp
        alert.alertStyle = .informational
        alert.accessoryView = fields.view
        alert.addButton(withTitle: text.add)
        alert.addButton(withTitle: text.cancel)

        NSApp.activate(ignoringOtherApps: true)
        guard alert.runModal() == .alertFirstButtonReturn else {
            return
        }

        let name = fields.name
        let label = fields.label.isEmpty ? text.defaultDeadlineLabel : fields.label
        let date = fields.date
        let time = fields.time.isEmpty ? nil : fields.time
        let timezone = fields.timezone.isEmpty ? TimeZone.current.identifier : fields.timezone

        guard !name.isEmpty, !date.isEmpty else {
            showError(message: text.invalidCustomDday)
            return
        }

        let deadline = ConferenceDeadline(
            id: "deadline",
            label: label,
            date: date,
            time: time,
            timezone: timezone,
            type: .submission,
            isPrimary: true
        )

        do {
            _ = try calculator.date(for: deadline)
        } catch {
            showError(message: text.invalidCustomDday)
            return
        }

        let userDeadline = UserDeadline(
            id: UUID().uuidString,
            name: name,
            label: label,
            date: date,
            time: time,
            timezone: timezone,
            createdAt: Date()
        )
        userDeadlineStore.add(userDeadline)
        settings.selectedDeadline = DeadlineSelection(
            conferenceID: userDeadlineConferenceID,
            deadlineID: userDeadline.id
        )
        refresh()
    }

    @objc private func removeSelectedCustomDday() {
        guard let selectedDeadline = settings.selectedDeadline,
              selectedDeadline.conferenceID == userDeadlineConferenceID else {
            return
        }

        userDeadlineStore.remove(id: selectedDeadline.deadlineID)
        settings.selectedDeadline = nil
        refresh()
    }

    private func showError(message: String) {
        let alert = NSAlert()
        alert.messageText = message
        alert.alertStyle = .warning
        alert.addButton(withTitle: "OK")
        NSApp.activate(ignoringOtherApps: true)
        alert.runModal()
    }

    private func showInfo(message: String) {
        let alert = NSAlert()
        alert.messageText = message
        alert.alertStyle = .informational
        alert.addButton(withTitle: "OK")
        NSApp.activate(ignoringOtherApps: true)
        alert.runModal()
    }

    @objc private func refreshFromMenu() {
        refresh()
    }

    @objc private func checkConferenceListUpdates() {
        guard !isUpdatingConferences else {
            return
        }

        isUpdatingConferences = true
        refresh()

        Task { @MainActor in
            do {
                let updatedStore = try await conferenceDataUpdater.fetchAndCacheLatest()
                store = updatedStore

                if let selectedDeadline = settings.selectedDeadline,
                   selectedDeadline.conferenceID != userDeadlineConferenceID,
                   updatedStore.deadline(selection: selectedDeadline) == nil {
                    settings.selectedDeadline = nil
                }

                isUpdatingConferences = false
                refresh()
                showInfo(message: text.conferenceUpdatesSucceeded(count: updatedStore.conferences.count))
            } catch {
                isUpdatingConferences = false
                refresh()
                showError(message: text.conferenceUpdatesFailed(error.localizedDescription))
            }
        }
    }

    @objc private func openConferenceWebsite() {
        guard let lastSelectedWebsiteURL,
              lastSelectedWebsiteURL.isWebURL else {
            return
        }

        NSWorkspace.shared.open(lastSelectedWebsiteURL)
    }

    @objc private func quit() {
        NSApplication.shared.terminate(nil)
    }
}

private struct SelectedDeadline {
    let conferenceID: String
    let deadlineID: String
    let conferenceName: String
    let deadline: ConferenceDeadline
    let websiteURL: URL?
    let isUserDefined: Bool

    init(conference: Conference, deadline: ConferenceDeadline) {
        self.conferenceID = conference.id
        self.deadlineID = deadline.id
        self.conferenceName = conference.name
        self.deadline = deadline
        self.websiteURL = conference.websiteUrl
        self.isUserDefined = false
    }

    init(userDeadline: UserDeadline) {
        self.conferenceID = userDeadlineConferenceID
        self.deadlineID = userDeadline.id
        self.conferenceName = userDeadline.name
        self.deadline = userDeadline.deadline
        self.websiteURL = nil
        self.isUserDefined = true
    }
}

private final class DeadlineMenuSelection: NSObject {
    let conferenceID: String
    let deadlineID: String

    init(conferenceID: String, deadlineID: String) {
        self.conferenceID = conferenceID
        self.deadlineID = deadlineID
    }
}

private extension ConferenceSubcategory {
    static let menuOrder: [ConferenceSubcategory] = Self.allCases
}

private extension Array where Element == Conference {
    func sortedForMenu() -> [Conference] {
        sorted {
            if $0.year == $1.year {
                return $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
            }

            return $0.year < $1.year
        }
    }
}

private final class MenuInfoRow: NSView {
    private let horizontalPadding: CGFloat = 14
    private let rowHeight: CGFloat = 22
    private let emphasis: Bool
    private let label: NSTextField

    init(title: String, emphasis: Bool) {
        self.emphasis = emphasis
        let font = emphasis
            ? NSFont.systemFont(ofSize: NSFont.systemFontSize, weight: .semibold)
            : NSFont.systemFont(ofSize: NSFont.systemFontSize)
        let textSize = title.size(withAttributes: [.font: font])
        let width = max(240, ceil(textSize.width) + horizontalPadding * 2)
        self.label = NSTextField(labelWithString: title)

        super.init(frame: NSRect(x: 0, y: 0, width: width, height: rowHeight))

        label.font = font
        label.lineBreakMode = .byTruncatingTail
        label.frame = NSRect(
            x: horizontalPadding,
            y: 2,
            width: width - horizontalPadding * 2,
            height: rowHeight - 4
        )
        addSubview(label)
        updateTextColor()
    }

    override func viewDidChangeEffectiveAppearance() {
        super.viewDidChangeEffectiveAppearance()
        updateTextColor()
    }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        updateTextColor()
    }

    private func updateTextColor() {
        let isDark = effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
        if isDark {
            label.textColor = emphasis
                ? NSColor(calibratedWhite: 0.96, alpha: 1)
                : NSColor(calibratedWhite: 0.86, alpha: 1)
        } else {
            label.textColor = emphasis
                ? .labelColor
                : NSColor.labelColor.withAlphaComponent(0.88)
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        nil
    }
}

@MainActor
private final class CustomDeadlineFields {
    let view: NSView

    private let nameField = NSTextField()
    private let labelField = NSTextField()
    private let dateField = NSTextField()
    private let timeField = NSTextField()
    private let timezoneField = NSTextField()

    var name: String {
        trimmed(nameField.stringValue)
    }

    var label: String {
        trimmed(labelField.stringValue)
    }

    var date: String {
        trimmed(dateField.stringValue)
    }

    var time: String {
        trimmed(timeField.stringValue)
    }

    var timezone: String {
        trimmed(timezoneField.stringValue)
    }

    init(text: MenuText) {
        let stack = NSStackView()
        stack.orientation = .vertical
        stack.spacing = 8
        stack.alignment = .leading
        stack.translatesAutoresizingMaskIntoConstraints = false

        nameField.placeholderString = text.customNamePlaceholder
        labelField.placeholderString = text.customLabelPlaceholder
        dateField.placeholderString = "2026-07-28"
        timeField.placeholderString = "23:59"
        timezoneField.placeholderString = TimeZone.current.identifier
        timezoneField.stringValue = TimeZone.current.identifier

        stack.addArrangedSubview(Self.row(label: text.customName, field: nameField))
        stack.addArrangedSubview(Self.row(label: text.customLabel, field: labelField))
        stack.addArrangedSubview(Self.row(label: text.customDate, field: dateField))
        stack.addArrangedSubview(Self.row(label: text.customTime, field: timeField))
        stack.addArrangedSubview(Self.row(label: text.customTimezone, field: timezoneField))

        let container = NSView(frame: NSRect(x: 0, y: 0, width: 360, height: 160))
        container.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            stack.topAnchor.constraint(equalTo: container.topAnchor),
            stack.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])
        view = container
    }

    private static func row(label: String, field: NSTextField) -> NSView {
        let row = NSStackView()
        row.orientation = .horizontal
        row.spacing = 8
        row.alignment = .centerY

        let labelView = NSTextField(labelWithString: label)
        labelView.frame.size.width = 92
        labelView.widthAnchor.constraint(equalToConstant: 92).isActive = true
        field.widthAnchor.constraint(equalToConstant: 240).isActive = true

        row.addArrangedSubview(labelView)
        row.addArrangedSubview(field)
        return row
    }

    private func trimmed(_ value: String) -> String {
        value.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

private struct MenuText {
    private let usesKorean: Bool

    init(language: AppLanguage) {
        switch language {
        case .system:
            usesKorean = Locale.preferredLanguages.first?.hasPrefix("ko") == true
        case .english:
            usesKorean = false
        case .korean:
            usesKorean = true
        }
    }

    var toolTip: String {
        usesKorean ? "학회 마감일 추적기" : "Conference deadline tracker"
    }

    var local: String {
        usesKorean ? "내 시간" : "Local"
    }

    var unableToCalculate: String {
        usesKorean ? "선택한 마감일을 계산할 수 없습니다" : "Unable to calculate selected deadline"
    }

    var openConferenceWebsite: String {
        usesKorean ? "학회 홈페이지 열기" : "Open Conference Website"
    }

    var checkConferenceUpdates: String {
        usesKorean ? "학회 목록 업데이트 확인" : "Check Conference List Updates"
    }

    var checkForAppUpdates: String {
        usesKorean ? "Dday 업데이트 확인..." : "Check for Dday Updates..."
    }

    var checkingConferenceUpdates: String {
        usesKorean ? "학회 목록 업데이트 확인 중..." : "Checking Conference List Updates..."
    }

    func conferenceUpdatesSucceeded(count: Int) -> String {
        usesKorean
            ? "학회 목록을 업데이트했습니다. 현재 \(count)개 학회가 들어 있습니다."
            : "Conference list updated. \(count) conferences are now available."
    }

    func conferenceUpdatesFailed(_ reason: String) -> String {
        usesKorean
            ? "학회 목록을 업데이트하지 못했습니다.\n\(reason)"
            : "Could not update the conference list.\n\(reason)"
    }

    var refresh: String {
        usesKorean ? "새로고침" : "Refresh"
    }

    var quit: String {
        usesKorean ? "Dday 종료" : "Quit Dday"
    }

    var menuBarDisplay: String {
        usesKorean ? "메뉴바 표시" : "Menu Bar Display"
    }

    var visualStyle: String {
        usesKorean ? "디자인" : "Visual Style"
    }

    var language: String {
        usesKorean ? "언어" : "Language"
    }

    var systemLanguage: String {
        usesKorean ? "시스템 설정" : "System"
    }

    var noConferences: String {
        usesKorean ? "학회 데이터가 없습니다" : "No conferences available"
    }

    var pastConferences: String {
        usesKorean ? "지난 학회" : "Past Conferences"
    }

    var machineLearning: String {
        "Machine Learning"
    }

    var computerVision: String {
        "Computer Vision"
    }

    var naturalLanguageProcessing: String {
        "NLP"
    }

    var generalAI: String {
        usesKorean ? "General AI" : "General AI"
    }

    var couldNotStart: String {
        usesKorean ? "Dday를 시작할 수 없습니다" : "Dday could not start"
    }

    var ddayOnly: String {
        usesKorean ? "D-Day만" : "D-Day Only"
    }

    var conferenceAndDday: String {
        usesKorean ? "학회명 + D-Day" : "Conference + D-Day"
    }

    var conferenceAndDate: String {
        usesKorean ? "학회명 + 날짜" : "Conference + Date"
    }

    var plainText: String {
        usesKorean ? "기본 텍스트" : "Plain Text"
    }

    var lightBadge: String {
        usesKorean ? "밝은 배지" : "Light Badge"
    }

    var glassBadge: String {
        "Glass Badge"
    }

    var customizeGlassColors: String {
        usesKorean ? "Glass 색상 사용자화..." : "Customize Glass Colors..."
    }

    var addCustomDday: String {
        usesKorean ? "사용자 D-Day 추가..." : "Add Custom D-Day..."
    }

    var customDdays: String {
        usesKorean ? "사용자 D-Day" : "Custom D-Days"
    }

    var removeSelectedCustomDday: String {
        usesKorean ? "선택한 사용자 D-Day 삭제" : "Remove Selected Custom D-Day"
    }

    var customDdayHelp: String {
        usesKorean
            ? "목록에 없는 학회나 개인 마감일을 직접 추가합니다. 날짜는 yyyy-MM-dd 형식으로 입력해 주세요."
            : "Add a conference or personal deadline that is not in the built-in list. Use yyyy-MM-dd for the date."
    }

    var add: String {
        usesKorean ? "추가" : "Add"
    }

    var cancel: String {
        usesKorean ? "취소" : "Cancel"
    }

    var invalidCustomDday: String {
        usesKorean
            ? "입력값을 확인해 주세요. 날짜는 yyyy-MM-dd, 시간은 HH:mm 형식이어야 합니다."
            : "Please check the values. Date must use yyyy-MM-dd and time must use HH:mm."
    }

    var defaultDeadlineLabel: String {
        usesKorean ? "마감일" : "Deadline"
    }

    var customName: String {
        usesKorean ? "이름" : "Name"
    }

    var customLabel: String {
        usesKorean ? "마감 이름" : "Label"
    }

    var customDate: String {
        usesKorean ? "날짜" : "Date"
    }

    var customTime: String {
        usesKorean ? "시간" : "Time"
    }

    var customTimezone: String {
        usesKorean ? "시간대" : "Timezone"
    }

    var customNamePlaceholder: String {
        usesKorean ? "예: UIST" : "e.g. UIST"
    }

    var customLabelPlaceholder: String {
        usesKorean ? "예: Full Paper" : "e.g. Full Paper"
    }
}
