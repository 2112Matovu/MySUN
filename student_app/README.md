# MySun — Student App

Flutter mobile client for the MySun campus companion (Soroti University).
Currently runs entirely on **mock data** — no backend required. The data layer
is shaped to match the REST contract in
`../MySun_Complete_Software_Specification.md` so wiring in the FastAPI backend is
a drop-in swap at `lib/providers/repositories.dart`.

## Stack

| Concern | Choice |
|---|---|
| State | Riverpod 2 (`Notifier` / `AsyncNotifier` / `FutureProvider`) |
| Navigation | go_router (`StatefulShellRoute` for the bottom nav) |
| Theming | Material 3, single seed colour, light + dark |
| Local storage | `shared_preferences` (settings, bookmarks); Hive initialised for future offline cache |
| Networking | `dio` (added, unused until the backend is live) |
| Images | `cached_network_image` with a graceful category-tinted fallback |

## First run

This folder was hand-authored. Generate the platform folders once, then fetch
packages:

```powershell
cd student_app
flutter create --project-name mysun_app --org ug.ac.sorotiu .
flutter pub get
flutter run
```

`flutter create` will not overwrite anything already in `lib/`, `test/`,
`pubspec.yaml`, or `README.md`.

## Layout

```
lib/
  app.dart                 MaterialApp.router + theme wiring
  main.dart                bootstrap (Hive + SharedPreferences)
  core/
    constants/             categories, app constants
    router/app_router.dart  routes + shell
    theme/                 colours + Material 3 theme
    utils/date_fmt.dart    relative time, countdowns, day labels
  data/
    models/                Announcement, Event, TransportProvider, BusSchedule,
                           AppNotification, UserProfile (with fromJson/toJson)
    mock/mock_data.dart    seed content, dates relative to "now"
    repositories/          abstract interface + Mock* implementation per domain
  providers/               Riverpod providers (one file per domain) + repo wiring
  widgets/                 shared cards, chips, state views, image box
  features/
    splash/ home/ announcements/ events/ transport/ saved/
    notifications/ profile/ search/ shell/
```

## Screens

Splash → Home feed (greeting, quick-status row, category filter, announcement
feed, pull-to-refresh) → Announcement detail. Events (search + date/category
filters) → Event detail (countdown, capacity, reminder toggle, add-to-calendar
stub). Transport (next-bus card, provider directory, call stub) → Bus schedule.
Saved (News / Events tabs). Alerts (mark read, swipe to dismiss, deep links).
Profile & settings (theme, notification toggles, followed categories). Global
search across all three content types.

## Backend URL

The API address is baked in at build time. Development builds default to
`http://127.0.0.1:8000/api/v1` (the local backend — on a USB-connected
Android device run `adb reverse tcp:8000 tcp:8000` first), so `flutter run`
needs no extra flags. Release builds **must** pass it explicitly, or the app
throws on startup rather than shipping pointed at localhost:

```bash
flutter build appbundle --release --dart-define=API_BASE_URL=https://api.example.ug/api/v1
```

Use `https` in production — Android blocks plain-`http` traffic in release
builds by default.

## Release signing

`flutter build appbundle`/`apk --release` needs `android/key.properties`
(gitignored — never commit it or the `.jks` it points to). A keystore
already exists locally at `android/app/upload-keystore.jks` with matching
`android/key.properties`; back both up somewhere safe outside this repo —
**losing the keystore means you can never publish an update to the same
Play Store listing again**, there's no recovery. Without `key.properties`
present, `android/app/build.gradle.kts` falls back to debug-signing the
release build type so `flutter run --release` still works for local
testing, but that build must never be uploaded to the Play Store.

To generate a new one from scratch (e.g. on another machine):

```bash
keytool -genkeypair -v -keystore android/app/upload-keystore.jks \
  -alias mysun_upload -keyalg RSA -keysize 2048 -validity 10000
```

Then fill in `android/key.properties` from `android/key.properties.example`
(`keytool` on modern JDKs creates a PKCS12 keystore, which requires
`storePassword` and `keyPassword` to be identical).

## Swapping in the backend

Implement `Http*Repository` classes against the interfaces in
`lib/data/repositories/`, then change the four providers in
`lib/providers/repositories.dart`. Nothing above that layer changes.
