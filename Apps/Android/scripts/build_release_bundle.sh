#!/usr/bin/env bash

set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export JAVA_HOME="${JAVA_HOME:-/opt/homebrew/opt/openjdk@21/libexec/openjdk.jdk/Contents/Home}"
export ANDROID_SDK_ROOT="${ANDROID_SDK_ROOT:-/opt/homebrew/share/android-commandlinetools}"

PROPERTIES_PATH="${PROJECT_DIR}/keystore.properties"
BUNDLE_PATH="${PROJECT_DIR}/app/build/outputs/bundle/release/app-release.aab"
JARSIGNER="${JAVA_HOME}/bin/jarsigner"

if [[
    ! -f "${PROPERTIES_PATH}" &&
    (
        -z "${DDAY_ANDROID_STORE_FILE:-}" ||
        -z "${DDAY_ANDROID_KEY_ALIAS:-}"
    )
]]; then
    echo "Release signing is not configured." >&2
    echo "Run ./scripts/create_upload_keystore.sh or provide signing environment variables." >&2
    exit 1
fi

if [[ ! -x "${JARSIGNER}" ]]; then
    echo "jarsigner was not found at ${JARSIGNER}." >&2
    exit 1
fi

if [[ -z "${DDAY_ANDROID_STORE_PASSWORD:-}" ]]; then
    if [[ ! -t 0 ]]; then
        echo "Set DDAY_ANDROID_STORE_PASSWORD for a non-interactive build." >&2
        exit 1
    fi
    read -r -s -p "Upload keystore password: " DDAY_ANDROID_STORE_PASSWORD
    echo
fi

export DDAY_ANDROID_STORE_PASSWORD
export DDAY_ANDROID_KEY_PASSWORD="${DDAY_ANDROID_KEY_PASSWORD:-${DDAY_ANDROID_STORE_PASSWORD}}"
trap 'unset DDAY_ANDROID_STORE_PASSWORD DDAY_ANDROID_KEY_PASSWORD' EXIT

gradle_arguments=(
    --project-dir "${PROJECT_DIR}"
    clean
    test
    bundleRelease
)

if [[ -n "${DDAY_ANDROID_VERSION_CODE:-}" ]]; then
    gradle_arguments+=("-PddayVersionCode=${DDAY_ANDROID_VERSION_CODE}")
fi

if [[ -n "${DDAY_ANDROID_VERSION_NAME:-}" ]]; then
    gradle_arguments+=("-PddayVersionName=${DDAY_ANDROID_VERSION_NAME}")
fi

"${PROJECT_DIR}/scripts/sync_conference_data.sh"
"${PROJECT_DIR}/gradlew" "${gradle_arguments[@]}"

if [[ ! -f "${BUNDLE_PATH}" ]]; then
    echo "Expected bundle was not created at ${BUNDLE_PATH}." >&2
    exit 1
fi

verification_output="$(LANG=C "${JARSIGNER}" -verify "${BUNDLE_PATH}" 2>&1)"
if ! grep -q "jar verified\\." <<< "${verification_output}"; then
    echo "${verification_output}" >&2
    echo "The generated app bundle signature could not be verified." >&2
    exit 1
fi

shasum -a 256 "${BUNDLE_PATH}" > "${BUNDLE_PATH}.sha256"

echo
echo "Bundle signature verified."
echo "Signed Android App Bundle:"
echo "${BUNDLE_PATH}"
echo "SHA-256:"
cat "${BUNDLE_PATH}.sha256"
