-- Audit log of administrator actions, real usage tracking (last seen, content
-- views) and a place for per-account data retention.

create table audit_log (
  id uuid primary key default gen_random_uuid(),
  actor_id uuid references profiles (id) on delete set null,
  actor_name text,
  action text not null,           -- e.g. role_change, content_removed, verify_toggle, login
  target_type text,
  target_id text,
  detail jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create index on audit_log (created_at desc);
create index on audit_log (actor_id);

alter table profiles add column last_seen_at timestamptz;
create index on profiles (last_seen_at);

create table content_views (
  id bigint generated always as identity primary key,
  content_type text not null check (content_type in ('announcement', 'event')),
  content_id uuid not null,
  user_id uuid references profiles (id) on delete set null,
  viewed_at timestamptz not null default now()
);

create index on content_views (content_type, content_id);
create index on content_views (viewed_at);

alter table audit_log enable row level security;
alter table content_views enable row level security;
-- No policies on purpose: only the backend (service-role key) reads or writes these.
