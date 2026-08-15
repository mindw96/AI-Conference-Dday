#!/usr/bin/env bash

set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROJECT_CACHE_DIR="${DDAY_GRADLE_PROJECT_CACHE_DIR:-${GRADLE_USER_HOME:-${HOME}/.gradle}/dday-project-cache}"

mkdir -p "${PROJECT_CACHE_DIR}"
exec "${PROJECT_DIR}/gradlew" \
    --project-dir "${PROJECT_DIR}" \
    --project-cache-dir "${PROJECT_CACHE_DIR}" \
    "$@"
