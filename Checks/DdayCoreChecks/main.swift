import DdayCore
import Foundation

enum DdayCoreChecks {
    static func run() throws {
        try checkFutureDeadlineUsesDMinusFormat()
        try checkSameLocalDeadlineDayUsesDDayFormat()
        try checkSameLocalDeadlineDayUsesHourCountdown()
        try checkSameLocalDeadlineDayUsesMinuteCountdown()
        try checkPastDeadlineUsesDPlusFormat()
        try checkInvalidDeadlineDateIsRejected()
        try checkInvalidDeadlineTimeIsRejected()
        try checkInvalidDeadlineTimezoneIsRejected()
        try checkInvalidStoredUserDeadlineTimezoneIsMigrated()
        try checkMenuBarGlassAppearancePersists()
        try checkAoEMapsToUTCMinusTwelve()
        try checkAoEDeadlineUsesLocalDisplayTimezone()
        try checkWidgetTimelineSkipsDistantAndEmptyDeadlines()
        try checkWidgetTimelineSchedulesVisibleTransitions()
        try checkWidgetTimelineEntryCountIsBounded()
        try checkWidgetTimelineSchedulesNextDailyRefresh()
        try checkDefaultConferenceDataURLUsesCurrentRepository()
        try checkLoadsConferenceJSON()
        try checkLoadsConferenceJSONFromData()
        try checkUnknownConferenceDataValuesUseFallbacks()
        try checkConferenceDataUpdaterFallsBackWhenCacheIsInvalid()
        try checkLoadsProjectConferenceData()
        try checkBundledMacConferenceDataMatchesPublicData()
        try checkBundledAndroidConferenceDataMatchesPublicData()

        print("DdayCoreChecks passed")
    }

    private static func checkFutureDeadlineUsesDMinusFormat() throws {
        let deadline = ConferenceDeadline(
            id: "paper",
            label: "Paper Deadline",
            date: "2026-05-30",
            time: "23:59",
            timezone: "UTC",
            type: .submission,
            isPrimary: true
        )
        let now = try require(ISO8601DateFormatter().date(from: "2026-05-27T12:00:00Z"))

        let display = try DeadlineCalculator().display(
            for: deadline,
            now: now,
            displayTimeZone: TimeZone(secondsFromGMT: 0)!
        )

        try expect(display.text == "D-3", "expected D-3, got \(display.text)")
        try expect(display.days == 3, "expected 3 days, got \(display.days)")
    }

    private static func checkSameLocalDeadlineDayUsesDDayFormat() throws {
        let deadline = ConferenceDeadline(
            id: "paper",
            label: "Paper Deadline",
            date: "2026-05-27",
            time: "23:59",
            timezone: "UTC",
            type: .submission,
            isPrimary: true
        )
        let now = try require(ISO8601DateFormatter().date(from: "2026-05-27T12:00:00Z"))

        let display = try DeadlineCalculator().display(
            for: deadline,
            now: now,
            displayTimeZone: TimeZone(secondsFromGMT: 0)!
        )

        try expect(display.text == "H-12", "expected H-12, got \(display.text)")
        try expect(display.days == 0, "expected 0 days, got \(display.days)")
    }

    private static func checkSameLocalDeadlineDayUsesHourCountdown() throws {
        let deadline = ConferenceDeadline(
            id: "paper",
            label: "Paper Deadline",
            date: "2026-05-27",
            time: "23:59",
            timezone: "UTC",
            type: .submission,
            isPrimary: true
        )
        let timezone = TimeZone(secondsFromGMT: 0)!

        let h24Now = try require(ISO8601DateFormatter().date(from: "2026-05-27T00:00:00Z"))
        let h10Now = try require(ISO8601DateFormatter().date(from: "2026-05-27T14:00:00Z"))

        let h24Display = try DeadlineCalculator().display(
            for: deadline,
            now: h24Now,
            displayTimeZone: timezone
        )
        let h10Display = try DeadlineCalculator().display(
            for: deadline,
            now: h10Now,
            displayTimeZone: timezone
        )

        try expect(h24Display.text == "H-24", "expected H-24, got \(h24Display.text)")
        try expect(h10Display.text == "H-10", "expected H-10, got \(h10Display.text)")
    }

