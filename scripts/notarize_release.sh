#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 1 ]]; then
  echo "Usage: $0 <release-tag>" >&2
  exit 64
fi

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TAG="$1"
VERSION="${TAG#v}"
DIST_DIR="$ROOT/dist"
DMG_PATH="$DIST_DIR/Dday-${TAG}.dmg"
ZIP_PATH="$DIST_DIR/Dday-${TAG}.zip"
NOTARY_ZIP="$ROOT/build/Dday-${TAG}-notary.zip"
RELEASE_ROOT="$(mktemp -d /private/tmp/dday-release.XXXXXX)"
APP_DIR="$RELEASE_ROOT/Dday.app"

SIGN_IDENTITY="${MACOS_SIGN_IDENTITY:-${SIGN_IDENTITY:-Developer ID Application}}"
NOTARY_PROFILE="${NOTARYTOOL_PROFILE:-DdayNotary}"

cleanup() {
  rm -rf "$RELEASE_ROOT"
}
trap cleanup EXIT

cd "$ROOT"

if ! security find-identity -p codesigning -v | grep -Fq "$SIGN_IDENTITY"; then
  echo "Missing signing identity matching: $SIGN_IDENTITY" >&2
  echo "Create or install a Developer ID Application certificate first." >&2
  exit 65
fi

DDAY_APP_DIR="$APP_DIR" APP_VERSION="$VERSION" MACOS_SIGN_IDENTITY="$SIGN_IDENTITY" ./scripts/build_app.sh
codesign --verify --deep --strict --verbose=2 "$APP_DIR"
spctl -a -vv "$APP_DIR" || true

rm -f "$NOTARY_ZIP"
ditto --norsrc -c -k --keepParent "$APP_DIR" "$NOTARY_ZIP"
xcrun notarytool submit "$NOTARY_ZIP" \
  --keychain-profile "$NOTARY_PROFILE" \
  --wait
xcrun stapler staple "$APP_DIR"
xcrun stapler validate "$APP_DIR"

DDAY_APP_DIR="$APP_DIR" ./scripts/package_release.sh "$TAG"

codesign --force --timestamp --sign "$SIGN_IDENTITY" "$DMG_PATH"
xcrun notarytool submit "$DMG_PATH" \
  --keychain-profile "$NOTARY_PROFILE" \
  --wait
xcrun stapler staple "$DMG_PATH"
xcrun stapler validate "$DMG_PATH"

shasum -a 256 "$ZIP_PATH" > "$ZIP_PATH.sha256"
shasum -a 256 "$DMG_PATH" > "$DMG_PATH.sha256"

if [[ "${SKIP_SPARKLE_APPCAST:-0}" != "1" ]]; then
  ./scripts/generate_sparkle_appcast.sh "$TAG"
fi

echo "Notarized release artifacts:"
echo "  $DMG_PATH"
echo "  $ZIP_PATH"
if [[ -f "$DIST_DIR/appcast.xml" ]]; then
  echo "  $DIST_DIR/appcast.xml"
fi
