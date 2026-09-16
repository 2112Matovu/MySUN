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

## Running in production (Docker)

```bash
docker compose up -d --build
```

This starts two containers: `api` (the FastAPI app, `--workers 2`, not
exposed directly) and `nginx` (reverse proxy on port 80). Requires a real
`.env` in this folder — `docker-compose.yml` loads it via `env_file`, and
force-sets `APP_ENV=production` regardless of what's in `.env`, which locks
CORS down to `CORS_ORIGINS` instead of `*`.

**Not included, add before exposing this publicly:** TLS termination
(`nginx/nginx.conf` is plain HTTP — put it behind certbot or a managed load
balancer) and a CI pipeline. Optional: set `SENTRY_DSN` in `.env` to get
error tracking; unset, it's a no-op.

Logs go to stdout as one JSON object per line (`app/core/logging.py`) —
request/response with a `request_id`, and unhandled exceptions with a full
traceback tagged with that same `request_id`. Every response also carries
an `X-Request-ID` header for correlating a client-reported issue to a log
line.

`/auth/login`, `/auth/signup`, `/auth/google` are rate-limited per client IP
(`app/core/limiter.py`, applied in `app/api/v1/auth.py`) — 8/minute for
login and Google sign-in, 5/minute for signup — to blunt brute-force and
credential-stuffing. A tripped limit returns `429`. Real client IPs behind
the bundled nginx are trusted via `--forwarded-allow-ips` in the
Dockerfile's `CMD`; running outside Docker (e.g. `uvicorn --reload`
directly) rate-limits by the direct connecting IP instead.

## Deploying to Render (free tier)

This is the actual "put the backend somewhere it stays running" step —
until this is done, the API only exists while `uvicorn` is running on a
dev machine. Render builds `Dockerfile` directly (not `docker-compose.yml`
— Render is its own reverse proxy and handles HTTPS itself, so the bundled
`nginx` sidecar isn't used here; it's still relevant for a self-hosted VM).

1. Push this repo to GitHub if you haven't (`git push`).
2. At [render.com](https://render.com), sign up (no card required for the
   free plan) → **New > Blueprint** → connect this GitHub repo. Render
   reads `render.yaml` and proposes a `mysun-api` web service — accept it.
3. Render will prompt for the env vars marked `sync: false` in
   `render.yaml` (not stored in git): paste in `SUPABASE_URL`,
   `SUPABASE_ANON_KEY`, `SUPABASE_SERVICE_ROLE_KEY` from your Supabase
   project's **Settings > API**, and optionally `SENTRY_DSN`.
4. Deploy. Render gives you a URL like `https://mysun-api.onrender.com`.
5. Update `CORS_ORIGINS` in the Render dashboard's env vars to include
   any real web origin you serve the app from (mobile doesn't need this —
   it authenticates with a Bearer token, not cookies).
6. Rebuild the Flutter app pointed at the real URL:
   `flutter build appbundle --release --dart-define=API_BASE_URL=https://mysun-api.onrender.com/api/v1`

**Free-tier tradeoff**: the service spins down after ~15 minutes with no
traffic, so the first request after a quiet period takes several seconds
to ~1 minute while it wakes back up. Fine for a campus app's usage
pattern; upgrade to a paid Render plan later if that cold start becomes a
problem.

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

## Google Sign-In setup

`POST /api/v1/auth/google` exchanges a Google ID token for a Supabase
session (`app/api/v1/auth.py`). The Flutter app gets that ID token via the
`google_sign_in` package (`student_app/lib/core/network/google_auth_service.dart`).
One-time setup, done outside this repo:

1. **Google Cloud Console** (console.cloud.google.com/apis/credentials):
   - Configure the OAuth consent screen if you haven't (External, app name
     "MySun", your support email).
   - Create Credentials → OAuth client ID → **Web application**.
   - Authorized JavaScript origins: `http://localhost:5000` (the Flutter web
     dev server port) — add your real domain later too.
   - Authorized redirect URIs: `https://<your-project-ref>.supabase.co/auth/v1/callback`
     (Supabase asks for this even though the ID-token flow doesn't redirect).
   - Save, then copy the generated **Client ID** (`....apps.googleusercontent.com`)
     and **Client Secret**.
2. **Supabase dashboard** → Authentication → Providers → Google → Enable,
   paste in that Client ID and Client Secret, Save.
3. **Flutter app**: paste the same Client ID into
   `student_app/lib/core/network/google_config.dart` (`googleWebClientId`).
   Used on every platform — web via `GoogleSignIn.clientId`, Android via
   `GoogleSignIn.serverClientId` (so the ID token's audience matches what
   Supabase expects regardless of platform).

Android specifically needs one more registration before Google Sign-In
works on a real device/emulator: an **Android** OAuth client in the same
Google Cloud project, tied to the app's package name
(`ug.ac.sorotiu.mysun_app`) and its debug/release SHA-1 signing
fingerprint (`cd student_app/android && ./gradlew signingReport`). Web
doesn't need this — only the Web client ID above.

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
