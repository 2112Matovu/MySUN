-- Boda ratings, in-app booking, and campus services (food, health, IT, library).

-- ── Ratings ──────────────────────────────────────────────────────────────
create table transport_ratings (
  provider_id uuid not null references transport_providers (id) on delete cascade,
  user_id uuid not null references profiles (id) on delete cascade,
  stars smallint not null check (stars between 1 and 5),
  comment text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  primary key (provider_id, user_id)
);

-- One rating per user per rider; rating again replaces the previous one.
-- Recomputes the rider's average and count from the rows so the numbers
-- can't drift. Returns {status, rating, rating_count}.
create or replace function rate_transport_provider(
  p_provider_id uuid, p_user_id uuid, p_stars integer, p_comment text
) returns json language plpgsql as $$
declare
  avg_stars numeric;
  total integer;
begin
  perform 1 from transport_providers where id = p_provider_id for update;
  if not found then
    return json_build_object('status', 'not_found');
  end if;

  insert into transport_ratings (provider_id, user_id, stars, comment)
    values (p_provider_id, p_user_id, p_stars, p_comment)
  on conflict (provider_id, user_id)
    do update set stars = excluded.stars, comment = excluded.comment, updated_at = now();

  select round(avg(stars)::numeric, 1), count(*) into avg_stars, total
    from transport_ratings where provider_id = p_provider_id;
  update transport_providers set rating = avg_stars, rating_count = total
    where id = p_provider_id;
  return json_build_object('status', 'ok', 'rating', avg_stars, 'rating_count', total);
end;
$$;

-- ── Bookings ─────────────────────────────────────────────────────────────
create type booking_status as enum ('pending', 'accepted', 'declined', 'cancelled', 'completed');

create table bookings (
  id uuid primary key default gen_random_uuid(),
  student_id uuid not null references profiles (id) on delete cascade,
  provider_id uuid not null references transport_providers (id) on delete cascade,
  pickup text not null,
  destination text not null,
  requested_time timestamptz, -- null = as soon as possible
  note text,
  status booking_status not null default 'pending',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index on bookings (student_id);
create index on bookings (provider_id);

-- ── Campus services ──────────────────────────────────────────────────────
create type campus_service_category as enum ('food', 'health', 'it_support', 'library');

create table campus_services (
  id uuid primary key default gen_random_uuid(),
  category campus_service_category not null,
  name text not null,
  description text,
  location text,
  opening_hours text,
  contact_phone text,
  created_at timestamptz not null default now()
);

create index on campus_services (category);

alter table transport_ratings enable row level security;
alter table bookings enable row level security;
alter table campus_services enable row level security;

create policy "users read their own ratings" on transport_ratings
  for select using (auth.uid() = user_id);
create policy "students read their own bookings" on bookings
  for select using (auth.uid() = student_id);
create policy "campus services are publicly readable" on campus_services
  for select using (true);
