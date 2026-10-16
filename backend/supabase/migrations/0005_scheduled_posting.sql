-- Scheduled posting: announcements and events can go live at a future time.
--   publish_at  - when the item becomes visible (null = live immediately)
--   notified_at - set once the "new announcement/event" alert has been sent
--                 for a scheduled item, so it is only sent once.

-- Run this statement on its own first if your SQL editor wraps the file in
-- a transaction (a new enum value can't be used until it is committed).
alter type submission_status add value if not exists 'scheduled';

alter table announcements add column publish_at timestamptz, add column notified_at timestamptz;
alter table events add column publish_at timestamptz, add column notified_at timestamptz;
alter table publisher_submissions add column publish_at timestamptz;

-- Lets the release job find due items quickly.
create index on announcements (publish_at) where notified_at is null and publish_at is not null;
create index on events (publish_at) where notified_at is null and publish_at is not null;

-- Registration must not work on an event that is not live yet.
create or replace function register_for_event(p_event_id uuid, p_user_id uuid)
returns json language plpgsql as $$
declare
  ev events%rowtype;
  inserted integer;
begin
  select * into ev from events where id = p_event_id for update;
  if not found or (ev.publish_at is not null and ev.publish_at > now()) then
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
