#!/usr/bin/env python3
"""Validate release requirements in the built iOS app, not just project settings."""
import argparse
import plistlib
from pathlib import Path


def require(condition, message):
    if not condition:
        raise SystemExit(f"FAIL: {message}")


def read_plist(path):
    require(path.is_file(), f"Missing {path}")
    with path.open("rb") as stream:
        return plistlib.load(stream)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("app", type=Path, help="Built DdayMobile.app")
    app = parser.parse_args().app
    info = read_plist(app / "Info.plist")
    require(any(key in info for key in (
        "UILaunchScreen", "UILaunchScreens", "UILaunchStoryboardName", "UILaunchStoryboards"
    )), "The iOS 27 SDK requires a launch screen")
    require(isinstance(info.get("UIApplicationSceneManifest"), dict),
            "The app must declare its scene-based life cycle")
    require(bool(info.get("NSCalendarsWriteOnlyAccessUsageDescription")),
            "Calendar writes require a usage description")

    extension = app / "PlugIns/DdayWidgets.appex"
    widget = read_plist(extension / "Info.plist")
    for key in ("CFBundleVersion", "CFBundleShortVersionString"):
        require(info.get(key) and info[key] == widget.get(key),
                f"App and widget {key} must match")
    require(widget.get("NSExtension", {}).get("NSExtensionPointIdentifier") == "com.apple.widgetkit-extension",
            "WidgetKit extension metadata must be present")
    for bundle in (app, extension):
        privacy = read_plist(bundle / "PrivacyInfo.xcprivacy")
        defaults = next((entry for entry in privacy.get("NSPrivacyAccessedAPITypes", [])
                         if entry.get("NSPrivacyAccessedAPIType") == "NSPrivacyAccessedAPICategoryUserDefaults"), {})
        require({"CA92.1", "1C8F.1"}.issubset(defaults.get("NSPrivacyAccessedAPITypeReasons", [])),
                f"{bundle.name} must declare local and App Group defaults access")
        require(privacy.get("NSPrivacyTracking") is False,
                f"{bundle.name} must preserve Dday's no-tracking declaration")
    print(f"PASS: iOS bundle launch, scenes, calendar, widget versions and privacy; SDK={info.get('DTSDKName')}")


if __name__ == "__main__":
    main()
