# Dday Android

Jetpack Compose client for AI Conference Dday. It follows the iPhone/iPad
information architecture and reads the same public conference JSON contract.

## Included

- Home, Conferences, Custom D-Day, and Settings tabs
- User-selected main D-Day and multi-category filtering
- AoE-to-local-time conversion with D/H/M countdowns
- Conference and custom deadline calendar intents
- Manual conference-list refresh with HTTPS and 5 MB safeguards
- Korean, English, and system-language modes
- Resizable home-screen widget with 30-minute fallback updates and immediate
  refreshes after date, time, time-zone, or locale changes
- Widget background and text-color choices matching the iOS settings

## Build

```bash
./scripts/build_debug.sh
```

The debug APK is generated at `app/build/outputs/apk/debug/app-debug.apk`.

## Project Emulator

Create the Pixel 9 Pro Android 16 virtual device once:

```bash
./scripts/create_avd.sh
```

Then start it:

```bash
./scripts/run_emulator.sh
```

In a second terminal, build, install, and launch Dday:

```bash
./scripts/install_debug.sh
```

The install script waits for Android, System UI, and Package Manager to finish
booting, so it is safe to run while the emulator is still starting.

The AVD is named `Dday_API_36_1` and is stored in the ignored
`.android-avd/` directory so it does not affect other Android projects. The
launcher also enables Apple Silicon host GPU acceleration for a faster and more
stable System UI.

## Conference Data

`scripts/sync_conference_data.sh` copies the repository's canonical
`data/conferences.json` into the Android assets directory. The app can also
refresh that file from the shared HTTPS feed when the user asks it to.