    private static func checkSameLocalDeadlineDayUsesMinuteCountdown() throws {
        let deadline = ConferenceDeadline(
            id: "paper",
            label: "Paper Deadline",
            date: "2026-05-27",
            time: "23:59",
            timezone: "UTC",
            type: .submission,
            isPrimary: true
        )
        let timezone = TimeZone(secondsFromGMT: 0)!

        let m59Now = try require(ISO8601DateFormatter().date(from: "2026-05-27T23:00:00Z"))
        let m10Now = try require(ISO8601DateFormatter().date(from: "2026-05-27T23:49:00Z"))
        let m1Now = try require(ISO8601DateFormatter().date(from: "2026-05-27T23:58:01Z"))

        let m59Display = try DeadlineCalculator().display(
            for: deadline,
            now: m59Now,
            displayTimeZone: timezone
        )
        let m10Display = try DeadlineCalculator().display(
            for: deadline,
            now: m10Now,
            displayTimeZone: timezone
        )
        let m1Display = try DeadlineCalculator().display(
            for: deadline,
            now: m1Now,
            displayTimeZone: timezone
        )

        try expect(m59Display.text == "M-59", "expected M-59, got \(m59Display.text)")
        try expect(m10Display.text == "M-10", "expected M-10, got \(m10Display.text)")
        try expect(m1Display.text == "M-1", "expected M-1, got \(m1Display.text)")
    }

    private static func checkPastDeadlineUsesDPlusFormat() throws {
        let deadline = ConferenceDeadline(
            id: "paper",
            label: "Paper Deadline",
            date: "2026-05-20",
            time: "23:59",
            timezone: "UTC",
            type: .submission,
            isPrimary: true
        )
        let now = try require(ISO8601DateFormatter().date(from: "2026-05-27T12:00:00Z"))

        let display = try DeadlineCalculator().display(
            for: deadline,
            now: now,
            displayTimeZone: TimeZone(secondsFromGMT: 0)!
        )

        try expect(display.text == "D+7", "expected D+7, got \(display.text)")
        try expect(display.days == -7, "expected -7 days, got \(display.days)")
    }

    private static func checkInvalidDeadlineDateIsRejected() throws {
        let deadline = ConferenceDeadline(
            id: "paper",
            label: "Paper Deadline",
            date: "2026-13-01",
            time: "23:59",
            timezone: "UTC",
            type: .submission,
            isPrimary: true
        )

        do {
            _ = try DeadlineCalculator().date(for: deadline)
            throw CheckError("invalid date should be rejected")
        } catch DeadlineCalculationError.invalidDate {
            return
        }
    }

    private static func checkInvalidDeadlineTimeIsRejected() throws {
        let deadline = ConferenceDeadline(
            id: "paper",
            label: "Paper Deadline",
            date: "2026-05-27",
            time: "25:99",
            timezone: "UTC",
            type: .submission,
            isPrimary: true
        )

        do {
            _ = try DeadlineCalculator().date(for: deadline)
            throw CheckError("invalid time should be rejected")
        } catch DeadlineCalculationError.invalidTime {
            return
        }
    }

    private static func checkInvalidDeadlineTimezoneIsRejected() throws {
        let deadline = ConferenceDeadline(
            id: "paper",
            label: "Paper Deadline",
            date: "2026-05-27",
            time: "23:59",
            timezone: "Not/A-TimeZone",
            type: .submission,
            isPrimary: true
        )

        do {
            _ = try DeadlineCalculator().date(for: deadline)
            throw CheckError("invalid timezone should be rejected")
        } catch DeadlineCalculationError.invalidTimeZone {
            return
        }
    }

    private static func checkInvalidStoredUserDeadlineTimezoneIsMigrated() throws {
        let suiteName = "DdayCoreChecks-\(UUID().uuidString)"
        let defaults = try require(UserDefaults(suiteName: suiteName))
        defer {
            defaults.removePersistentDomain(forName: suiteName)
        }

        let store = UserDeadlineStore(defaults: defaults)
        store.deadlines = [
            UserDeadline(
                id: "legacy",
                name: "Legacy D-Day",
                label: "Deadline",
                date: "2026-08-01",
                time: "12:00",
                timezone: "Not/A-TimeZone",
                createdAt: Date(timeIntervalSince1970: 0)
            )
        ]

        let migrated = try require(store.deadlines.first)
        try expect(
            migrated.timezone == TimeZone.current.identifier,
            "invalid stored timezone should migrate to the current timezone"
        )

        let reloaded = UserDeadlineStore(defaults: defaults)
        try expect(
            reloaded.deadlines.first?.timezone == TimeZone.current.identifier,
            "migrated timezone should be persisted"
        )
    }

