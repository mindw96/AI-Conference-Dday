import Foundation

public struct DeadlineDisplay: Equatable, Sendable {
    public let text: String
    public let days: Int
    public let remainingSeconds: TimeInterval
    public let deadlineDate: Date

    public init(
        text: String,
        days: Int,
        remainingSeconds: TimeInterval,
        deadlineDate: Date
    ) {
        self.text = text
        self.days = days
        self.remainingSeconds = remainingSeconds
        self.deadlineDate = deadlineDate
    }
}

public enum DeadlineCalculationError: Error, Equatable, Sendable {
    case invalidDate(String)
    case invalidTime(String)
    case invalidTimeZone(String)
}

public struct DeadlineCalculator: Sendable {
    public init() {}

    public func display(
        for deadline: ConferenceDeadline,
        now: Date = Date(),
        displayTimeZone: TimeZone = .current
    ) throws -> DeadlineDisplay {
        let deadlineDate = try date(for: deadline)

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = displayTimeZone

        let todayStart = calendar.startOfDay(for: now)
        let deadlineStart = calendar.startOfDay(for: deadlineDate)
        let days = calendar.dateComponents([.day], from: todayStart, to: deadlineStart).day ?? 0
        let remainingSeconds = deadlineDate.timeIntervalSince(now)

        let text: String
        if days == 0 && remainingSeconds > 0 {
            text = countdownText(for: remainingSeconds)
        } else if days > 0 {
            text = "D-\(days)"
        } else if days == 0 {
            text = "D-Day"
        } else {
            text = "D+\(-days)"
        }

        return DeadlineDisplay(
            text: text,
            days: days,
            remainingSeconds: remainingSeconds,
            deadlineDate: deadlineDate
        )
    }

    public func date(for deadline: ConferenceDeadline) throws -> Date {
        try date(for: deadline, timezone: resolvedTimeZone(deadline.timezone))
    }

    public func resolvedTimeZone(_ identifier: String) throws -> TimeZone {
        if identifier.caseInsensitiveCompare("AoE") == .orderedSame {
            return TimeZone(secondsFromGMT: -12 * 60 * 60)!
        }

        guard let timeZone = TimeZone(identifier: identifier) else {
            throw DeadlineCalculationError.invalidTimeZone(identifier)
        }

        return timeZone
    }

    private func date(for deadline: ConferenceDeadline, timezone: TimeZone) throws -> Date {
        let dateParts = deadline.date.split(separator: "-").compactMap { Int($0) }
        guard dateParts.count == 3 else {
            throw DeadlineCalculationError.invalidDate(deadline.date)
        }

        var hour = 23
        var minute = 59

        if let time = deadline.time {
            let timeParts = time.split(separator: ":").compactMap { Int($0) }
            guard timeParts.count == 2 else {
                throw DeadlineCalculationError.invalidTime(time)
            }
            hour = timeParts[0]
            minute = timeParts[1]
        }

        guard (0...23).contains(hour), (0...59).contains(minute) else {
            throw DeadlineCalculationError.invalidTime(deadline.time ?? "\(hour):\(minute)")
        }

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timezone

        var components = DateComponents()
        components.calendar = calendar
        components.timeZone = timezone
        components.year = dateParts[0]
        components.month = dateParts[1]
        components.day = dateParts[2]
        components.hour = hour
        components.minute = minute
        components.second = 0

        guard components.isValidDate(in: calendar),
              let date = components.date else {
            throw DeadlineCalculationError.invalidDate(deadline.date)
        }

        return date
    }

    private func countdownText(for remainingSeconds: TimeInterval) -> String {
        let totalMinutes = max(1, Int(ceil(remainingSeconds / 60)))

        if totalMinutes >= 60 {
            let hours = Int(ceil(Double(totalMinutes) / 60.0))
            return "H-\(hours)"
        }

        return "M-\(totalMinutes)"
    }
}
