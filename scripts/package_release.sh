#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 1 ]]; then
  echo "Usage: $0 <release-tag>" >&2
  exit 64
fi

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TAG="$1"
APP_DIR="${DDAY_APP_DIR:-$ROOT/build/Dday.app}"
DIST_DIR="$ROOT/dist"
WORK_ROOT="$(mktemp -d /private/tmp/dday-package.XXXXXX)"
DMG_ROOT="$WORK_ROOT/dmg-root"
RW_DMG="$WORK_ROOT/Dday-${TAG}-rw.dmg"
MOUNT_DIR=""
ATTACH_PLIST="$WORK_ROOT/Dday-${TAG}-attach.plist"
DMG_PATH="$DIST_DIR/Dday-${TAG}.dmg"
ZIP_PATH="$DIST_DIR/Dday-${TAG}.zip"
BACKGROUND_PATH="$DMG_ROOT/.background/dmg-background.png"

export COPYFILE_DISABLE=1

if [[ ! -d "$APP_DIR" ]]; then
  echo "Missing app bundle: $APP_DIR" >&2
  echo "Run ./scripts/build_app.sh first." >&2
  exit 66
fi

mkdir -p "$DIST_DIR"
rm -f "$ZIP_PATH" \
      "$ZIP_PATH.sha256" \
      "$DMG_PATH" \
      "$DMG_PATH.sha256" \
      "$RW_DMG"

ditto --norsrc -c -k --keepParent "$APP_DIR" "$ZIP_PATH"

rm -rf "$DMG_ROOT" "$ATTACH_PLIST"
mkdir -p "$DMG_ROOT/.background"
ditto --norsrc "$APP_DIR" "$DMG_ROOT/Dday.app"
ln -s /Applications "$DMG_ROOT/Applications"
swift "$ROOT/scripts/generate_dmg_background.swift" "$BACKGROUND_PATH"
SetFile -a V "$DMG_ROOT/.background" || true

hdiutil create \
  -volname "Dday" \
  -fs HFS+ \
  -srcfolder "$DMG_ROOT" \
  -ov \
  -format UDRW \
  "$RW_DMG"

ATTACH_OUTPUT="$(hdiutil attach "$RW_DMG" \
  -nobrowse \
  -readwrite \
  -plist)"
printf "%s\n" "$ATTACH_OUTPUT" > "$ATTACH_PLIST"
MOUNT_DIR="$(awk '
  /<key>mount-point<\/key>/ {
    getline
    gsub(/^[[:space:]]*<string>/, "")
    gsub(/<\/string>[[:space:]]*$/, "")
    print
    exit
  }
' "$ATTACH_PLIST")"

if [[ -z "$MOUNT_DIR" || ! -d "$MOUNT_DIR" ]]; then
  echo "Could not resolve mounted DMG path." >&2
  exit 67
fi

cleanup() {
  if [[ -n "$MOUNT_DIR" ]]; then
    hdiutil detach "$MOUNT_DIR" -quiet || true
  fi
  rm -rf "$WORK_ROOT"
}
trap cleanup EXIT

sleep 1
osascript \
  -e "set dmgFolder to POSIX file \"$MOUNT_DIR\" as alias" \
  -e 'tell application "Finder" to open dmgFolder' >/dev/null
sleep 1
osascript \
  -e "set dmgFolder to POSIX file \"$MOUNT_DIR\" as alias" \
  -e 'tell application "Finder"' \
  -e 'set theWindow to container window of dmgFolder' \
  -e 'set current view of theWindow to icon view' \
  -e 'try' \
  -e 'set toolbar visible of theWindow to false' \
  -e 'end try' \
  -e 'try' \
  -e 'set statusbar visible of theWindow to false' \
  -e 'end try' \
  -e 'set bounds of theWindow to {100, 100, 860, 580}' \
  -e 'end tell' >/dev/null
osascript \
  -e "set dmgFolder to POSIX file \"$MOUNT_DIR\" as alias" \
  -e 'tell application "Finder"' \
  -e 'set theOptions to icon view options of container window of dmgFolder' \
  -e 'set arrangement of theOptions to not arranged' \
  -e 'set icon size of theOptions to 112' \
  -e 'set background picture of theOptions to file ".background:dmg-background.png" of dmgFolder' \
  -e 'set position of item "Dday.app" of dmgFolder to {190, 222}' \
  -e 'set position of item "Applications" of dmgFolder to {570, 222}' \
  -e 'update dmgFolder' \
  -e 'end tell' >/dev/null
osascript \
  -e "set dmgFolder to POSIX file \"$MOUNT_DIR\" as alias" \
  -e 'tell application "Finder"' \
  -e 'set theWindow to container window of dmgFolder' \
  -e 'close theWindow' \
  -e 'end tell' >/dev/null

sleep 1

for _ in {1..20}; do
  [[ -f "$MOUNT_DIR/.DS_Store" ]] && break
  sleep 0.5
done

if [[ ! -f "$MOUNT_DIR/.DS_Store" ]]; then
  echo "Finder did not write .DS_Store for the DMG layout." >&2
  exit 67
fi

if ! strings "$MOUNT_DIR/.DS_Store" | grep -Fq "dmg-background.png"; then
  echo "Finder did not persist the DMG background image setting." >&2
  exit 67
fi

sync
hdiutil detach "$MOUNT_DIR" -quiet
trap - EXIT
MOUNT_DIR=""

hdiutil convert "$RW_DMG" \
  -format UDZO \
  -imagekey zlib-level=9 \
  -o "$DMG_PATH"

rm -f "$RW_DMG"
rm -rf "$WORK_ROOT"

shasum -a 256 "$ZIP_PATH" > "$ZIP_PATH.sha256"
shasum -a 256 "$DMG_PATH" > "$DMG_PATH.sha256"