    private static func checkMenuBarGlassAppearancePersists() throws {
        let suiteName = "DdayCoreChecks-\(UUID().uuidString)"
        let defaults = try require(UserDefaults(suiteName: suiteName))
        defer {
            defaults.removePersistentDomain(forName: suiteName)
        }

        let settings = SettingsStore(defaults: defaults)
        try expect(
            settings.menuBarGlassAppearance == .standard,
            "glass appearance should use the standard defaults when unset"
        )

        let customized = MenuBarGlassAppearance(
            backgroundRGB: DdayRGBColor(red: -10, green: 120, blue: 300),
            textRGB: DdayRGBColor(red: 220, green: 230, blue: 240),
            usesAutomaticTextColor: false
        )
        settings.menuBarVisualStyle = .glass
        settings.menuBarGlassAppearance = customized

        let reloaded = SettingsStore(defaults: defaults)
        try expect(
            reloaded.menuBarVisualStyle == .glass,
            "glass visual style should persist"
        )
        try expect(
            reloaded.menuBarGlassAppearance == customized,
            "glass RGB appearance should persist"
        )
        try expect(
            reloaded.menuBarGlassAppearance.backgroundRGB
                == DdayRGBColor(red: 0, green: 120, blue: 255),
            "glass RGB values should be clamped to 0...255"
        )
    }

    private static func checkAoEMapsToUTCMinusTwelve() throws {
        let timezone = try DeadlineCalculator().resolvedTimeZone("AoE")

        try expect(
            timezone.secondsFromGMT() == -12 * 60 * 60,
            "expected AoE to map to UTC-12"
        )
    }

    private static func checkAoEDeadlineUsesLocalDisplayTimezone() throws {
        let deadline = ConferenceDeadline(
            id: "full-paper",
            label: "Full Papers Due",
            date: "2026-07-28",
            time: "23:59",
            timezone: "AoE",
            type: .submission,
            isPrimary: true
        )
        let now = try require(ISO8601DateFormatter().date(from: "2026-07-28T00:00:00Z"))
        let korea = try require(TimeZone(identifier: "Asia/Seoul"))

        let display = try DeadlineCalculator().display(
            for: deadline,
            now: now,
            displayTimeZone: korea
        )

        try expect(display.text == "D-1", "expected D-1 in Asia/Seoul, got \(display.text)")
    }

    private static func checkWidgetTimelineSkipsDistantAndEmptyDeadlines() throws {
        let calendar = utcCalendar()
        let now = try require(ISO8601DateFormatter().date(from: "2026-07-01T12:00:00Z"))
        let deadline = try require(ISO8601DateFormatter().date(from: "2026-07-03T23:59:00Z"))

        let distantDates = DeadlineTimelinePlanner.entryDates(
            now: now,
            deadline: deadline,
            shouldScheduleCountdown: true,
            calendar: calendar
        )
        let emptyDates = DeadlineTimelinePlanner.entryDates(
            now: now,
            deadline: deadline,
            shouldScheduleCountdown: false,
            calendar: calendar
        )

        try expect(distantDates == [now], "distant deadlines should use the daily refresh only")
        try expect(emptyDates == [now], "empty widget snapshots should not schedule countdown entries")
    }

    private static func checkWidgetTimelineSchedulesVisibleTransitions() throws {
        let calendar = utcCalendar()
        let now = try require(ISO8601DateFormatter().date(from: "2026-07-01T23:50:00Z"))
        let midnight = try require(ISO8601DateFormatter().date(from: "2026-07-02T00:00:00Z"))
        let firstMinuteTransition = try require(
            ISO8601DateFormatter().date(from: "2026-07-02T00:01:00Z")
        )
        let deadline = try require(ISO8601DateFormatter().date(from: "2026-07-02T01:00:00Z"))

        let dates = DeadlineTimelinePlanner.entryDates(
            now: now,
            deadline: deadline,
            shouldScheduleCountdown: true,
            calendar: calendar
        )

        try expect(dates.first == now, "widget timeline should start immediately")
        try expect(dates.contains(midnight), "widget timeline should refresh at the deadline day boundary")
        try expect(
            dates.contains(firstMinuteTransition),
            "widget timeline should include the H-1 to M-59 transition"
        )
        try expect(dates.last == deadline, "widget timeline should include the exact deadline")
        try expect(
            zip(dates, dates.dropFirst()).allSatisfy(<),
            "widget timeline entries should be strictly increasing"
        )
    }

