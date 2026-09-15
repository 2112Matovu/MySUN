# MySun Backend

FastAPI backend for MySun, built on **Supabase** for Postgres, Auth, and
Storage. Mirrors the Flutter app's mock repositories field-for-field — see
`student_app/lib/data/models/*.dart` and
`../MySun_Integrated_Final_Specification.md`.

## Setup

1. Create a project at [supabase.com](https://supabase.com).
2. In the SQL Editor, run `supabase/migrations/0001_init.sql` (or install
   the [Supabase CLI](https://supabase.com/docs/guides/cli) and run
   `supabase db push` from this folder).
3. Copy `.env.example` to `.env` and fill in three values from
   **Project Settings > API**: URL, the client-safe key (called "anon" on
   older projects, "publishable" on newer ones), and the privileged
   server-only key ("service_role" / "secret"). No JWT secret needed —
   see Architecture below.
4. Install dependencies and run:

```bash
python -m venv .venv
.venv\Scripts\activate        # Windows
pip install -r requirements.txt
uvicorn app.main:app --reload --port 8000
```

5. Open `http://localhost:8000/docs` for the interactive API docs, and
   `http://localhost:8000/health` to confirm it's up.

## Architecture

- **Supabase Postgres** — schema in `supabase/migrations/`. Row Level
  Security is enabled as defence-in-depth, but the real authorization logic
  (role checks, "can this publisher remove this listing") lives in
  `app/core/security.py` and the route layer, using the service-role key.
- **Supabase Auth** — `POST /api/v1/auth/signup` and `/login` proxy to
  Supabase Auth and return its JWT. Every other endpoint validates that
  JWT by calling Supabase Auth's own `/auth/v1/user` endpoint
  (`admin.auth.get_user(token)` in `app/core/security.py`) rather than
  decoding it locally against a shared secret — this works regardless of
  whether the project uses a legacy shared JWT secret or newer per-project
  signing keys, so there's nothing extra to configure. New accounts always
  start as `student`; only a Super Admin can promote via
  `PATCH /api/v1/admin/users/{id}/role`.
- **Supabase Storage** — not yet wired into any endpoint (the Flutter app's
  image fields currently take a public URL directly, matching its mock
  `picsum.photos` seed data). Add a bucket and an upload endpoint when real
  photo uploads are needed.

## Key behavior notes

- **Publishing is immediate.** There is no pre-approval gate — creating an
  announcement/event/accommodation listing/boda rider makes it live right
  away. Admins (`admin`, `minor_admin`) can only **remove** content that
  breaks the terms of service (`POST /api/v1/admin/moderation/{id}/remove`);
  there is no separate "approve" step.
- **Publishers can remove their own content** via the content type's own
  `DELETE` endpoint (e.g. `DELETE /api/v1/transport/{id}`) — this is
  separate from admin moderation and doesn't require a reason.
- **Drafts** save the full form (`form_data`, jsonb) so the Flutter app can
  resume editing exactly where it left off.
- **Roles**: `student`, `publisher`, `admin` (Super Admin), `minor_admin`.
  A Minor Admin can review/remove content but not manage users, view
  analytics, or appoint other admins — enforced via `require_super_admin`
  vs. `require_admin_level` in `app/core/security.py`.
