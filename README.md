# MySun — Soroti University Campus Companion

Monorepo for the MySun system. Full product/engineering spec:
[`MySun_Integrated_Final_Specification.md`](./MySun_Integrated_Final_Specification.md)
(supersedes the original `MySun_Complete_Software_Specification.md` — the
integrated doc is kept up to date with what's actually built; read its
inline "as actually built" notes for where it deviates from the original
plan).

## Components

| Folder | Component | Stack | Status |
|---|---|---|---|
| `student_app/` | Student/staff mobile app — **includes Admin management**, not a separate app | Flutter + Riverpod + go_router | Wired to the live backend: auth, publishing (with photo uploads and scheduling), drafts, admin moderation, search, ratings and boda bookings, campus services, push notifications |
| `backend/` | REST API | Python 3.11 + FastAPI + **Supabase** (Postgres + Auth + Storage), served by `uvicorn`, containerized with Docker | Live end-to-end against a real Supabase project and wired into the Flutter app; push via Firebase Cloud Messaging; deployable to **Render** (free tier) via `backend/render.yaml` |

There is no separate `admin_portal/` — Super Admin and Minor Admin are an
extra tab inside `student_app/`, gated by role exactly like the Publisher
tab (see the spec's §2.1).

## Build order

1. ~~Student app on mock data~~ — done, UX proven end to end.
2. ~~Backend~~ — FastAPI + Supabase, schema in
   `backend/supabase/migrations/`, endpoints in spec §9. Live and wired
   to the app.
3. ~~Wire the student app's `Mock*Repository` classes to real HTTP
   calls~~ — done; `Http*Repository` implementations are the default.
4. ~~Production hardening~~ — Docker, logging, rate limits, secure token
   storage, release signing, real photo uploads (Supabase Storage).
5. ~~Feature round~~ — event registration, ratings and boda bookings,
   campus services, search, scheduled posting, event reminders, and push
   notifications via Firebase Cloud Messaging.
6. **Current:** testing push on a real device through a tunnel, then
   deploying the backend permanently (Render free tier — scaffolded in
   `backend/render.yaml`, not yet deployed; set
   `FCM_SERVICE_ACCOUNT_JSON` there too). Open code-review items: see
   "Known issues" in `backend/README.md`.
7. iOS build, once Mac/Xcode access exists.

## Push notifications (Firebase) — setup summary

Firebase project `mysun-5cede`, Android package `ug.ac.sorotiu.mysun_app`.
Two credentials, both git-ignored, never commit them:

- `backend/fcm-service-account.json` (service-account key) — referenced by
  `FCM_SERVICE_ACCOUNT_JSON` in `backend/.env`. On Render, paste the JSON
  contents into that env var instead.
- `student_app/android/app/google-services.json` — used by the
  `com.google.gms.google-services` Gradle plugin.

## Student app — quick start

```powershell
cd student_app
flutter pub get
flutter run
```

See [`student_app/README.md`](./student_app/README.md) for the full layout.

## Backend — quick start

```powershell
cd backend
python -m venv .venv
.venv\Scripts\activate
pip install -r requirements.txt
copy .env.example .env   # then fill in your Supabase project's keys
uvicorn app.main:app --reload --port 8000
```

See [`backend/README.md`](./backend/README.md) for Supabase setup and
architecture notes.