    private static func checkWidgetTimelineEntryCountIsBounded() throws {
        let calendar = utcCalendar()
        let now = try require(ISO8601DateFormatter().date(from: "2026-07-02T00:00:00Z"))
        let deadline = try require(ISO8601DateFormatter().date(from: "2026-07-02T23:59:00Z"))

        let dates = DeadlineTimelinePlanner.entryDates(
            now: now,
            deadline: deadline,
            shouldScheduleCountdown: true,
            calendar: calendar
        )

        try expect(
            dates.count <= DeadlineTimelinePlanner.maximumEntryCount,
            "widget timeline should respect the entry limit"
        )
        try expect(dates.last == deadline, "bounded widget timeline should preserve the exact deadline")
    }

    private static func checkWidgetTimelineSchedulesNextDailyRefresh() throws {
        let calendar = utcCalendar()
        let now = try require(ISO8601DateFormatter().date(from: "2026-07-01T23:59:00Z"))
        let expected = try require(ISO8601DateFormatter().date(from: "2026-07-02T00:05:00Z"))

        let nextRefresh = DeadlineTimelinePlanner.nextDailyRefresh(
            after: now,
            calendar: calendar
        )

        try expect(nextRefresh == expected, "widget should schedule its next daily refresh at 00:05")
    }

    private static func checkDefaultConferenceDataURLUsesCurrentRepository() throws {
        try expect(
            ConferenceDataUpdater.defaultRemoteURL.absoluteString
                == "https://raw.githubusercontent.com/mindw96/AI-Conference-Dday/main/data/conferences.json",
            "default conference data URL must use the current repository name"
        )
    }

    private static func checkLoadsConferenceJSON() throws {
        let url = try require(Bundle.module.url(forResource: "conferences-fixture", withExtension: "json"))
        let store = try ConferenceStore.load(from: url)

        try expect(store.conferences.count == 1, "expected one fixture conference")
        try expect(store.conferences.first?.id == "testconf-2026", "unexpected conference id")
        try expect(store.conferences.first?.subcategory == .ml, "unexpected fixture subcategory")
        try expect(store.conferences.first?.primaryDeadline?.id == "full-paper", "unexpected primary deadline")
    }

    private static func checkLoadsConferenceJSONFromData() throws {
        let url = try require(Bundle.module.url(forResource: "conferences-fixture", withExtension: "json"))
        let data = try Data(contentsOf: url)
        let store = try ConferenceStore.load(from: data)

        try expect(store.conferences.count == 1, "expected one fixture conference from data")
        try expect(store.conferences.first?.id == "testconf-2026", "unexpected conference id from data")
    }

    private static func checkUnknownConferenceDataValuesUseFallbacks() throws {
        let json = """
        [
          {
            "id": "futureconf-2026",
            "name": "FutureConf",
            "fullName": "Future Conference",
            "year": 2026,
            "field": ["testing"],
            "subcategory": "future-category",
            "location": "Online",
            "websiteUrl": "https://example.com/futureconf",
            "sourceUrl": "https://example.com/futureconf/cfp",
            "sourceCheckedAt": "2026-06-12",
            "timezone": "AoE",
            "deadlines": [
              {
                "id": "full-paper",
                "label": "Full Paper Submission",
                "date": "2026-06-01",
                "time": "23:59",
                "timezone": "AoE",
                "type": "future-kind",
                "isPrimary": true
              }
            ]
          }
        ]
        """
        let store = try ConferenceStore.load(from: Data(json.utf8))
        let conference = try require(store.conferences.first)
        let deadline = try require(conference.primaryDeadline)

        try expect(conference.subcategory == .generalAI, "unknown subcategory should fallback to General AI")
        try expect(deadline.type == .submission, "unknown deadline type should fallback to submission")
    }

