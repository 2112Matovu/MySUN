# MySun Backend

FastAPI backend for MySun, built on **Supabase** for Postgres, Auth, and
Storage. Mirrors the Flutter app's mock repositories field-for-field — see
`student_app/lib/data/models/*.dart` and
`../MySun_Integrated_Final_Specification.md`.

## Setup

1. Create a project at [supabase.com](https://supabase.com).
2. In the SQL Editor, run every file in `supabase/migrations/` in order
   (`0001_init.sql` through `0006_audit_usage.sql`), or install
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

## Deploying to your own Python server (venv + systemd + nginx)

For any Linux server (VPS, or a panel host such as CloudPanel) where the
backend runs as a normal Python process in a virtual environment, with nginx
in front for HTTPS. Commands assume Ubuntu/Debian.

**Before you start**
- Python 3.12 or newer, a domain pointing at the server, and sudo access.
- **Run every Supabase migration first**, `supabase/migrations/0001` to
  `0006`, in order, in the Supabase **SQL Editor**. A missing migration shows
  up as HTTP 500 on data routes and a log line like
  `column announcements.publish_at does not exist` (that one is `0005`). The
  files are not safe to run twice, so check what exists before re-running.

**1. Prepare the server**
```
sudo apt update && sudo apt install -y python3-venv python3-pip git nginx
sudo adduser --disabled-password --gecos "" mysun
sudo -iu mysun
```

**2. Get the code and create the venv**
```
git clone https://github.com/2112Matovu/MySUN.git
cd MySUN/backend
python3 -m venv venv
venv/bin/pip install -r requirements.txt gunicorn
```

**3. Create `.env`** (never commit it)
```
cp .env.example .env && nano .env && chmod 600 .env
```
Set `APP_ENV=production`, `SUPABASE_URL`, `SUPABASE_ANON_KEY`,
`SUPABASE_SERVICE_ROLE_KEY`, `CORS_ORIGINS=https://<your-domain>`,
`CRON_SECRET` (a long random string) and `ADMIN_REQUIRE_2FA=false`.
`FCM_SERVICE_ACCOUNT_JSON` is optional (no push notifications without it).

**4. Try it by hand**
```
venv/bin/uvicorn app.main:app --host 127.0.0.1 --port 8090
curl http://127.0.0.1:8090/health      # {"status":"ok",...}
```

**5. Keep it running with systemd.** As a sudo user, create
`/etc/systemd/system/mysun.service`:
```
[Unit]
Description=MySun API
After=network.target

[Service]
User=mysun
WorkingDirectory=/home/mysun/MySUN/backend
ExecStart=/home/mysun/MySUN/backend/venv/bin/gunicorn app.main:app -k uvicorn.workers.UvicornWorker -w 2 -b 127.0.0.1:8090 --forwarded-allow-ips=127.0.0.1
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
```
```
sudo systemctl daemon-reload && sudo systemctl enable --now mysun
journalctl -u mysun -f          # logs
```

**6. nginx** (`/etc/nginx/sites-available/mysun`, then symlink into
`sites-enabled`, `sudo nginx -t && sudo systemctl reload nginx`):
```
server {
    listen 80;
    server_name api.yourdomain.com;
    location / {
        proxy_pass http://127.0.0.1:8090;
        proxy_set_header Host $host;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

**7. HTTPS and firewall**
```
sudo apt install -y certbot python3-certbot-nginx
sudo certbot --nginx -d api.yourdomain.com
sudo ufw allow OpenSSH && sudo ufw allow 'Nginx Full' && sudo ufw enable
```
Check `https://api.yourdomain.com/health`. Port 8090 stays closed to the
outside; only nginx talks to it.

**8. Scheduled jobs** (`crontab -e` as the `mysun` user)
```
*/5 * * * * curl -s -X POST -H "X-Cron-Secret: YOUR_SECRET" https://api.yourdomain.com/api/v1/internal/run-reminders
0 3 1 * * curl -s -X POST -H "X-Cron-Secret: YOUR_SECRET" https://api.yourdomain.com/api/v1/internal/purge-inactive
```

**9. Update later**
```
cd ~/MySUN && git pull && cd backend
venv/bin/pip install -r requirements.txt
sudo systemctl restart mysun
```

**10. Point the app at it**
```
flutter build apk --release --dart-define=API_BASE_URL=https://api.yourdomain.com/api/v1
```
The URL must end in `/api/v1`.

### Panel hosts with no SSH (CloudPanel and similar)

If the only way to run commands is the panel's **Cron Jobs** tab, upload
`app/`, `requirements.txt`, `start.sh` and your `.env` into one folder
(File Manager), set the site's **App Port** to `8090` in the panel's Python
settings, and add one cron job, every minute:
```
sh /path/to/that/folder/start.sh
```
`start.sh` installs the libraries once (log: `setup.log`), then starts the
API on port 8090 and restarts it if it stops (log: `run.log`). Keep the job
in place; it is what keeps the API alive.

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
- **Supabase Storage** — `POST /api/v1/uploads` stores publisher photos in
  a bucket and returns the public URL; every publishing form in the app
  uses it.
- **Firebase Cloud Messaging** — `app/services/fcm.py` sends HTTP v1 pushes
  using a service-account key (see Push notifications below).

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

## Push notifications, scheduling and reminders

- **Push**: `app/services/notify.py` writes in-app notifications (respecting
  each user's category preferences) and then pushes to their registered
  devices through `app/services/fcm.py`. Devices register via
  `POST /api/v1/notifications/devices` and unregister via
  `/devices/unregister`; preferences via `GET/PUT /notifications/preferences`.
  Set `FCM_SERVICE_ACCOUNT_JSON` (the key JSON itself, or a file path such
  as `fcm-service-account.json`). Unset means no push; in-app notifications
  still work. A device token is deleted only when FCM reports it
  unregistered or invalid, not for payload errors.
- **Scheduled posting**: announcements and events take an optional
  `publish_at` (between a minute and a year ahead). Until then they are
  hidden from public lists; `PATCH /events/{id}/schedule` and the matching
  announcement route move or release them early.
  `app/services/scheduling.py` sends the new-content alert once the time
  arrives; a failed release is retried on the next run.
- **Event reminders**: about a day and an hour before start, to registered
  and bookmarked users (`app/services/reminders.py`). Each (event, user,
  kind) is claimed with an insert-or-ignore on `event_reminders_sent`, so
  overlapping runs never double-send. The release and reminder jobs run
  in-process every 5 minutes (`REMINDERS_ENABLED=true`), or from an
  external scheduler via `POST /api/v1/internal/run-reminders` with
  `CRON_SECRET`.
- **Other endpoints added**: `/search`, `/bookings` (create, mine, incoming,
  cancel, respond), `/transport/{id}/rate`, `/campus-services`, event
  registration.

## Accounts, admin controls and compliance

- **Audit log**: administrator actions (role changes, removals, rider
  verification, user exports, two-factor checks, account deletions) are
  written to `audit_log`; Super Admins read it at `GET /admin/audit`.
- **CSV export**: `GET /admin/users/export.csv` (Super Admin, formula-safe,
  logged).
- **Real analytics**: `profiles.last_seen_at` (touched at most every 5
  minutes) gives daily/monthly active users; `content_views` records
  announcement/event openings and feeds the publisher performance screen
  (views, and bookmarks + registrations per view as engagement).
- **Account data**: `GET /auth/me/export` returns everything held about the
  caller; `DELETE /auth/me` deletes the account (Super Admins must change
  role first). `POST /internal/purge-inactive` (cron secret) removes student
  accounts unseen for two years.
- **Password reset**: `POST /auth/password-reset` always answers 202. Set the
  Supabase Site URL so the emailed link lands somewhere useful.
- **Lockout**: five wrong passwords for one email in 15 minutes gives 429
  (per process), on top of the per-IP limits.
- **Two-factor (TOTP)** for admin and minor-admin accounts through Supabase
  MFA: `GET /auth/mfa/status`, `POST /auth/mfa/enroll`, `POST /auth/mfa/verify`.
  Login returns `mfa_required` plus a factor id when an admin has enrolled.
  Set `ADMIN_REQUIRE_2FA=true` only after every admin has enrolled; then admin
  endpoints demand an `aal2` session.
- Backups, restore testing, uptime monitoring and the job schedule are in
  [`../docs/OPERATIONS.md`](../docs/OPERATIONS.md); `scripts/backup_db.ps1`
  takes a dated `pg_dump`.

## Key behavior notes

- **Publishing is immediate unless scheduled.** There is no pre-approval
  gate — creating an announcement/event/accommodation listing/boda rider
  makes it live right away, or at its `publish_at` time if one is set. Admins (`admin`, `minor_admin`) can only **remove** content that
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
