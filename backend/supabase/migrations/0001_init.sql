-- MySun — initial schema on Supabase Postgres.
-- Mirrors the Flutter app's current mock models field-for-field so the
-- backend is a drop-in replacement for the mock repositories (see
-- student_app/lib/data/models/*.dart and MySun_Integrated_Final_Specification.md).

create extension if not exists "pgcrypto";

-- ── Roles & profiles ─────────────────────────────────────────────────────
-- auth.users (Supabase Auth) holds email/password; app-specific fields live
-- in profiles, one row per auth user, created by the trigger below.

create type user_role as enum ('student', 'publisher', 'admin', 'minor_admin');

create table profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  name text not null,
  email text not null,
  role user_role not null default 'student',
  student_id text,
  faculty text,
  program text,
  image_url text,
  created_at timestamptz not null default now()
);

-- New Supabase Auth sign-ups always start as students; only an admin can
-- promote via PATCH /admin/users/{id}/role (§7.3 Role Assignment).
create function handle_new_user() returns trigger as $$
begin
  insert into public.profiles (id, name, email, faculty, program)
  values (
    new.id,
    coalesce(new.raw_user_meta_data ->> 'name', split_part(new.email, '@', 1)),
    new.email,
    new.raw_user_meta_data ->> 'faculty',
    new.raw_user_meta_data ->> 'program'
  );
  return new;
end;
$$ language plpgsql security definer;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure handle_new_user();

-- ── Content ──────────────────────────────────────────────────────────────

create table announcements (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  description text not null,
  category text not null,
  publisher_name text not null,
  published_at timestamptz not null default now(),
  is_important boolean not null default false,
  image_url text,
  expires_at timestamptz
);

create table events (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  description text not null,
  category text not null,
  organizer_name text not null,
  date_time timestamptz not null,
  venue text not null,
  end_date_time timestamptz,
  image_url text,
  capacity integer,
  registered_count integer not null default 0,
  is_featured boolean not null default false
);

create type accommodation_type as enum ('hostel', 'rental');
create type room_sharing_type as enum ('shared', 'private', 'both');

create table accommodation_listings (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  type accommodation_type not null,
  location text not null,
  -- Hostels bill per semester, independent rentals per month
  -- (student_app/lib/data/models/accommodation_listing.dart AccommodationType.priceUnit).
  price integer not null,
  is_gazetted boolean not null default false,
  room_sharing room_sharing_type not null default 'shared',
  contact_phone text not null,
  image_urls text[] not null default '{}',
  description text,
  publisher_name text,
  is_available boolean not null default true
);

-- Boda-only for now (spec §6 services framework — taxi/bus/matatu can
-- return as separate service types later).
create table transport_providers (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  phone_number text not null,
  service_type text not null default 'boda',
  contact_person text,
  operating_hours text,
  service_areas text[] not null default '{}',
  image_url text,
  is_verified boolean not null default false,
  rating numeric(3, 1) not null default 0,
  rating_count integer not null default 0
);

create table bus_schedules (
  id uuid primary key default gen_random_uuid(),
  route_name text not null,
  departure_point text not null,
  destination text not null,
  departure_time text not null, -- "HH:MM", campus-local
  estimated_duration_minutes integer not null,
  operating_days text not null,
  status text not null default 'active',
  notes text
);

-- ── Publishing & moderation ──────────────────────────────────────────────
-- Publishing is immediate — there is no pre-approval gate. This table is
-- the publisher's own history and the admin's review-and-remove list
-- (§5.1 "Content moderation": remove only, no approve step).

create type submission_type as enum ('announcement', 'event', 'accommodation', 'transport');
create type submission_status as enum ('draft', 'published', 'removed');

create table publisher_submissions (
  id uuid primary key default gen_random_uuid(),
  publisher_id uuid not null references profiles (id) on delete cascade,
  type submission_type not null,
  title text not null,
  status submission_status not null default 'draft',
  content_id uuid, -- row id in the matching content table above; null for drafts
  form_data jsonb, -- the Create screen's fields, so a draft can be resumed
  publisher_name text,
  removal_reason text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index on publisher_submissions (publisher_id);
create index on publisher_submissions (status);

-- ── Bookmarks & notifications ────────────────────────────────────────────

create table bookmarks (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references profiles (id) on delete cascade,
  content_type text not null, -- 'announcement' | 'event'
  content_id uuid not null,
  created_at timestamptz not null default now(),
  unique (user_id, content_type, content_id)
);

create table notifications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references profiles (id) on delete cascade,
  title text not null,
  body text not null,
  type text not null, -- 'announcement' | 'event' | 'reminder' | 'transport' | 'system'
  related_id uuid,
  is_read boolean not null default false,
  created_at timestamptz not null default now()
);

create index on notifications (user_id);

-- ── Row Level Security ───────────────────────────────────────────────────
-- Baseline defence-in-depth; the FastAPI backend uses the service-role key
-- and enforces the real authorization logic itself (see app/core/security.py).

alter table profiles enable row level security;
alter table announcements enable row level security;
alter table events enable row level security;
alter table accommodation_listings enable row level security;
alter table transport_providers enable row level security;
alter table bus_schedules enable row level security;
alter table publisher_submissions enable row level security;
alter table bookmarks enable row level security;
alter table notifications enable row level security;

create policy "profiles are publicly readable" on profiles for select using (true);
create policy "content is publicly readable: announcements" on announcements for select using (true);
create policy "content is publicly readable: events" on events for select using (true);
create policy "content is publicly readable: accommodation" on accommodation_listings for select using (true);
create policy "content is publicly readable: transport" on transport_providers for select using (true);
create policy "content is publicly readable: bus schedules" on bus_schedules for select using (true);

create policy "users manage their own bookmarks" on bookmarks
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

create policy "users read their own notifications" on notifications
  for select using (auth.uid() = user_id);

create policy "publishers read their own submissions" on publisher_submissions
  for select using (auth.uid() = publisher_id);
