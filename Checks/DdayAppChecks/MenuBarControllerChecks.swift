// Appended to MenuBarController.swift by scripts/check_macos_menu.sh so the
// regression checks can exercise private state without widening the app API.

extension MenuBarController {
    static func runRegressionChecks() -> Int32 {
        var failures: Int32 = 0
        var count = 0
        func check(_ condition: Bool, _ name: String) {
            count += 1
            if !condition { failures += 1 }
            print("\(condition ? "PASS" : "FAIL"): \(name)")
        }
        func makeController(date: String? = nil) -> MenuBarController {
            let defaults = InMemoryDefaults()
            let settings = SettingsStore(defaults: defaults)
            settings.appLanguage = .english
            let userStore = UserDeadlineStore(defaults: defaults)
            if let date {
                userStore.add(UserDeadline(id: "custom-uuid", name: "Personal", label: "Deadline", date: date, time: "12:00", timezone: "UTC", createdAt: Date()))
            }
            return MenuBarController(store: ConferenceStore(conferences: []), calculator: DeadlineCalculator(), settings: settings, userDeadlineStore: userStore, appUpdater: AppUpdater())
        }
        for date in ["2099-12-31", "2000-01-01"] {
            let controller = makeController(date: date)
            check(controller.settings.selectedDeadline?.deadlineID == "custom-uuid", "Persist actual custom ID for \(date)")
            check(controller.resolvedSelection()?.deadlineID == "custom-uuid", "Restore custom selection for \(date)")
            let menu = controller.statusItem.menu!
            controller.menuNeedsUpdate(menu)
            let customItems = menu.items.first { $0.title == "Custom D-Days" }?.submenu?.items ?? []
            check(customItems.first?.state == .on, "Custom checkmark for \(date)")
            controller.removeSelectedCustomDday()
            check(controller.userDeadlineStore.deadlines.isEmpty, "Remove automatically selected custom deadline for \(date)")
            controller.refreshTimer?.invalidate()
            NSStatusBar.system.removeStatusItem(controller.statusItem)
        }
        let controller = makeController()
        defer {
            controller.refreshTimer?.invalidate()
            NSStatusBar.system.removeStatusItem(controller.statusItem)
        }
        let menu = controller.statusItem.menu!
        controller.menuNeedsUpdate(menu)
        check(menu.items.contains { $0.action == #selector(addCustomDday) }, "Empty catalog allows adding a custom deadline")
        check(menu.items.first?.isEnabled == false, "Informational menu rows remain disabled")
        let initialItems = menu.items
        for _ in 0..<5 { controller.refresh() }
        check(controller.statusItem.menu === menu && zip(initialItems, menu.items).allSatisfy { $0 === $1 }, "Refresh preserves menu and existing items")
        controller.isUpdatingConferences = true
        controller.menuNeedsUpdate(menu)
        menu.update()
        check(menu.items.first { $0.action == #selector(checkConferenceListUpdates) }?.isEnabled == false, "Menu validation keeps an in-flight update disabled")
        controller.isUpdatingConferences = false
        controller.settings.menuBarVisualStyle = .glass
        controller.startupError = NSError(domain: "fixture", code: 1)
        controller.refresh()
        let image = controller.statusItem.button!.image
        controller.refresh()
        check(controller.statusItem.button?.image === image, "Unchanged badge image is reused")
        let originalAppearance = controller.statusItem.button?.appearance
        let isDark = controller.statusItem.button!.effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
        controller.statusItem.button?.appearance = NSAppearance(named: isDark ? .aqua : .darkAqua)
        controller.refresh()
        check(controller.statusItem.button?.image !== image, "Menu bar appearance change invalidates the badge cache")
        controller.statusItem.button?.appearance = originalAppearance
        controller.settings.menuBarVisualStyle = .plain
        controller.refresh()
        check(controller.statusItem.button?.image == nil && controller.statusItem.button?.title == "Dday Error", "Switching to plain text clears the badge image")
        controller.menuNeedsUpdate(menu)
        check(controller.statusItem.button?.toolTip == "Dday Error", "Startup failure survives refresh")
        check(menu.items.contains { $0.action == #selector(checkConferenceListUpdates) }, "Startup failure still allows catalog recovery")
        check(menu.items.contains { $0.action == #selector(addCustomDday) }, "Startup failure still allows custom deadlines")
        print("\(count - Int(failures))/\(count) macOS menu checks passed")
        print("DDAY_MACOS_MENU_CHECKS_COMPLETED")
        return failures == 0 ? 0 : 1
    }
}
