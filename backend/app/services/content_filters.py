from datetime import datetime, timedelta, timezone

from fastapi import HTTPException, status


def _now_z() -> str:
    return datetime.now(timezone.utc).isoformat().replace("+00:00", "Z")


def not_expired_filter() -> str:
    """PostgREST `or` clause matching announcements with no expiry or an
    expiry still in the future."""
    return f"expires_at.is.null,expires_at.gt.{_now_z()}"


def is_live_filter() -> str:
    """PostgREST `or` clause matching content that is published now: not
    scheduled, or scheduled for a time that has arrived."""
    return f"publish_at.is.null,publish_at.lte.{_now_z()}"


def is_live(row: dict) -> bool:
    publish_at = row.get("publish_at")
    return publish_at is None or datetime.fromisoformat(publish_at) <= datetime.now(timezone.utc)


def validate_publish_at(value: datetime | None) -> datetime | None:
    """A schedule must be at least a minute ahead (anything sooner is just
    "publish now") and within a year. Naive times are taken as UTC."""
    if value is None:
        return None
    if value.tzinfo is None:
        value = value.replace(tzinfo=timezone.utc)
    now = datetime.now(timezone.utc)
    if value < now + timedelta(minutes=1):
        raise HTTPException(
            status.HTTP_422_UNPROCESSABLE_ENTITY, "Schedule a time at least a minute from now"
        )
    if value > now + timedelta(days=365):
        raise HTTPException(
            status.HTTP_422_UNPROCESSABLE_ENTITY, "Schedule at most a year ahead"
        )
    return value