    private static func checkConferenceDataUpdaterFallsBackWhenCacheIsInvalid() throws {
        let fileManager = FileManager.default
        let fixtureURL = try require(Bundle.module.url(forResource: "conferences-fixture", withExtension: "json"))
        let temporaryDirectory = fileManager.temporaryDirectory
            .appendingPathComponent("DdayCoreChecks-\(UUID().uuidString)", isDirectory: true)
        let cacheURL = temporaryDirectory.appendingPathComponent("conferences.json")

        try fileManager.createDirectory(at: temporaryDirectory, withIntermediateDirectories: true)
        defer {
            try? fileManager.removeItem(at: temporaryDirectory)
        }

        try Data("not json".utf8).write(to: cacheURL)

        let updater = ConferenceDataUpdater(
            remoteURL: URL(string: "https://example.invalid/conferences.json")!,
            cacheURL: cacheURL,
            fileManager: fileManager
        )
        let store = try updater.loadPreferred(bundledURL: fixtureURL)

        try expect(store.conferences.count == 1, "expected bundled data after invalid cache")
        try expect(!fileManager.fileExists(atPath: cacheURL.path), "invalid cache should be removed")
    }

    private static func checkLoadsProjectConferenceData() throws {
        let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        let url = root.appendingPathComponent("data/conferences.json")
        let store = try ConferenceStore.load(from: url)

        try expect(store.conferences.count >= 29, "expected at least 29 seed conferences")
        try expect(
            store.conferences.allSatisfy { !$0.deadlines.isEmpty },
            "each conference must have at least one deadline"
        )
        try expect(
            store.conferences.contains { $0.id == "eccv-2026" && $0.subcategory == .cv },
            "expected ECCV 2026 in CV subcategory"
        )
        try expect(
            store.conferences.contains { $0.id == "emnlp-2026" && $0.subcategory == .nlp },
            "expected EMNLP 2026 in NLP subcategory"
        )
        try expect(
            store.conferences.contains { $0.id == "neurips-2026" && $0.subcategory == .ml },
            "expected NeurIPS 2026 in ML subcategory"
        )
        try expect(
            store.conferences.contains { $0.id == "kdd-2026" && $0.subcategory == .ml },
            "expected KDD 2026 in ML subcategory"
        )
        try expect(
            store.conferences.contains { $0.id == "accv-2026" && $0.subcategory == .cv },
            "expected ACCV 2026 in CV subcategory"
        )
        try expect(
            store.conferences.contains { $0.id == "colm-2026" && $0.subcategory == .nlp },
            "expected COLM 2026 in NLP subcategory"
        )
        try expect(
            store.conferences.contains { $0.id == "sigir-2026" && $0.subcategory == .nlp },
            "expected SIGIR 2026 in NLP subcategory"
        )
        try expect(
            store.conferences.contains { $0.id == "ijcai-ecai-2026" && $0.subcategory == .generalAI },
            "expected IJCAI-ECAI 2026 in General AI subcategory"
        )
        try expect(
            store.conferences.contains { $0.id == "kr-2026" && $0.subcategory == .generalAI },
            "expected KR 2026 in General AI subcategory"
        )

        try checkProjectConferenceDataUsesStableFeedSchema(url: url)
    }

    private static func checkBundledMacConferenceDataMatchesPublicData() throws {
        let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        let publicURL = root.appendingPathComponent("data/conferences.json")
        let bundledURL = root.appendingPathComponent("Sources/DdayApp/Resources/conferences.json")

        let publicData = try Data(contentsOf: publicURL)
        let bundledData = try Data(contentsOf: bundledURL)

        try expect(
            publicData == bundledData,
            "Sources/DdayApp/Resources/conferences.json must match data/conferences.json"
        )
    }

    private static func checkBundledAndroidConferenceDataMatchesPublicData() throws {
        let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        let publicURL = root.appendingPathComponent("data/conferences.json")
        let bundledURL = root.appendingPathComponent(
            "Apps/Android/app/src/main/assets/conferences.json"
        )

        let publicData = try Data(contentsOf: publicURL)
        let bundledData = try Data(contentsOf: bundledURL)

        try expect(
            publicData == bundledData,
            "Apps/Android/app/src/main/assets/conferences.json must match data/conferences.json"
        )
    }

