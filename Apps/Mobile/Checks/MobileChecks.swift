import DdayCore
import Foundation
import UserNotifications

@MainActor
private final class AsyncGate {
    private var suspended: CheckedContinuation<Void, Never>?
    private var observer: CheckedContinuation<Void, Never>?

    func suspend() async {
        await withCheckedContinuation { continuation in
            suspended = continuation
            observer?.resume()
            observer = nil
        }
    }

    func waitUntilSuspended() async {
        guard suspended == nil else { return }
        await withCheckedContinuation { observer = $0 }
    }

    func resume() {
        suspended?.resume()
        suspended = nil
    }
}

@MainActor
private final class MockNotificationCenter: MobileNotificationCenter {
    var requests: [String: UNNotificationRequest] = [:]
    var addGate: AsyncGate?
    var authorizationGate: AsyncGate?
    var permissionGate: AsyncGate?

    func requestAuthorization() async throws -> Bool {
        if let gate = authorizationGate {
            authorizationGate = nil
            await gate.suspend()
        }
        return true
    }

    func notificationsAllowed() async -> Bool {
        if let gate = permissionGate {
            permissionGate = nil
            await gate.suspend()
        }
        return true
    }

    func pendingNotificationRequests() async -> [UNNotificationRequest] {
        Array(requests.values)
    }

    func removePendingNotificationRequests(withIdentifiers identifiers: [String]) {
        for identifier in identifiers {
            requests.removeValue(forKey: identifier)
        }
    }

    func add(_ request: UNNotificationRequest) async throws {
        if let gate = addGate {
            addGate = nil
            await gate.suspend()
        }
        requests[request.identifier] = request
    }
}

private struct CheckFailure: Error, CustomStringConvertible {
    let description: String
}

@main
@MainActor
private enum MobileChecks {
    static func main() async throws {
        try await checkReminderDatesAndCopy()
        try await checkEarlyDeadline()
        try await checkSchedulingBudget()
        try await checkClearDuringAdd()
        try await checkReplacementDuringAdd()
        try await checkScheduleClearSchedule()
        try await checkDisableDuringAuthorization()
        try await checkDisableDuringPermissionCheck()
        try await checkDisabledModelClearsPendingReminders()
        try checkCustomDeadlineSurvivesCatalogFailure()
        print("PASS: 10 mobile regression checks")
    }

    private static func expect(_ value: @autoclosure () -> Bool, _ message: String) throws {
        guard value() else { throw CheckFailure(description: message) }
    }

