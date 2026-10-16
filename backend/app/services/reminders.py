"""Event reminders: about a day and about an hour before start, sent to
everyone registered for the event or who bookmarked it."""

from datetime import datetime, timedelta, timezone

from app.core.supabase_client import get_supabase_admin
from app.services.content_filters import is_live_filter
from app.services.notify import notify_users

_DAY = timedelta(hours=24)
_HOUR = timedelta(hours=1)


def _until(delta: timedelta) -> str:
    minutes = max(int(delta.total_seconds() // 60), 1)
    if minutes < 60:
        return f"{minutes} minute{'s' if minutes != 1 else ''}"
    hours = round(minutes / 60)
    return f"{hours} hour{'s' if hours != 1 else ''}"


def run_event_reminders(now: datetime | None = None) -> dict[str, int]:
    """Safe to call as often as you like (the job runs every few minutes):
    each (event, user, kind) is sent once, tracked in event_reminders_sent.
    A reminder is "hour" within the last hour before start, otherwise "day"
    (anything starting within 24 hours)."""
    now = now or datetime.now(timezone.utc)
    db = get_supabase_admin()
    events = (
        db.table("events")
        .select("id,title,venue,date_time")
        .gt("date_time", now.isoformat())
        .lte("date_time", (now + _DAY).isoformat())
        .or_(is_live_filter())
        .execute()
        .data
    )
    sent = {"day": 0, "hour": 0}
    for ev in events:
        delta = datetime.fromisoformat(ev["date_time"]) - now
        kind = "hour" if delta <= _HOUR else "day"

        registered = db.table("event_registrations").select("user_id").eq("event_id", ev["id"]).execute().data
        saved = (
            db.table("bookmarks")
            .select("user_id")
            .eq("content_type", "event")
            .eq("content_id", ev["id"])
            .execute()
            .data
        )
        audience = {r["user_id"] for r in registered} | {r["user_id"] for r in saved}
        already = {
            r["user_id"]
            for r in db.table("event_reminders_sent")
            .select("user_id")
            .eq("event_id", ev["id"])
            .eq("kind", kind)
            .execute()
            .data
        }
        todo = sorted(audience - already)
        if not todo:
            continue

        notify_users(
            todo,
            title=f"{ev['title']} starts in {_until(delta)}",
            body=f"Venue: {ev['venue']}",
            type="reminder",
            related_id=ev["id"],
        )
        db.table("event_reminders_sent").insert(
            [{"event_id": ev["id"], "user_id": uid, "kind": kind} for uid in todo]
        ).execute()
        sent[kind] += len(todo)
    return sent
