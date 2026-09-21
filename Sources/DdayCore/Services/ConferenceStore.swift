import Foundation

public struct ConferenceStore: Sendable {
    public let conferences: [Conference]

    public init(conferences: [Conference]) {
        self.conferences = conferences
    }

    public static func load(from url: URL) throws -> ConferenceStore {
        let data = try Data(contentsOf: url)
        return try load(from: data)
    }

    public static func load(from data: Data) throws -> ConferenceStore {
        let decoder = JSONDecoder()
        let conferences = try decoder.decode([Conference].self, from: data)
        // Validate before a downloaded catalog can replace the last usable cache.
        let calculator = DeadlineCalculator()
        var conferenceIDs = Set<String>()
        for conference in conferences {
            guard !conference.id.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                  conferenceIDs.insert(conference.id).inserted else {
                throw ConferenceDataValidationError.invalidConferenceID(conference.id)
            }
            guard !conference.deadlines.isEmpty else {
                throw ConferenceDataValidationError.missingDeadlines(conference.id)
            }
            _ = try calculator.resolvedTimeZone(conference.timezone)
            var deadlineIDs = Set<String>()
            for deadline in conference.deadlines {
                guard !deadline.id.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                      deadlineIDs.insert(deadline.id).inserted else {
                    throw ConferenceDataValidationError.invalidDeadlineID(conference.id, deadline.id)
                }
                _ = try calculator.date(for: deadline)
            }
        }
        return ConferenceStore(conferences: conferences.sorted())
    }

    public func conference(id: String) -> Conference? {
        conferences.first { $0.id == id }
    }

    public func deadline(selection: DeadlineSelection) -> (Conference, ConferenceDeadline)? {
        guard let conference = conference(id: selection.conferenceID),
              let deadline = conference.deadline(id: selection.deadlineID) else {
            return nil
        }

        return (conference, deadline)
    }
}

public enum ConferenceDataValidationError: LocalizedError, Equatable {
    case invalidConferenceID(String)
    case invalidDeadlineID(String, String)
    case missingDeadlines(String)

    public var errorDescription: String? {
        switch self {
        case .invalidConferenceID(let id):
            return "Conference data contains an empty or duplicate conference ID: \(id)."
        case .invalidDeadlineID(let conferenceID, let deadlineID):
            return "Conference \(conferenceID) contains an empty or duplicate deadline ID: \(deadlineID)."
        case .missingDeadlines(let id):
            return "Conference \(id) has no deadlines."
        }
    }
}

private extension Array where Element == Conference {
    func sorted() -> [Conference] {
        sorted {
            if $0.year == $1.year {
                return $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
            }

            return $0.year < $1.year
        }
    }
}
