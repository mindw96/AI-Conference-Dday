#!/usr/bin/env bash

set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export JAVA_HOME="${JAVA_HOME:-/opt/homebrew/opt/openjdk@21/libexec/openjdk.jdk/Contents/Home}"
export ANDROID_SDK_ROOT="${ANDROID_SDK_ROOT:-/opt/homebrew/share/android-commandlinetools}"

"${PROJECT_DIR}/scripts/sync_conference_data.sh"
"${PROJECT_DIR}/gradlew" \
    --project-dir "${PROJECT_DIR}" \
    clean \
    test \
    assembleDebug \
    bundleRelease

test -f "${PROJECT_DIR}/app/build/outputs/apk/debug/app-debug.apk"
test -f "${PROJECT_DIR}/app/build/outputs/bundle/release/app-release.aab"

echo "Debug APK and unsigned release-validation AAB built successfully."
