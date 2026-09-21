#!/bin/bash
set -euo pipefail

# Runs model and scheduling regressions with an in-memory notification center.
# Requires Xcode on macOS; does not request notification/calendar permissions.
ROOT_DIR="$(cd "$(dirname "$0")/../../.." && pwd)"
CHECK_BUILD_DIR="$(mktemp -d "${TMPDIR:-/tmp}/dday-mobile-checks.XXXXXX")"
trap 'rm -rf "$CHECK_BUILD_DIR"' EXIT
TARGET="$(uname -m)-apple-macosx14.0"

xcrun swiftc -swift-version 6 -target "$TARGET" \
  -module-cache-path "$CHECK_BUILD_DIR/module-cache" \
  -emit-library -emit-module -module-name DdayCore \
  -emit-module-path "$CHECK_BUILD_DIR/DdayCore.swiftmodule" \
  "$ROOT_DIR"/Sources/DdayCore/Models/*.swift \
  "$ROOT_DIR"/Sources/DdayCore/Services/*.swift \
  -o "$CHECK_BUILD_DIR/libDdayCore.dylib"

xcrun swiftc -swift-version 6 -target "$TARGET" -parse-as-library \
  -module-cache-path "$CHECK_BUILD_DIR/module-cache" \
  -I "$CHECK_BUILD_DIR" -L "$CHECK_BUILD_DIR" -lDdayCore \
  -Xlinker -rpath -Xlinker "$CHECK_BUILD_DIR" \
  "$ROOT_DIR/Apps/Mobile/DdayMobile/App/MobileAppModel.swift" \
  "$ROOT_DIR/Apps/Mobile/DdayMobile/App/MobileAppText.swift" \
  "$ROOT_DIR/Apps/Mobile/DdayMobile/App/MobileCalendarEventWriter.swift" \
  "$ROOT_DIR/Apps/Mobile/DdayMobile/App/MobileConferenceLoader.swift" \
  "$ROOT_DIR/Apps/Mobile/DdayMobile/App/MobileNotificationScheduler.swift" \
  "$ROOT_DIR/Apps/Mobile/DdayMobile/Models/MobileDeadlineSummary.swift" \
  "$ROOT_DIR/Apps/Mobile/Shared/MobileWidgetSnapshotStore.swift" \
  "$ROOT_DIR/Apps/Mobile/Checks/MobileChecks.swift" \
  -o "$CHECK_BUILD_DIR/MobileChecks"

"$CHECK_BUILD_DIR/MobileChecks"
