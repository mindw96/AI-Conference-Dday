import Foundation

public final class SettingsStore {
    private enum Key {
        static let selectedConferenceID = "selectedConferenceID"
        static let selectedDeadlineID = "selectedDeadlineID"
        static let menuBarDisplayMode = "menuBarDisplayMode"
        static let menuBarVisualStyle = "menuBarVisualStyle"
        static let menuBarGlassAppearance = "menuBarGlassAppearance"
        static let appLanguage = "appLanguage"
    }

    private let defaults: UserDefaults

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    public var selectedConferenceID: String? {
        get { defaults.string(forKey: Key.selectedConferenceID) }
        set { defaults.set(newValue, forKey: Key.selectedConferenceID) }
    }

    public var selectedDeadlineID: String? {
        get { defaults.string(forKey: Key.selectedDeadlineID) }
        set { defaults.set(newValue, forKey: Key.selectedDeadlineID) }
    }

    public var menuBarDisplayMode: MenuBarDisplayMode {
        get {
            guard let rawValue = defaults.string(forKey: Key.menuBarDisplayMode),
                  let mode = MenuBarDisplayMode(rawValue: rawValue) else {
                return .conferenceAndDday
            }

            return mode
        }
        set {
            defaults.set(newValue.rawValue, forKey: Key.menuBarDisplayMode)
        }
    }

    public var menuBarVisualStyle: MenuBarVisualStyle {
        get {
            guard let rawValue = defaults.string(forKey: Key.menuBarVisualStyle),
                  let style = MenuBarVisualStyle(rawValue: rawValue) else {
                return .plain
            }

            return style
        }
        set {
            defaults.set(newValue.rawValue, forKey: Key.menuBarVisualStyle)
        }
    }

    public var menuBarGlassAppearance: MenuBarGlassAppearance {
        get {
            guard let data = defaults.data(forKey: Key.menuBarGlassAppearance),
                  let appearance = try? JSONDecoder().decode(
                      MenuBarGlassAppearance.self,
                      from: data
                  ) else {
                return .standard
            }

            return appearance
        }
        set {
            guard let data = try? JSONEncoder().encode(newValue) else {
                return
            }
            defaults.set(data, forKey: Key.menuBarGlassAppearance)
        }
    }

    public var appLanguage: AppLanguage {
        get {
            guard let rawValue = defaults.string(forKey: Key.appLanguage),
                  let language = AppLanguage(rawValue: rawValue) else {
                return .system
            }

            return language
        }
        set {
            defaults.set(newValue.rawValue, forKey: Key.appLanguage)
        }
    }

    public var selectedDeadline: DeadlineSelection? {
        get {
            guard let selectedConferenceID,
                  let selectedDeadlineID else {
                return nil
            }

            return DeadlineSelection(
                conferenceID: selectedConferenceID,
                deadlineID: selectedDeadlineID
            )
        }
        set {
            selectedConferenceID = newValue?.conferenceID
            selectedDeadlineID = newValue?.deadlineID
        }
    }
}

public enum MenuBarDisplayMode: String, Codable, Equatable, CaseIterable {
    case ddayOnly
    case conferenceAndDday
    case conferenceAndDate
}

public enum MenuBarVisualStyle: String, Codable, Equatable, CaseIterable {
    case plain
    case badge
    case glass
}

public struct DdayRGBColor: Codable, Equatable, Sendable {
    public let red: Int
    public let green: Int
    public let blue: Int

    public init(red: Int, green: Int, blue: Int) {
        self.red = Self.clamp(red)
        self.green = Self.clamp(green)
        self.blue = Self.clamp(blue)
    }

    private static func clamp(_ value: Int) -> Int {
        min(max(value, 0), 255)
    }
}

public struct MenuBarGlassAppearance: Codable, Equatable, Sendable {
    public var backgroundRGB: DdayRGBColor
    public var textRGB: DdayRGBColor
    public var usesAutomaticTextColor: Bool

    public init(
        backgroundRGB: DdayRGBColor,
        textRGB: DdayRGBColor,
        usesAutomaticTextColor: Bool
    ) {
        self.backgroundRGB = backgroundRGB
        self.textRGB = textRGB
        self.usesAutomaticTextColor = usesAutomaticTextColor
    }

    public static let standard = MenuBarGlassAppearance(
        backgroundRGB: DdayRGBColor(red: 74, green: 125, blue: 255),
        textRGB: DdayRGBColor(red: 20, green: 29, blue: 48),
        usesAutomaticTextColor: true
    )
}

public enum AppLanguage: String, Codable, Equatable, CaseIterable {
    case system
    case english
    case korean
}
