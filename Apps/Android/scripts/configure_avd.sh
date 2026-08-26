#!/usr/bin/env bash

set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export ANDROID_AVD_HOME="${ANDROID_AVD_HOME:-${HOME}/.android/avd}"

AVD_NAME="${DDAY_AVD_NAME:-Dday_API_36_1}"
CONFIG_PATH="${ANDROID_AVD_HOME}/${AVD_NAME}.avd/config.ini"

if [[ ! -f "${CONFIG_PATH}" ]]; then
    echo "AVD configuration was not found at ${CONFIG_PATH}." >&2
    echo "Run ./scripts/create_avd.sh first." >&2
    exit 1
fi

set_avd_option() {
    local key="$1"
    local value="$2"
    local temporary_path

    temporary_path="$(mktemp "${CONFIG_PATH}.tmp.XXXXXX")"
    awk -F= -v key="${key}" -v value="${value}" '
        BEGIN { updated = 0 }
        $1 == key {
            print key "=" value
            updated = 1
            next
        }
        { print }
        END {
            if (!updated) {
                print key "=" value
            }
        }
    ' "${CONFIG_PATH}" > "${temporary_path}"
    mv "${temporary_path}" "${CONFIG_PATH}"
}

# The default Pixel profile disables host GPU acceleration, which can make
# System UI unresponsive during the first boot on Apple Silicon.
set_avd_option "hw.gpu.enabled" "yes"
set_avd_option "hw.gpu.mode" "host"
set_avd_option "hw.cpu.ncore" "4"
set_avd_option "hw.ramSize" "4096"
set_avd_option "vm.heapSize" "512"

echo "Configured ${AVD_NAME} for Apple Silicon host acceleration."
