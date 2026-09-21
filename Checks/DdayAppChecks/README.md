# macOS menu regression checks

Run from a logged-in macOS desktop:

```bash
./scripts/check_macos_menu.sh
```

The runner compiles the real menu controller, badge renderer, and appearance
editor. It appends a test extension to a temporary source copy so private state
can be exercised without changing the app's API. It uses memory-only preferences
and a stub for Sparkle; it does not install the app or change saved settings.
Temporary status items are removed before the runner exits.

Checks cover automatic custom-deadline selection and deletion, empty/error menus,
update-action validation, stable menus during refresh, and badge cache behavior.
Badge checks cover opaque rendering with Reduce Transparency, at least 4.5:1
text contrast across 64 custom colors in each appearance with Increase Contrast,
and rendering into a 2x bitmap. Accessibility preferences are injected into the
renderer, so the checks do not modify system settings.

The runner compiles DdayCore in its temporary directory instead of depending on
SwiftPM's internal object layout, which changed with Swift 6.4 / Xcode 27.
An explicit completion marker prevents an unavailable window server from being
mistaken for a passing run. These checks are intentionally separate from the
headless core checks.
