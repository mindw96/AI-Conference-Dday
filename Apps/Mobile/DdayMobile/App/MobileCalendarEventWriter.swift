import EventKit
import Foundation

struct MobileCalendarEventDraft {
    let title: String
    let startDate: Date
    let endDate: Date
    let isAllDay: Bool
    let notes: String?
    let url: URL?
}

enum MobileCalendarEventWriterError: LocalizedError {
    case accessDenied
    case noDefaultCalendar

    var errorDescription: String? {
        switch self {
        case .accessDenied:
            return "Calendar access was not granted."
        case .noDefaultCalendar:
            return "No default calendar is available."
        }
    }
}

@MainActor
final class MobileCalendarEventWriter: ObservableObject {
    private let eventStore = EKEventStore()

    func add(_ draft: MobileCalendarEventDraft) async throws {
        try await requestWriteAccessIfNeeded()

        guard let calendar = eventStore.defaultCalendarForNewEvents else {
            throw MobileCalendarEventWriterError.noDefaultCalendar
        }

        let event = EKEvent(eventStore: eventStore)
        event.title = draft.title
        event.startDate = draft.startDate
        event.endDate = draft.endDate
        event.isAllDay = draft.isAllDay
        event.notes = draft.notes
        event.url = draft.url
        event.calendar = calendar

        try eventStore.save(event, span: .thisEvent, commit: true)
    }

    private func requestWriteAccessIfNeeded() async throws {
        switch EKEventStore.authorizationStatus(for: .event) {
        case .fullAccess, .writeOnly, .authorized:
            return
        case .notDetermined:
            let granted = try await requestWriteOnlyAccess()
            guard granted else {
                throw MobileCalendarEventWriterError.accessDenied
            }
        case .denied, .restricted:
            throw MobileCalendarEventWriterError.accessDenied
        @unknown default:
            throw MobileCalendarEventWriterError.accessDenied
        }
    }

    private func requestWriteOnlyAccess() async throws -> Bool {
        try await withCheckedThrowingContinuation { continuation in
            eventStore.requestWriteOnlyAccessToEvents { granted, error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: granted)
                }
            }
        }
    }
}