    private static func checkProjectConferenceDataUsesStableFeedSchema(url: URL) throws {
        let data = try Data(contentsOf: url)
        let raw = try JSONSerialization.jsonObject(with: data)
        guard let conferences = raw as? [[String: Any]] else {
            throw CheckError("project conference data must be a JSON array of objects")
        }

        let allowedSubcategories = Set(ConferenceSubcategory.allCases.map(\.rawValue))
        let allowedDeadlineKinds: Set<String> = [
            "abstract",
            "submission",
            "supplementary",
            "notification",
            "camera-ready",
            "conference-start",
            "conference-end"
        ]
        var conferenceIDs = Set<String>()

        for conference in conferences {
            let id = try require(conference["id"] as? String)
            try expect(conferenceIDs.insert(id).inserted, "duplicate conference id: \(id)")

            let subcategory = try require(conference["subcategory"] as? String)
            try expect(
                allowedSubcategories.contains(subcategory),
                "unknown conference subcategory in published feed: \(subcategory)"
            )

            try expectWebURL(conference["websiteUrl"] as? String, field: "\(id).websiteUrl")
            try expectWebURL(conference["sourceUrl"] as? String, field: "\(id).sourceUrl")
            try expectValidDate(conference["sourceCheckedAt"] as? String, field: "\(id).sourceCheckedAt")
            try expectValidTimeZone(conference["timezone"] as? String, field: "\(id).timezone")

            guard let deadlines = conference["deadlines"] as? [[String: Any]], !deadlines.isEmpty else {
                throw CheckError("conference \(id) must have at least one deadline")
            }

            var deadlineIDs = Set<String>()
            for deadline in deadlines {
                let deadlineID = try require(deadline["id"] as? String)
                try expect(deadlineIDs.insert(deadlineID).inserted, "duplicate deadline id: \(id).\(deadlineID)")

                let kind = try require(deadline["type"] as? String)
                try expect(allowedDeadlineKinds.contains(kind), "unknown deadline type in published feed: \(kind)")
                try expectValidDate(deadline["date"] as? String, field: "\(id).\(deadlineID).date")

                if let time = deadline["time"] as? String {
                    try expectValidTime(time, field: "\(id).\(deadlineID).time")
                }
                try expectValidTimeZone(
                    deadline["timezone"] as? String,
                    field: "\(id).\(deadlineID).timezone"
                )
            }
        }
    }

    private static func expectWebURL(_ value: String?, field: String) throws {
        let urlString = try require(value)
        let url = try require(URL(string: urlString))

        try expect(url.scheme?.lowercased() == "https", "\(field) must be https")
    }

    private static func expectValidDate(_ value: String?, field: String) throws {
        let date = try require(value)
        let parts = date.split(separator: "-").compactMap { Int($0) }
        guard parts.count == 3 else {
            throw CheckError("\(field) must use yyyy-mm-dd")
        }

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!

        var components = DateComponents()
        components.calendar = calendar
        components.timeZone = calendar.timeZone
        components.year = parts[0]
        components.month = parts[1]
        components.day = parts[2]

        try expect(components.isValidDate(in: calendar), "\(field) must be a valid date")
    }

    private static func expectValidTime(_ value: String, field: String) throws {
        let parts = value.split(separator: ":").compactMap { Int($0) }
        guard parts.count == 2 else {
            throw CheckError("\(field) must use HH:mm")
        }

        try expect((0...23).contains(parts[0]) && (0...59).contains(parts[1]), "\(field) must be a valid time")
    }

    private static func expectValidTimeZone(_ value: String?, field: String) throws {
        let identifier = try require(value)
        do {
            _ = try DeadlineCalculator().resolvedTimeZone(identifier)
        } catch {
            throw CheckError("\(field) must be AoE or a valid IANA timezone identifier")
        }
    }

    private static func expect(
        _ condition: @autoclosure () -> Bool,
        _ message: String
    ) throws {
        if !condition() {
            throw CheckError(message)
        }
    }

    private static func require<T>(_ value: T?) throws -> T {
        guard let value else {
            throw CheckError("required value was nil")
        }

        return value
    }

    private static func utcCalendar() -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }
}

private struct CheckError: Error, CustomStringConvertible {
    let description: String

    init(_ description: String) {
        self.description = description
    }
}

try DdayCoreChecks.run()
