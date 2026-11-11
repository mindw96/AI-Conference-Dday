# Privacy

Dday is local-first and does not collect personal data from your use of the app.

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

## Apple Watch

When Apple Watch support is enabled, Dday sends the selected deadline information
from the iPhone to its paired Apple Watch using Apple's WatchConnectivity
framework. The Watch app and complications store this information locally. It is
not sent to a Dday server.

## Retention and deletion

Settings, selections, cached public conference data, and custom D-Days stay in
the app's local storage until you change or remove them. You can delete custom
D-Days in the app. To remove all local app data, use the operating system's app
data controls where available. On macOS, removing the application alone may
leave its settings or sandbox container; contact us for instructions for your
installation. Dday has no server-side copy of these app settings or deadlines.

Events you choose to add to Calendar are managed by your calendar app and can be
removed there. Removing Dday does not remove those calendar events.

## Network services and support

Public catalog downloads and links opened from Dday use GitHub or the selected
conference's website. Those services may receive normal network information,
such as an IP address, under their own privacy policies. See the
[GitHub Privacy Statement](https://docs.github.com/en/site-policy/privacy-policies/github-general-privacy-statement).

If you choose to contact support by email, we receive the email address and
information you include only to respond to your request. Please do not include
sensitive information that is unnecessary for support. Support correspondence is
retained as needed to resolve your request and follow-up questions. You can ask
us to delete your support correspondence using the contact address below.

Developer: Dongwook Min (민동욱)  
Privacy and support contact: jeff4043@naver.com

Last updated: November 11, 2026.
