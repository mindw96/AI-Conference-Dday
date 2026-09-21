#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MODE="${1:-run}"
case "$MODE" in
  run|--verify|--debug|--logs|--telemetry) ;;
  *) echo "usage: $0 [--verify|--debug|--logs|--telemetry]" >&2; exit 2 ;;
esac

APP_BUNDLE="${DDAY_APP_DIR:-$ROOT_DIR/build/Dday.app}"
DDAY_APP_DIR="$APP_BUNDLE" "$ROOT_DIR/scripts/build_app.sh"
# Only replace the running app after the new build succeeds.
pkill -x Dday >/dev/null 2>&1 || true

if [[ "$MODE" == --debug ]]; then
  exec lldb -- "$APP_BUNDLE/Contents/MacOS/Dday"
fi
if [[ "$MODE" == --verify ]]; then
  # Keep automatic updating out of the local launch check without changing
  # the user's saved Sparkle preferences.
  /usr/bin/open -n "$APP_BUNDLE" --args -SUEnableAutomaticChecks NO -SUAutomaticallyUpdate NO
else
  /usr/bin/open -n "$APP_BUNDLE"
fi
case "$MODE" in
  --verify)
    for attempt in 1 2 3 4 5; do
      if pgrep -f "^$APP_BUNDLE/Contents/MacOS/Dday([[:space:]]|$)" >/dev/null; then
        echo "Launched $APP_BUNDLE"
        exit 0
      fi
      sleep 1
    done
    echo "Dday did not stay running." >&2
    exit 1
    ;;
  --logs)
    exec /usr/bin/log stream --info --style compact --predicate 'process == "Dday"'
    ;;
  --telemetry)
    exec /usr/bin/log stream --info --style compact --predicate 'subsystem == "dev.mindw.Dday"'
    ;;
esac
