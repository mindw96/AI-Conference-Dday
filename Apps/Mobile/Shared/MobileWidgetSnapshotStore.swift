import DdayCore
import Foundation

enum DdayAppGroup {
    static let identifier = "group.dev.mindw.Dday"
}

struct MobileWidgetDeadlineSnapshot: Codable, Equatable, Sendable {
    let title: String
    let deadlineText: String
    let deadlineLabel: String
    let localDateText: String
    let sourceDateText: String
    let deadlineDate: Date
    let updatedAt: Date

    static let placeholder = MobileWidgetDeadlineSnapshot(
        title: "AAAI",
        deadlineText: "D-62",
        deadlineLabel: "Full Paper Deadline",
        localDateText: "Jul 28 at 11:59 PM",
        sourceDateText: "2026-07-28 23:59 AoE",
        deadlineDate: Date().addingTimeInterval(62 * 24 * 60 * 60),
        updatedAt: Date()
    )

    static let empty = MobileWidgetDeadlineSnapshot(
        title: "Dday",
        deadlineText: "--",
        deadlineLabel: "Select a main D-Day",
        localDateText: "Open Dday",
        sourceDateText: "",
        deadlineDate: Date().addingTimeInterval(60 * 60),
        updatedAt: Date()
    )

    func refreshed(now: Date = Date(), calendar: Calendar = .current) -> MobileWidgetDeadlineSnapshot {
        guard !sourceDateText.isEmpty else {
            return self
        }

        let todayStart = calendar.startOfDay(for: now)
        let deadlineStart = calendar.startOfDay(for: deadlineDate)
        let days = calendar.dateComponents([.day], from: todayStart, to: deadlineStart).day ?? 0
        let remainingSeconds = deadlineDate.timeIntervalSince(now)

        let refreshedText: String
        if days == 0 && remainingSeconds > 0 {
            refreshedText = Self.countdownText(for: remainingSeconds)
        } else if days > 0 {
            refreshedText = "D-\(days)"
        } else if days == 0 {
            refreshedText = "D-Day"
        } else {
            refreshedText = "D+\(-days)"
        }

        return MobileWidgetDeadlineSnapshot(
            title: title,
            deadlineText: refreshedText,
            deadlineLabel: deadlineLabel,
            localDateText: localDateText,
            sourceDateText: sourceDateText,
            deadlineDate: deadlineDate,
            updatedAt: updatedAt
        )
    }

    private static func countdownText(for remainingSeconds: TimeInterval) -> String {
        let totalMinutes = max(1, Int(ceil(remainingSeconds / 60)))

        if totalMinutes >= 60 {
            let hours = Int(ceil(Double(totalMinutes) / 60.0))
            return "H-\(hours)"
        }

        return "M-\(totalMinutes)"
    }
}

enum MobileWidgetTimelinePlanner {
    static func entryDates(
        now: Date,
        snapshot: MobileWidgetDeadlineSnapshot,
        calendar: Calendar = .current
    ) -> [Date] {
        DeadlineTimelinePlanner.entryDates(
            now: now,
            deadline: snapshot.deadlineDate,
            shouldScheduleCountdown: !snapshot.sourceDateText.isEmpty,
            calendar: calendar
        )
    }

    static func nextDailyRefresh(
        after date: Date,
        calendar: Calendar = .current
    ) -> Date {
        DeadlineTimelinePlanner.nextDailyRefresh(
            after: date,
            calendar: calendar
        )
    }
}

enum MobileWidgetBackground: String, CaseIterable, Codable, Sendable {
    case system
    case glass
    case white
    case black
    case navy
}

enum MobileWidgetTextColor: String, CaseIterable, Codable, Sendable {
    case automatic
    case black
    case white
    case custom
}

struct MobileWidgetRGBColor: Codable, Equatable, Sendable {
    var red: Int
    var green: Int
    var blue: Int

    init(red: Int, green: Int, blue: Int) {
        self.red = Self.clamp(red)
        self.green = Self.clamp(green)
        self.blue = Self.clamp(blue)
    }

    static let defaultGlassTint = MobileWidgetRGBColor(
        red: 74,
        green: 125,
        blue: 255
    )

    static let defaultText = MobileWidgetRGBColor(
        red: 20,
        green: 29,
        blue: 48
    )

    private static func clamp(_ value: Int) -> Int {
        min(max(value, 0), 255)
    }
}

struct MobileWidgetAppearance: Codable, Equatable, Sendable {
    var background: MobileWidgetBackground
    var textColor: MobileWidgetTextColor
    var backgroundRGB: MobileWidgetRGBColor
    var textRGB: MobileWidgetRGBColor

    init(
        background: MobileWidgetBackground,
        textColor: MobileWidgetTextColor,
        backgroundRGB: MobileWidgetRGBColor = .defaultGlassTint,
        textRGB: MobileWidgetRGBColor = .defaultText
    ) {
        self.background = background
        self.textColor = textColor
        self.backgroundRGB = backgroundRGB
        self.textRGB = textRGB
    }

    private enum CodingKeys: String, CodingKey {
        case background
        case textColor
        case backgroundRGB
        case textRGB
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        background = (try? container.decode(MobileWidgetBackground.self, forKey: .background)) ?? .system
        textColor = (try? container.decode(MobileWidgetTextColor.self, forKey: .textColor)) ?? .automatic
        backgroundRGB = try container.decodeIfPresent(
            MobileWidgetRGBColor.self,
            forKey: .backgroundRGB
        ) ?? .defaultGlassTint
        textRGB = try container.decodeIfPresent(
            MobileWidgetRGBColor.self,
            forKey: .textRGB
        ) ?? .defaultText
    }

    static let standard = MobileWidgetAppearance(
        background: .glass,
        textColor: .automatic
    )
}

struct MobileWidgetSnapshotStore {
    private enum Key {
        static let selectedDeadlineSnapshot = "selectedDeadlineSnapshot"
        static let widgetAppearance = "widgetAppearance"
    }

    private let defaults: UserDefaults
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init(defaults: UserDefaults? = UserDefaults(suiteName: DdayAppGroup.identifier)) {
        self.defaults = defaults ?? .standard
    }

    func save(_ snapshot: MobileWidgetDeadlineSnapshot) {
        guard let data = try? encoder.encode(snapshot) else {
            return
        }

        defaults.set(data, forKey: Key.selectedDeadlineSnapshot)
    }

    func clear() {
        defaults.removeObject(forKey: Key.selectedDeadlineSnapshot)
    }

    func load() -> MobileWidgetDeadlineSnapshot? {
        guard let data = defaults.data(forKey: Key.selectedDeadlineSnapshot) else {
            return nil
        }

        return try? decoder.decode(MobileWidgetDeadlineSnapshot.self, from: data)
    }

    func saveAppearance(_ appearance: MobileWidgetAppearance) {
        guard let data = try? encoder.encode(appearance) else {
            return
        }

        defaults.set(data, forKey: Key.widgetAppearance)
    }

    func loadAppearance() -> MobileWidgetAppearance {
        guard let data = defaults.data(forKey: Key.widgetAppearance),
              let appearance = try? decoder.decode(MobileWidgetAppearance.self, from: data) else {
            return .standard
        }

        return appearance
    }
}
