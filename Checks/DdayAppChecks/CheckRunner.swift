import AppKit
import DdayCore

// Keep all test settings in memory; never touch the user's app preferences.
final class InMemoryDefaults: UserDefaults, @unchecked Sendable {
    private var values: [String: Any] = [:]
    init() { super.init(suiteName: nil)! }
    override func string(forKey key: String) -> String? { values[key] as? String }
    override func data(forKey key: String) -> Data? { values[key] as? Data }
    override func set(_ value: Any?, forKey key: String) { values[key] = value }
}
// Stub only Sparkle startup so these UI checks never check for updates.
@MainActor final class AppUpdater {
    func menuItem(title: String) -> NSMenuItem { NSMenuItem(title: title, action: nil, keyEquivalent: "") }
}
@main struct MenuChecks {
    @MainActor static func main() {
        NSApplication.shared.setActivationPolicy(.prohibited)
        let menuResult = MenuBarController.runRegressionChecks()
        let badgeResult = StatusBadgeRenderer.runAccessibilityChecks()
        exit(menuResult | badgeResult)
    }
}
