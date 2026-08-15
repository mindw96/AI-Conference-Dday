# Privacy

Dday is local-first and does not collect personal data.

- No account is required.
- No analytics are collected.
- No advertising SDK is included.
- No tracking is used.
- User settings are stored locally with `UserDefaults` on Apple platforms and
  `SharedPreferences` on Android.
- Custom D-Days are stored locally on the device.
- Selected conference settings are stored locally on the device.
- On iPhone and iPad, optional deadline reminders are scheduled locally through
  the system notification service. Dday does not use a notification server.
- When the user chooses to add a deadline or conference period to Calendar,
  Dday passes only that selected event to the system calendar interface. Dday
  does not read existing calendar events, and calendar data is not sent
  anywhere.

The app can manually fetch the latest public conference list from this project's
GitHub repository when the user chooses `Check Conference List Updates`. That
request downloads public JSON data only. Dday does not send custom D-Days,
selected deadlines, user settings, device identifiers, or account information as
part of that request.

Apple widgets read the selected D-Day through the local App Group container.
The Android Home Screen widget reads the same selection from app-private
`SharedPreferences`. Widget data remains on the device.
