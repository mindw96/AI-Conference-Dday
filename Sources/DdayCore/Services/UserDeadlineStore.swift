import Foundation

public final class UserDeadlineStore {
    private enum Key {
        static let userDeadlines = "userDeadlines"
    }

    private let defaults: UserDefaults
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    public var deadlines: [UserDeadline] {
        get {
            guard let data = defaults.data(forKey: Key.userDeadlines),
                  let deadlines = try? decoder.decode([UserDeadline].self, from: data) else {
                return []
            }

            let normalized = deadlines.map(normalizedDeadline)
            if normalized != deadlines {
                save(normalized)
            }

            return normalized.sorted { $0.createdAt < $1.createdAt }
        }
        set {
            save(newValue)
        }
    }

    public func deadline(id: String) -> UserDeadline? {
        deadlines.first { $0.id == id }
    }

    public func add(_ deadline: UserDeadline) {
        var current = deadlines
        current.append(deadline)
        deadlines = current
    }

    public func remove(id: String) {
        deadlines = deadlines.filter { $0.id != id }
    }

    private func normalizedDeadline(_ deadline: UserDeadline) -> UserDeadline {
        guard (try? DeadlineCalculator().resolvedTimeZone(deadline.timezone)) == nil else {
            return deadline
        }

        return UserDeadline(
            id: deadline.id,
            name: deadline.name,
            label: deadline.label,
            date: deadline.date,
            time: deadline.time,
            timezone: TimeZone.current.identifier,
            createdAt: deadline.createdAt
        )
    }

    private func save(_ deadlines: [UserDeadline]) {
        guard let data = try? encoder.encode(deadlines) else {
            return
        }

        defaults.set(data, forKey: Key.userDeadlines)
    }
}
