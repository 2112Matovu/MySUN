-- Event registration (SRS FR-EVT registration): one row per (event, user),
-- with events.registered_count kept in step inside the same transaction.

create table event_registrations (
  event_id uuid not null references events (id) on delete cascade,
  user_id uuid not null references profiles (id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (event_id, user_id)
);

create index on event_registrations (user_id);

alter table event_registrations enable row level security;
create policy "users read their own registrations" on event_registrations
  for select using (auth.uid() = user_id);

-- Registers a user. Locks the event row so concurrent sign-ups can't push
-- registered_count past capacity. Idempotent: registering twice is a no-op.
-- Returns {registered, registered_count, status} where status is
-- 'ok' | 'full' | 'not_found'.
create or replace function register_for_event(p_event_id uuid, p_user_id uuid)
returns json language plpgsql as $$
declare
  ev events%rowtype;
  inserted integer;
begin
  select * into ev from events where id = p_event_id for update;
  if not found then
    return json_build_object('registered', false, 'registered_count', 0, 'status', 'not_found');
  end if;

  if exists (select 1 from event_registrations where event_id = p_event_id and user_id = p_user_id) then
    return json_build_object('registered', true, 'registered_count', ev.registered_count, 'status', 'ok');
  end if;

  if ev.capacity is not null and ev.registered_count >= ev.capacity then
    return json_build_object('registered', false, 'registered_count', ev.registered_count, 'status', 'full');
  end if;

  insert into event_registrations (event_id, user_id) values (p_event_id, p_user_id);
  update events set registered_count = registered_count + 1
    where id = p_event_id returning registered_count into inserted;
  return json_build_object('registered', true, 'registered_count', inserted, 'status', 'ok');
end;
$$;

create or replace function unregister_from_event(p_event_id uuid, p_user_id uuid)
returns json language plpgsql as $$
declare
  ev events%rowtype;
  removed integer;
begin
  select * into ev from events where id = p_event_id for update;
  if not found then
    return json_build_object('registered', false, 'registered_count', 0, 'status', 'not_found');
  end if;

  delete from event_registrations where event_id = p_event_id and user_id = p_user_id;
  get diagnostics removed = row_count;
  if removed > 0 then
    update events set registered_count = greatest(registered_count - 1, 0)
      where id = p_event_id returning * into ev;
  end if;
  return json_build_object('registered', false, 'registered_count', ev.registered_count, 'status', 'ok');
end;
$$;
