import Foundation

public enum DeadlineTimelinePlanner {
    public static let maximumEntryCount = 90

    public static func entryDates(
        now: Date,
        deadline: Date,
        shouldScheduleCountdown: Bool,
        calendar: Calendar = .current
    ) -> [Date] {
        let todayStart = calendar.startOfDay(for: now)
        let deadlineDayStart = calendar.startOfDay(for: deadline)
        let dayDistance = calendar.dateComponents(
            [.day],
            from: todayStart,
            to: deadlineDayStart
        ).day

        guard shouldScheduleCountdown,
              deadline > now,
              dayDistance == 0 || dayDistance == 1 else {
            return [now]
        }

        var dates = [now]
        var cursor = max(now, deadlineDayStart)
        if cursor > now.addingTimeInterval(0.5) {
            dates.append(cursor)
        }

        // Reserve the final slot for the exact deadline.
        while cursor < deadline, dates.count < maximumEntryCount - 1 {
            let remainingSeconds = deadline.timeIntervalSince(cursor)
            let totalMinutes = max(1, Int(ceil(remainingSeconds / 60)))
            let nextDate: Date

            if totalMinutes >= 60 {
                let hours = Int(ceil(Double(totalMinutes) / 60.0))
                let nextRemainingMinutes = hours == 1 ? 59 : (hours - 1) * 60
                nextDate = deadline.addingTimeInterval(-Double(nextRemainingMinutes * 60))
            } else {
                nextDate = deadline.addingTimeInterval(-Double((totalMinutes - 1) * 60))
            }

            guard nextDate > cursor.addingTimeInterval(0.5) else {
                break
            }

            dates.append(min(nextDate, deadline))
            cursor = nextDate
        }

        if dates.last != deadline {
            if dates.count == maximumEntryCount {
                dates[dates.index(before: dates.endIndex)] = deadline
            } else {
                dates.append(deadline)
            }
        }

        return dates
    }

    public static func nextDailyRefresh(
        after date: Date,
        calendar: Calendar = .current
    ) -> Date {
        calendar.nextDate(
            after: date,
            matching: DateComponents(hour: 0, minute: 5),
            matchingPolicy: .nextTime
        ) ?? date.addingTimeInterval(24 * 60 * 60)
    }
}
