#!/usr/bin/env bash

set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REPOSITORY_DIR="$(cd "${PROJECT_DIR}/../.." && pwd)"
SOURCE="${REPOSITORY_DIR}/data/conferences.json"
DESTINATION="${PROJECT_DIR}/app/src/main/assets/conferences.json"

if [[ ! -f "${SOURCE}" ]]; then
    echo "Conference data was not found at ${SOURCE}." >&2
    exit 1
fi

cp "${SOURCE}" "${DESTINATION}"
echo "Synced ${SOURCE} to ${DESTINATION}."
