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

## Swapping in the backend

Implement `Http*Repository` classes against the interfaces in
`lib/data/repositories/`, then change the four providers in
`lib/providers/repositories.dart`. Nothing above that layer changes.
