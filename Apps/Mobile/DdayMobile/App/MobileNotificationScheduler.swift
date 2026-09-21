import DdayCore
import Foundation
import UserNotifications

struct MobileNotificationScheduleItem: Sendable {
    let id: String
    let title: String
    let deadlineLabel: String
    let deadlineDate: Date
}

@MainActor
protocol MobileNotificationCenter {
    func requestAuthorization() async throws -> Bool
    func notificationsAllowed() async -> Bool
    func pendingNotificationRequests() async -> [UNNotificationRequest]
    func removePendingNotificationRequests(withIdentifiers identifiers: [String])
    func add(_ request: UNNotificationRequest) async throws
}

@MainActor
private struct SystemMobileNotificationCenter: MobileNotificationCenter {
    private let center = UNUserNotificationCenter.current()

    func requestAuthorization() async throws -> Bool {
        try await center.requestAuthorization(options: [.alert, .sound, .badge])
    }

    func notificationsAllowed() async -> Bool {
        let settings = await center.notificationSettings()
        return settings.authorizationStatus == .authorized || settings.authorizationStatus == .provisional
    }

    func pendingNotificationRequests() async -> [UNNotificationRequest] {
        await center.pendingNotificationRequests()
    }

    func removePendingNotificationRequests(withIdentifiers identifiers: [String]) {
        center.removePendingNotificationRequests(withIdentifiers: identifiers)
    }

    func add(_ request: UNNotificationRequest) async throws {
        try await center.add(request)
    }
}

@MainActor
final class MobileNotificationScheduler {
    private enum ReminderWindow: Int, CaseIterable {
        case sevenDays = 7
        case threeDays = 3
        case oneDay = 1
        case deadlineDay = 0

        var identifier: String {
            switch self {
            case .sevenDays:
                return "7d"
            case .threeDays:
                return "3d"
            case .oneDay:
                return "1d"
            case .deadlineDay:
                return "day"
            }
        }
    }

    private let center: any MobileNotificationCenter
    private let calendar: Calendar
    private var operation: Task<Void, Never>?
    private var generation = 0

    init(
        center: (any MobileNotificationCenter)? = nil,
        calendar: Calendar = .autoupdatingCurrent
    ) {
        self.center = center ?? SystemMobileNotificationCenter()
        self.calendar = calendar
    }

    func requestAuthorization() async -> Bool {
        do {
            return try await center.requestAuthorization()
        } catch {
            return false
        }
    }

    func notificationsAllowed() async -> Bool {
        await center.notificationsAllowed()
    }

    func clearScheduledReminders() async {
        generation += 1
        let expectedGeneration = generation
        let previousOperation = operation
        let clearing = Task { @MainActor in
            // Wait for an in-flight add to finish before removing its request.
            await previousOperation?.value
            let pendingRequests = await center.pendingNotificationRequests()
            center.removePendingNotificationRequests(withIdentifiers: reminderIDs(in: pendingRequests))
        }
        operation = clearing
        await clearing.value
        if generation == expectedGeneration {
            operation = nil
        }
    }

    func schedule(
        items: [MobileNotificationScheduleItem],
        language: AppLanguage,
        now: Date = Date()
    ) async throws -> Int {
        generation += 1
        let expectedGeneration = generation
        let previousOperation = operation
        let scheduling = Task { @MainActor in
            await previousOperation?.value
            try checkGeneration(expectedGeneration)

            let pendingRequests = await center.pendingNotificationRequests()
            try checkGeneration(expectedGeneration)
            let identifiers = reminderIDs(in: pendingRequests)
            center.removePendingNotificationRequests(withIdentifiers: identifiers)

            // Use a conservative 64-request budget, preserving other app notifications.
            let availableSlots = max(0, 64 - (pendingRequests.count - identifiers.count))
            let requests = requests(items: items, language: language, now: now)
                .prefix(availableSlots)

            for request in requests {
                try checkGeneration(expectedGeneration)
                try await center.add(request)
            }
            try checkGeneration(expectedGeneration)
            return requests.count
        }
        operation = Task { _ = try? await scheduling.value }
        defer {
            if generation == expectedGeneration {
                operation = nil
            }
        }
        return try await scheduling.value
    }

    private func checkGeneration(_ expectedGeneration: Int) throws {
        guard generation == expectedGeneration else {
            throw CancellationError()
        }
    }

    private func reminderIDs(in requests: [UNNotificationRequest]) -> [String] {
        requests.map(\.identifier).filter { $0.hasPrefix("dday-reminder-") }
    }

    private func requests(
        items: [MobileNotificationScheduleItem],
        language: AppLanguage,
        now: Date
    ) -> [UNNotificationRequest] {
        var planned: [(date: Date, request: UNNotificationRequest)] = []
        for item in items {
            for window in ReminderWindow.allCases {
                guard let fireDate = reminderDate(for: item.deadlineDate, window: window),
                      fireDate > now else {
                    continue
                }

                let days = calendar.dateComponents(
                    [.day],
                    from: calendar.startOfDay(for: fireDate),
                    to: calendar.startOfDay(for: item.deadlineDate)
                ).day ?? 0
                let content = UNMutableNotificationContent()
                let deadlineText = days > 0 ? "D-\(days)" : "D-Day"
                content.title = "\(item.title) \(deadlineText)"
                content.body = notificationBody(for: item, days: days, language: language)
                content.sound = .default
                content.userInfo = [
                    "deadlineID": item.id,
                    "deadlineDate": item.deadlineDate.timeIntervalSince1970
                ]

                let components = calendar.dateComponents(
                    [.calendar, .timeZone, .year, .month, .day, .hour, .minute, .second],
                    from: fireDate
                )
                let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
                let request = UNNotificationRequest(
                    identifier: "dday-reminder-\(item.id)-\(window.identifier)",
                    content: content,
                    trigger: trigger
                )

                planned.append((fireDate, request))
            }
        }

        return planned.sorted {
            if $0.date == $1.date {
                return $0.request.identifier < $1.request.identifier
            }
            return $0.date < $1.date
        }.map(\.request)
    }

    private func reminderDate(for deadlineDate: Date, window: ReminderWindow) -> Date? {
        let deadlineDay = calendar.startOfDay(for: deadlineDate)
        guard let targetDay = calendar.date(byAdding: .day, value: -window.rawValue, to: deadlineDay) else {
            return nil
        }

        var components = calendar.dateComponents([.year, .month, .day], from: targetDay)
        components.hour = 9
        components.minute = 0

        guard let nineAM = calendar.date(from: components) else {
            return nil
        }

        if window == .deadlineDay && nineAM >= deadlineDate {
            return calendar.date(byAdding: .hour, value: -1, to: deadlineDate)
        }

        return nineAM
    }

    private func notificationBody(
        for item: MobileNotificationScheduleItem,
        days: Int,
        language: AppLanguage
    ) -> String {
        let korean = isKorean(language)

        if days > 0 {
            if korean {
                return "\(item.deadlineLabel)까지 \(days)일 남았습니다."
            }

            return "\(item.deadlineLabel) is in \(days) day\(days == 1 ? "" : "s")."
        } else {
            if korean {
                return "\(item.deadlineLabel) 당일입니다."
            }

            return "\(item.deadlineLabel) is today."
        }
    }

    private func isKorean(_ language: AppLanguage) -> Bool {
        switch language {
        case .korean:
            return true
        case .english:
            return false
        case .system:
            return Locale.preferredLanguages.first?.hasPrefix("ko") ?? false
        }
    }
}
