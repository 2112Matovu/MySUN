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
| `student_app/` | Student/staff mobile app — **includes Admin management**, not a separate app | Flutter + Riverpod + go_router | Functional end-to-end on mock data (auth, publishing, drafts, admin moderation) |
| `backend/` | REST API | Python 3.11 + FastAPI + **Supabase** (Postgres + Auth + Storage) | Scaffolded and verified to boot; not yet wired to a real Supabase project or to the Flutter app |

There is no separate `admin_portal/` — Super Admin and Minor Admin are an
extra tab inside `student_app/`, gated by role exactly like the Publisher
tab (see the spec's §2.1).

## Build order

1. ~~Student app on mock data~~ — done, UX proven end to end.
2. **Backend** (current) — FastAPI + Supabase, schema in
   `backend/supabase/migrations/`, endpoints in spec §9.
3. **Next:** create the Supabase project, then wire the student app's
   `Mock*Repository` classes to real HTTP calls against the backend
   (the repository interfaces were kept API-shaped from the start for
   exactly this swap).
4. iOS build, once Mac/Xcode access exists.

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