    private static var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Seoul")!
        return calendar
    }

    private static func date(_ value: String) -> Date {
        ISO8601DateFormatter().date(from: value)!
    }

    private static func item(_ id: String = "example", deadline: Date) -> MobileNotificationScheduleItem {
        MobileNotificationScheduleItem(
            id: id,
            title: "Example",
            deadlineLabel: "Paper",
            deadlineDate: deadline
        )
    }

    private static func checkReminderDatesAndCopy() async throws {
        let center = MockNotificationCenter()
        let scheduler = MobileNotificationScheduler(center: center, calendar: calendar)
        let deadline = date("2030-09-20T18:00:00+09:00")
        let now = date("2030-08-01T12:00:00+09:00")
        let count = try await scheduler.schedule(items: [item(deadline: deadline)], language: .english, now: now)
        try expect(count == 4, "All four future reminder windows should be scheduled")
        let sevenDays = center.requests["dday-reminder-example-7d"]!
        try expect(sevenDays.content.title == "Example D-7", "Reminder title must use delivery day, not scheduling day")
        try expect(sevenDays.content.body == "Paper is in 7 days.", "English copy should match the reminder date")
        let trigger = sevenDays.trigger as! UNCalendarNotificationTrigger
        try expect(trigger.dateComponents.timeZone == calendar.timeZone, "Reminder should preserve its computed time zone")
        try expect(trigger.dateComponents.date == date("2030-09-13T09:00:00+09:00"), "Seven day reminder should fire at local 09:00")

        _ = try await scheduler.schedule(items: [item(deadline: deadline)], language: .korean, now: now)
        try expect(center.requests["dday-reminder-example-1d"]?.content.body == "Paper까지 1일 남았습니다.", "Korean copy should use delivery day")
        _ = try await scheduler.schedule(items: [item(deadline: deadline)], language: .english, now: deadline)
        try expect(center.requests.isEmpty, "Expired reminders must not be scheduled")
    }

    private static func checkEarlyDeadline() async throws {
        let center = MockNotificationCenter()
        let scheduler = MobileNotificationScheduler(center: center, calendar: calendar)
        let deadline = date("2030-09-20T00:30:00+09:00")
        _ = try await scheduler.schedule(
            items: [item(deadline: deadline)], language: .english,
            now: date("2030-09-01T00:00:00+09:00")
        )
        let reminder = center.requests["dday-reminder-example-day"]!
        let trigger = reminder.trigger as! UNCalendarNotificationTrigger
        try expect(trigger.dateComponents.date == date("2030-09-19T23:30:00+09:00"), "Early deadlines need a reminder one hour before")
        try expect(reminder.content.title == "Example D-1", "A reminder on the preceding date must not say D-Day")
        try expect(reminder.content.body == "Paper is in 1 day.", "Copy must not say today when the deadline is tomorrow")
    }

    private static func checkSchedulingBudget() async throws {
        let center = MockNotificationCenter()
        let other = UNNotificationRequest(identifier: "other-feature", content: UNMutableNotificationContent(), trigger: nil)
        center.requests[other.identifier] = other
        let scheduler = MobileNotificationScheduler(center: center, calendar: calendar)
        let items = (0..<30).reversed().map {
            item("deadline-\($0)", deadline: date("2030-09-20T18:00:00+09:00").addingTimeInterval(Double($0) * 86400))
        }
        let count = try await scheduler.schedule(items: items, language: .english, now: date("2030-08-01T00:00:00Z"))
        try expect(count == 63 && center.requests.count == 64, "The conservative budget must preserve other app requests")
        try expect(center.requests[other.identifier] != nil, "Other features' requests must remain scheduled")
        try expect(center.requests["dday-reminder-deadline-0-7d"] != nil, "Nearest reminders must take priority over input order")
        try expect(center.requests["dday-reminder-deadline-29-day"] == nil, "Farthest reminders should be deferred")
        await scheduler.clearScheduledReminders()
        try expect(center.requests.keys.sorted() == [other.identifier], "Disabling reminders must preserve other app requests")
    }

    private static func checkClearDuringAdd() async throws {
        let center = MockNotificationCenter()
        let gate = AsyncGate()
        center.addGate = gate
        let scheduler = MobileNotificationScheduler(center: center, calendar: calendar)
        let initial = Task {
            try await scheduler.schedule(items: [item(deadline: date("2030-09-20T18:00:00+09:00"))], language: .english, now: date("2030-08-01T00:00:00Z"))
        }
        await gate.waitUntilSuspended()
        Task { gate.resume() }
        await scheduler.clearScheduledReminders()
        _ = try? await initial.value
        try expect(center.requests.isEmpty, "An in-flight add must not restore reminders after disabling")
    }

    private static func checkReplacementDuringAdd() async throws {
        let center = MockNotificationCenter()
        let gate = AsyncGate()
        center.addGate = gate
        let scheduler = MobileNotificationScheduler(center: center, calendar: calendar)
        let deadline = date("2030-09-20T18:00:00+09:00")
        let initial = Task {
            try await scheduler.schedule(items: [item("old", deadline: deadline)], language: .english, now: date("2030-08-01T00:00:00Z"))
        }
        await gate.waitUntilSuspended()
        Task { gate.resume() }
        let count = try await scheduler.schedule(items: [item("new", deadline: deadline)], language: .korean, now: date("2030-08-01T00:00:00Z"))
        _ = try? await initial.value
        try expect(count == 4 && center.requests.count == 4, "Replacement must contain only its own reminders")
        try expect(center.requests.keys.allSatisfy { $0.hasPrefix("dday-reminder-new-") }, "A stale selection must not reappear")
    }

    private static func checkScheduleClearSchedule() async throws {
        let center = MockNotificationCenter()
        let gate = AsyncGate()
        center.addGate = gate
        let scheduler = MobileNotificationScheduler(center: center, calendar: calendar)
        let deadline = date("2030-09-20T18:00:00+09:00")
        let initial = Task {
            try await scheduler.schedule(items: [item("old", deadline: deadline)], language: .english, now: date("2030-08-01T00:00:00Z"))
        }
        await gate.waitUntilSuspended()
        let latest = Task {
            gate.resume()
            return try await scheduler.schedule(items: [item("new", deadline: deadline)], language: .english, now: date("2030-08-01T00:00:00Z"))
        }
        await scheduler.clearScheduledReminders()
        let count = try await latest.value
        _ = try? await initial.value
        try expect(count == 4 && center.requests.keys.allSatisfy { $0.hasPrefix("dday-reminder-new-") }, "Re-enabling after clear must retain the new schedule")
    }

    private static func withModel(
        center: MockNotificationCenter,
        body: @MainActor (MobileAppModel, UserDefaults) async throws -> Void
    ) async throws {
        let suite = "DdayMobileChecks.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        let model = MobileAppModel(
            settingsStore: SettingsStore(defaults: defaults),
            userDeadlineStore: UserDeadlineStore(defaults: defaults),
            widgetSnapshotStore: MobileWidgetSnapshotStore(defaults: defaults),
            notificationScheduler: MobileNotificationScheduler(center: center, calendar: calendar),
            defaults: defaults
        )
        try await body(model, defaults)
    }

    private static func checkDisableDuringAuthorization() async throws {
        let center = MockNotificationCenter()
        let gate = AsyncGate()
        center.authorizationGate = gate
        try await withModel(center: center) { model, defaults in
            let enable = Task { await model.setNotificationsEnabled(true) }
            await gate.waitUntilSuspended()
            await model.setNotificationsEnabled(false)
            gate.resume()
            await enable.value
            try expect(!model.notificationsEnabled && !defaults.bool(forKey: "mobileNotificationsEnabled"), "Late authorization must not reverse a newer disable")
            try expect(center.requests.isEmpty, "Late authorization must not schedule disabled reminders")
        }
    }

    private static func checkDisableDuringPermissionCheck() async throws {
        let center = MockNotificationCenter()
        let gate = AsyncGate()
        center.permissionGate = gate
        try await withModel(center: center) { model, defaults in
            let enable = Task { await model.setNotificationsEnabled(true) }
            await gate.waitUntilSuspended()
            await model.setNotificationsEnabled(false)
            gate.resume()
            await enable.value
            try expect(!model.notificationsEnabled && !defaults.bool(forKey: "mobileNotificationsEnabled"), "Late permission checks must preserve the latest preference")
            try expect(model.notificationMessage == model.text.notificationsDisabled, "Stale refresh must not replace the disabled status")
        }
    }

    private static func checkCustomDeadlineSurvivesCatalogFailure() throws {
        let suite = "DdayMobileChecks.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        let deadlineStore = UserDeadlineStore(defaults: defaults)
        deadlineStore.add(UserDeadline(id: "saved", name: "Saved deadline", label: "Paper", date: "2030-09-20", time: "18:00", timezone: "Asia/Seoul", createdAt: Date()))
        defaults.set("custom", forKey: "mobileSelectedSourceKind")
        defaults.set("saved", forKey: "mobileSelectedCustomDeadlineID")
        let widgetStore = MobileWidgetSnapshotStore(defaults: defaults)
        let model = MobileAppModel(
            settingsStore: SettingsStore(defaults: defaults),
            userDeadlineStore: deadlineStore,
            widgetSnapshotStore: widgetStore,
            notificationScheduler: MobileNotificationScheduler(center: MockNotificationCenter()),
            defaults: defaults
        )
        try expect(model.errorMessage != nil, "This test executable intentionally has no bundled conference catalog")
        try expect(model.userDeadlines.count == 1 && model.featuredSummary?.title == "Saved deadline", "Catalog failure must not hide saved custom deadlines")
        try expect(widgetStore.load()?.title == "Saved deadline", "Custom widget snapshot must survive catalog failure")
    }

    private static func checkDisabledModelClearsPendingReminders() async throws {
        let center = MockNotificationCenter()
        let request = UNNotificationRequest(identifier: "dday-reminder-stale", content: UNMutableNotificationContent(), trigger: nil)
        center.requests[request.identifier] = request
        try await withModel(center: center) { model, _ in
            await model.refreshNotificationsIfNeeded()
            try expect(center.requests.isEmpty, "Disabled reminders left by an interrupted shutdown must be removed on refresh")
        }
    }
}
