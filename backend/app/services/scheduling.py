"""Scheduled posting: items with a future publish_at stay hidden from every
public list until that time. Nothing "flips" them live - the read paths just
stop filtering them out - but this module sends the new-content alert once
the time arrives and moves the publisher's submission from scheduled to
published."""

import logging
from datetime import datetime, timezone

from fastapi import HTTPException, status

from app.core.supabase_client import get_supabase_admin
from app.schemas.user import UserProfile
from app.services.announce import ANNOUNCERS
from app.services.content_filters import is_live, validate_publish_at
from app.services.table_repo import TableRepo

logger = logging.getLogger("mysun")

TABLE_BY_TYPE = {"announcement": "announcements", "event": "events"}


def _iso(dt: datetime) -> str:
    return dt.astimezone(timezone.utc).isoformat()


def release_due_content(now: datetime | None = None) -> int:
    """Alerts for scheduled items whose time has come. Safe to run often and
    from several processes: an item is claimed with a conditional update, so
    only one run sends its alert. Returns how many items were released."""
    now = now or datetime.now(timezone.utc)
    db = get_supabase_admin()
    released = 0
    for type_, table in TABLE_BY_TYPE.items():
        due = (
            db.table(table)
            .select("*")
            .lte("publish_at", _iso(now))
            .is_("notified_at", "null")
            .execute()
            .data
        )
        for row in due:
            claimed = (
                db.table(table)
                .update({"notified_at": _iso(now)})
                .eq("id", row["id"])
                .is_("notified_at", "null")
                .execute()
                .data
            )
            if not claimed:
                continue
            try:
                subs = (
                    db.table("publisher_submissions")
                    .select("id,publisher_id")
                    .eq("type", type_)
                    .eq("content_id", row["id"])
                    .eq("status", "scheduled")
                    .execute()
                    .data
                )
                ANNOUNCERS[type_](row, subs[0]["publisher_id"] if subs else None)
            except Exception:
                # Give the claim back so the next run retries this item, and
                # keep going: one bad row must not block the others.
                logger.exception("Releasing scheduled %s %s failed", type_, row["id"])
                db.table(table).update({"notified_at": None}).eq("id", row["id"]).execute()
                continue
            released += 1
            try:
                for sub in subs:
                    db.table("publisher_submissions").update(
                        {"status": "published", "updated_at": _iso(now)}
                    ).eq("id", sub["id"]).execute()
            except Exception:
                # The alert already went out; retrying would send it twice.
                logger.exception("Marking submissions published failed for %s", row["id"])
    return released


def reschedule(type_: str, content_id: str, user: UserProfile, when: datetime | None) -> dict:
    """Moves a still-scheduled item to a new time, or (when=None) publishes
    it right away. Only the publisher who scheduled it may do this."""
    table = TABLE_BY_TYPE[type_]
    db = get_supabase_admin()
    subs = (
        db.table("publisher_submissions")
        .select("id")
        .eq("type", type_)
        .eq("content_id", content_id)
        .eq("publisher_id", user.id)
        .eq("status", "scheduled")
        .execute()
        .data
    )
    if not subs:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "No scheduled item found")
    row = TableRepo(table).get(content_id)
    if is_live(row):
        raise HTTPException(status.HTTP_409_CONFLICT, "This item is already live")

    new_time = validate_publish_at(when) if when else datetime.now(timezone.utc)
    patch = {"publish_at": _iso(new_time)}
    if type_ == "announcement":
        patch["published_at"] = patch["publish_at"]
    expires_at = row.get("expires_at")
    if expires_at and datetime.fromisoformat(expires_at) <= new_time:
        raise HTTPException(
            status.HTTP_422_UNPROCESSABLE_ENTITY, "That is after the announcement expires"
        )
    updated = TableRepo(table).update(content_id, patch)
    db.table("publisher_submissions").update(
        {"publish_at": patch["publish_at"], "updated_at": _iso(datetime.now(timezone.utc))}
    ).eq("id", subs[0]["id"]).execute()
    return updated
