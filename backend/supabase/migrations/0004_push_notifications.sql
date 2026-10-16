-- Push notifications: per-user category preferences, device tokens, and a
-- log that keeps each event reminder from being sent twice.

-- Keys: announcements, events, reminders, transport. A missing key means on.
alter table profiles add column notification_prefs jsonb not null default '{}'::jsonb;

create table device_tokens (
  token text primary key,
  user_id uuid not null references profiles (id) on delete cascade,
  platform text not null default 'android',
  updated_at timestamptz not null default now()
);

create index on device_tokens (user_id);

-- kind: 'day' (about a day before start) or 'hour' (about an hour before).
create table event_reminders_sent (
  event_id uuid not null references events (id) on delete cascade,
  user_id uuid not null references profiles (id) on delete cascade,
  kind text not null check (kind in ('day', 'hour')),
  sent_at timestamptz not null default now(),
  primary key (event_id, user_id, kind)
);

alter table device_tokens enable row level security;
alter table event_reminders_sent enable row level security;
