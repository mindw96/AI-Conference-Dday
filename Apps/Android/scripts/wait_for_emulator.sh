#!/usr/bin/env bash

set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export ANDROID_SDK_ROOT="${ANDROID_SDK_ROOT:-/opt/homebrew/share/android-commandlinetools}"

ADB="${ANDROID_SDK_ROOT}/platform-tools/adb"
TIMEOUT_SECONDS="${DDAY_BOOT_TIMEOUT_SECONDS:-300}"
DEADLINE=$((SECONDS + TIMEOUT_SECONDS))
NEXT_STATUS_AT=0

echo "Waiting for Android to finish booting..."

while (( SECONDS < DEADLINE )); do
    device_state="$("${ADB}" get-state 2>/dev/null || true)"

    if [[ "${device_state}" == "device" ]]; then
        boot_completed="$("${ADB}" shell getprop sys.boot_completed 2>/dev/null | tr -d '\r' || true)"
        boot_animation="$("${ADB}" shell getprop init.svc.bootanim 2>/dev/null | tr -d '\r' || true)"
        package_service="$("${ADB}" shell service check package 2>/dev/null | tr -d '\r' || true)"

        if [[ "${boot_completed}" == "1" ]] \
            && [[ "${boot_animation}" == "stopped" ]] \
            && [[ "${package_service}" == *"found"* ]]; then
            "${ADB}" shell input keyevent 82 >/dev/null 2>&1 || true
            echo "Android is ready."
            exit 0
        fi
    else
        boot_completed=""
        boot_animation=""
        package_service=""
    fi

    elapsed=$((TIMEOUT_SECONDS - (DEADLINE - SECONDS)))
    if (( elapsed >= NEXT_STATUS_AT )); then
        echo "  ${elapsed}s: device=${device_state:-offline}, boot=${boot_completed:-pending}, package=${package_service:-pending}"
        NEXT_STATUS_AT=$((NEXT_STATUS_AT + 10))
    fi

    sleep 2
done

echo "Android did not become ready within ${TIMEOUT_SECONDS} seconds." >&2
echo "Try closing the emulator and run ./scripts/run_emulator.sh again." >&2
exit 1
