# MySun operations runbook

What has to be done outside the code for the SRS reliability, security and
retention requirements. Each section says which requirement it covers.

## Backups and restore (NFR-REL-03, NFR-REL-05)

Targets: **RTO 4 hours, RPO 6 hours.**

- Supabase takes daily backups on paid plans. The free plan has none you can
  restore from, so until the project is upgraded take your own:
  `backend/scripts/backup_db.ps1` runs `pg_dump` against `DATABASE_URL` (the
  Postgres connection string from Supabase > Project Settings > Database) and
  writes a dated `.sql` file. Schedule it every 6 hours (Windows Task
  Scheduler, or a cron job on any always-on machine) to meet the 6-hour RPO.
- Keep the last 14 dumps and copy them somewhere other than the machine that
  made them.
- **Restore test (do this once before launch, then each quarter):** create an
  empty scratch Supabase project, run `psql "$SCRATCH_URL" -f dump.sql`, point a
  local backend's `.env` at it, run `pytest` and open the app. Record the date
  and how long it took; that number is your real RTO.
- Photos live in Supabase Storage and are not part of `pg_dump`; download the
  bucket occasionally (Supabase dashboard > Storage) or accept losing them.

## Uptime and error monitoring (NFR-REL-01, NFR-REL-02)

- `GET /health` is the liveness probe. Point a free monitor (UptimeRobot,
  Better Stack) at `https://<api-host>/health` every 5 minutes with email/SMS
  alerts. Render's free tier sleeps after ~15 minutes idle, so the monitor's
  ping also keeps the API warm.
- Set `SENTRY_DSN` to get an alert on unhandled exceptions. Alert rule:
  error rate above 5% over 10 minutes.
- Every response carries `X-Request-ID`; logs are JSON on stdout, so a user's
  report can be matched to one log line.
- Availability and error rate are only meaningful once the monitor has run for
  a month; until then the requirement stays Partial.

## Scheduled jobs (reminders, scheduled posts, retention - DR-05)

Reminders and scheduled-post release run inside the API every 5 minutes when
`REMINDERS_ENABLED=true`. If the API sleeps (Render free), also call them from
an external scheduler with the shared secret (`CRON_SECRET`):

```
POST /api/v1/internal/run-reminders        header  X-Cron-Secret: <secret>   every 5 min
POST /api/v1/internal/purge-inactive       header  X-Cron-Secret: <secret>   monthly
```

`purge-inactive` deletes **student** accounts not seen for two years (staff
roles are never auto-purged). Run it with `?years=2` (the default).

## Account protection (NFR-SEC-09, NFR-SEC-10, FR-AUTH-07)

- **Lockout:** five wrong passwords for one email in 15 minutes returns HTTP
  429 for the rest of the window. The counter is per process; with several API
  workers each keeps its own. Supabase Auth's own rate limits and the per-IP
  limit (8 logins/minute) apply as well. Confirm Supabase's limits in
  Authentication > Rate Limits.
- **Admin session timeout:** the app signs admin and minor-admin accounts out
  after 30 minutes without a touch, including time spent in the background.
- **Two-factor (TOTP):**
  1. In Supabase, Authentication > Multi-factor, make sure TOTP is enabled.
  2. Each admin opens Profile > Two-factor authentication, adds the key to an
     authenticator app and enters a code.
  3. From then on that admin gets a code prompt after the password.
  4. Once **every** admin and minor admin has enrolled, set
     `ADMIN_REQUIRE_2FA=true` on the API. From then on admin endpoints reject
     any admin session that has not passed the code check (HTTP 403 "Two-factor
     authentication required"). Do not turn it on before everyone has
     enrolled or they will be locked out of the Admin tab. Recovery is to set
     it back to `false`.

## Password reset (FR-AUTH-06)

`POST /auth/password-reset` asks Supabase to email a reset link. Set
Authentication > URL Configuration > **Site URL** (and a redirect) to the page
that should finish the reset, otherwise the link lands on Supabase's default
page. Customise the email under Authentication > Email Templates.

## Data export and deletion (FR-AUTH-08)

Users do this themselves in Profile: **Download my data** (JSON copied to the
clipboard) and **Delete account**. Deleting removes the auth user; their
profile, bookmarks, notifications, registrations, bookings and submissions go
by cascade. Content they published stays live until an admin removes it.
Super Admin accounts cannot delete themselves (change the role first).
