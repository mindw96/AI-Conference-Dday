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
All project scripts keep Gradle's project cache outside the repository at
`~/.gradle/dday-project-cache`, which prevents cloud-storage placeholders under
`Documents` from breaking builds. Set `DDAY_GRADLE_PROJECT_CACHE_DIR` to use a
different local cache path.

## Play Internal Testing

The release build defaults to Android version `1.0.0` with version code `1`.
The project targets API 37, which satisfies Google Play's API 36 requirement
that takes effect on August 31, 2026.

Create the local upload key once:

```bash
./scripts/create_upload_keystore.sh
```

The private key is written under the repository's ignored `private/android/`
directory. `keystore.properties` contains only its path and alias; the password
is requested at build time and is never committed.

Back up the `.jks` file and its password separately. Google Play can reset an
upload key after Play App Signing is enabled, but keeping a verified backup is
still important.

Build the signed Android App Bundle:

```bash
./scripts/build_release_bundle.sh
```

The signed bundle and its SHA-256 file are generated at:

```text
app/build/outputs/bundle/release/app-release.aab
app/build/outputs/bundle/release/app-release.aab.sha256
```

For later uploads, increment the version code:

```bash
DDAY_ANDROID_VERSION_CODE=2 \
DDAY_ANDROID_VERSION_NAME=1.0.1 \
./scripts/build_release_bundle.sh
```

Use Play App Signing when creating the first Play Console release. Google keeps
the app-signing key, while the local Dday key remains the separate upload key.
CI builds an unsigned release AAB only to verify the optimized release variant;
publishable bundles must come from `build_release_bundle.sh`.

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

Gradle runs `syncConferenceData` before every build and copies the repository's
canonical `data/conferences.json` into the Android assets directory. The
`scripts/sync_conference_data.sh` helper remains available for an explicit
manual sync. The app can also refresh the data from the shared HTTPS feed when
the user asks it to.
