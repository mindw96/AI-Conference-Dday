#!/usr/bin/env bash

set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export ANDROID_SDK_ROOT="${ANDROID_SDK_ROOT:-/opt/homebrew/share/android-commandlinetools}"
export ANDROID_AVD_HOME="${ANDROID_AVD_HOME:-${HOME}/.android/avd}"

AVD_NAME="${DDAY_AVD_NAME:-Dday_API_36_1}"
SYSTEM_IMAGE="system-images;android-36.1;google_apis;arm64-v8a"

mkdir -p "${ANDROID_AVD_HOME}"

if "${ANDROID_SDK_ROOT}/emulator/emulator" -list-avds | grep -Fxq "${AVD_NAME}"; then
    echo "${AVD_NAME} already exists in ${ANDROID_AVD_HOME}."
else
    echo "no" | "${ANDROID_SDK_ROOT}/cmdline-tools/latest/bin/avdmanager" create avd \
        --name "${AVD_NAME}" \
        --package "${SYSTEM_IMAGE}" \
        --device "pixel_9_pro" \
        --path "${ANDROID_AVD_HOME}/${AVD_NAME}.avd" \
        --force

    echo "Created ${AVD_NAME} in ${ANDROID_AVD_HOME}."
fi

"${PROJECT_DIR}/scripts/configure_avd.sh"
