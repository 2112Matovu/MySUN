"""Real usage tracking: when a user was last seen and who viewed which
content. Both are best-effort and never fail the request they ride on."""

import logging
from datetime import datetime, timedelta, timezone

from app.core.supabase_client import get_supabase_admin

logger = logging.getLogger("mysun")

_TOUCH_EVERY = timedelta(minutes=5)


def touch_last_seen(profile: dict) -> None:
    """Stamps profiles.last_seen_at, at most once every few minutes per user."""
    try:
        last = profile.get("last_seen_at")
        now = datetime.now(timezone.utc)
        if last and now - datetime.fromisoformat(last) < _TOUCH_EVERY:
            return
        get_supabase_admin().table("profiles").update({"last_seen_at": now.isoformat()}).eq(
            "id", profile["id"]
        ).execute()
    except Exception:
        logger.exception("last_seen update failed")


def record_view(content_type: str, content_id: str, user_id: str | None = None) -> None:
    try:
        get_supabase_admin().table("content_views").insert(
            {"content_type": content_type, "content_id": content_id, "user_id": user_id}
        ).execute()
    except Exception:
        logger.exception("view record failed")


def count_active_since(since: datetime) -> int:
    rows = (
        get_supabase_admin()
        .table("profiles")
        .select("id")
        .gte("last_seen_at", since.isoformat())
        .execute()
        .data
    )
    return len(rows)


def can_preview(content_type: str, content_id: str, viewer) -> bool:
    """May this viewer open a not-yet-live item? Its publisher and admins."""
    if viewer is None:
        return False
    if viewer.role in ("admin", "minor_admin"):
        return True
    owned = (
        get_supabase_admin()
        .table("publisher_submissions")
        .select("id")
        .eq("type", content_type)
        .eq("content_id", content_id)
        .eq("publisher_id", viewer.id)
        .execute()
        .data
    )
    return bool(owned)
