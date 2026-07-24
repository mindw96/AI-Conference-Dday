#!/usr/bin/env bash

set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export ANDROID_SDK_ROOT="${ANDROID_SDK_ROOT:-/opt/homebrew/share/android-commandlinetools}"

ADB="${ANDROID_SDK_ROOT}/platform-tools/adb"
APK="${PROJECT_DIR}/app/build/outputs/apk/debug/app-debug.apk"

"${PROJECT_DIR}/scripts/build_debug.sh"
"${PROJECT_DIR}/scripts/wait_for_emulator.sh"
"${ADB}" install -r "${APK}"
"${ADB}" shell am start -W \
    -n "dev.mindw.dday.debug/dev.mindw.dday.MainActivity"
