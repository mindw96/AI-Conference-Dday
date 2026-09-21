import DdayCore
import Foundation

enum CustomDeadlineTimezone: String, CaseIterable {
    case aoe
    case local

    var deadlineTimezoneIdentifier: String {
        switch self {
        case .aoe:
            return "AoE"
        case .local:
            return TimeZone.current.identifier
        }
    }
}

enum MobileDeadlineSource: Codable, Equatable, Sendable {
    case conference(conferenceID: String, deadlineID: String)
    case custom(id: String)

    var storageKind: String {
        switch self {
        case .conference:
            return "conference"
        case .custom:
            return "custom"
        }
    }
}

struct MobileDeadlineSummary: Identifiable {
    let id: String
    let title: String
    let subtitle: String
    let deadlineLabel: String
    let sourceDateText: String
    let websiteURL: URL?
    let sourceURL: URL?
    let source: MobileDeadlineSource
    let display: DeadlineDisplay

    init(
        conference: Conference,
        deadline: ConferenceDeadline,
        display: DeadlineDisplay
    ) {
        id = "\(conference.id)-\(deadline.id)"
        title = conference.name
        subtitle = conference.fullName
        deadlineLabel = deadline.label
        sourceDateText = "\(deadline.date) \(deadline.time ?? "23:59") \(deadline.timezone)"
        websiteURL = conference.websiteUrl
        sourceURL = conference.sourceUrl
        source = .conference(conferenceID: conference.id, deadlineID: deadline.id)
        self.display = display
    }

    init(
        userDeadline: UserDeadline,
        display: DeadlineDisplay
    ) {
        id = "custom-\(userDeadline.id)"
        title = userDeadline.name
        subtitle = userDeadline.label
        deadlineLabel = userDeadline.label
        sourceDateText = "\(userDeadline.date) \(userDeadline.time ?? "23:59") \(userDeadline.timezone)"
        websiteURL = nil
        sourceURL = nil
        source = .custom(id: userDeadline.id)
        self.display = display
    }

    var localDateText: String {
        let dateText = display.deadlineDate.formatted(
            .dateTime
                .month(.abbreviated)
                .day()
                .hour()
                .minute()
        )

        return "\(dateText) \(TimeZone.current.abbreviation(for: display.deadlineDate) ?? "")"
    }
}

extension ConferenceSubcategory {
    var mobileTitle: String {
        switch self {
        case .ml:
            return "Machine Learning"
        case .cv:
            return "Computer Vision"
        case .nlp:
            return "NLP"
        case .generalAI:
            return "General AI"
        }
    }
}
