#!/usr/bin/env bash

set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export ANDROID_SDK_ROOT="${ANDROID_SDK_ROOT:-/opt/homebrew/share/android-commandlinetools}"
export ANDROID_AVD_HOME="${ANDROID_AVD_HOME:-${PROJECT_DIR}/.android-avd}"

AVD_NAME="${DDAY_AVD_NAME:-Dday_API_36_1}"

"${PROJECT_DIR}/scripts/configure_avd.sh"

exec "${ANDROID_SDK_ROOT}/emulator/emulator" \
    -avd "${AVD_NAME}" \
    -gpu host \
    -no-snapshot \
    "$@"
