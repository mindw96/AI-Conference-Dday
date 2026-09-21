#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
WORK_ROOT="$(mktemp -d /private/tmp/dday-menu-checks.XXXXXX)"
trap 'rm -rf "$WORK_ROOT"' EXIT

cd "$ROOT"
TARGET="$(uname -m)-apple-macosx13.0"

# Build the small shared module directly. Swift 6.4's Swift Build engine and
# older SwiftPM versions use different internal module/object directories.
xcrun swiftc -swift-version 6 -target "$TARGET" \
  -module-cache-path "$WORK_ROOT/ModuleCache" \
  -emit-library -emit-module -module-name DdayCore \
  -emit-module-path "$WORK_ROOT/DdayCore.swiftmodule" \
  Sources/DdayCore/Models/*.swift Sources/DdayCore/Services/*.swift \
  -o "$WORK_ROOT/libDdayCore.dylib"

# The appended extension can exercise private controller state while keeping
# production APIs private. The runner stubs Sparkle and keeps defaults in memory.
cat Sources/DdayApp/App/MenuBarController.swift \
    Checks/DdayAppChecks/MenuBarControllerChecks.swift \
    > "$WORK_ROOT/MenuBarController.swift"
cat Sources/DdayApp/App/StatusBadgeRenderer.swift \
    Checks/DdayAppChecks/StatusBadgeRendererChecks.swift \
    > "$WORK_ROOT/StatusBadgeRenderer.swift"

xcrun swiftc -swift-version 6 -target "$TARGET" -parse-as-library \
  -module-cache-path "$WORK_ROOT/ModuleCache" \
  -I "$WORK_ROOT" -L "$WORK_ROOT" -lDdayCore \
  -Xlinker -rpath -Xlinker "$WORK_ROOT" \
  "$WORK_ROOT/MenuBarController.swift" \
  Checks/DdayAppChecks/CheckRunner.swift \
  "$WORK_ROOT/StatusBadgeRenderer.swift" \
  Sources/DdayApp/App/BadgeAppearanceWindowController.swift \
  -o "$WORK_ROOT/DdayAppChecks"

"$WORK_ROOT/DdayAppChecks" | tee "$WORK_ROOT/results.log"

# AppKit can exit successfully before running assertions when it cannot connect
# to the window server. Require the runner's completion marker as well as exit 0.
if ! grep -Fxq 'DDAY_MACOS_MENU_CHECKS_COMPLETED' "$WORK_ROOT/results.log"; then
  echo "macOS menu checks did not complete. Run from a logged-in macOS desktop with AppKit access." >&2
  exit 1
fi
if ! grep -Fxq 'DDAY_MACOS_BADGE_CHECKS_COMPLETED' "$WORK_ROOT/results.log"; then
  echo "macOS badge accessibility checks did not complete." >&2
  exit 1
fi
