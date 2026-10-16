from datetime import datetime, timezone

from fastapi import HTTPException, status

from app.core.supabase_client import get_supabase_admin
from app.services.notify import notify_users
from app.services.table_repo import TableRepo

submissions_repo = TableRepo("publisher_submissions")

CONTENT_TABLE_BY_TYPE = {
    "announcement": "announcements",
    "event": "events",
    "accommodation": "accommodation_listings",
    "transport": "transport_providers",
}


def _now() -> str:
    return datetime.now(timezone.utc).isoformat()


def record_publish(
    *,
    publisher_id: str,
    publisher_name: str | None,
    type: str,
    title: str,
    content_id: str,
    draft_id: str | None = None,
    publish_at: str | None = None,
) -> dict:
    """Logs a just-created piece of content as published. If [draft_id]
    points at one of this publisher's own drafts, that row is converted in
    place instead of left behind as a duplicate (mirrors
    PublisherRepository.publish in the Flutter mock)."""
    payload = {
        "type": type,
        "title": title,
        "status": "scheduled" if publish_at else "published",
        "publish_at": publish_at,
        "content_id": content_id,
        "publisher_name": publisher_name,
        "updated_at": _now(),
    }
    if draft_id:
        existing = submissions_repo.list(id=draft_id, publisher_id=publisher_id)
        if existing:
            return submissions_repo.update(draft_id, payload)
    payload["publisher_id"] = publisher_id
    return submissions_repo.create(payload)


def remove_content(submission: dict, reason: str, *, notify_publisher: bool = False) -> dict:
    """Deletes the real content row (if any) and marks the submission
    removed — used for both admin moderation and publisher self-removal."""
    content_id = submission.get("content_id")
    if content_id:
        table = CONTENT_TABLE_BY_TYPE[submission["type"]]
        TableRepo(table).delete(content_id)
    updated = submissions_repo.update(
        submission["id"],
        {"status": "removed", "removal_reason": reason, "updated_at": _now()},
    )
    if notify_publisher and submission.get("publisher_id"):
        notify_users(
            [submission["publisher_id"]],
            title="Your content was removed",
            body=f"\"{submission['title']}\" was removed by an administrator. Reason: {reason}",
            type="system",  # moderation notices are never switched off
            related_id=submission.get("content_id"),
        )
    return updated


def remove_own_content(publisher_id: str, type: str, content_id: str) -> None:
    """A publisher taking down their own live content — distinct from an
    admin's terms-of-service removal, which goes through admin.py instead."""
    matches = [
        m
        for status_ in ("published", "scheduled")
        for m in submissions_repo.list(
            content_id=content_id, publisher_id=publisher_id, type=type, status=status_
        )
    ]
    if not matches:
        raise HTTPException(status.HTTP_403_FORBIDDEN, "You can only remove your own listings.")
    remove_content(matches[0], "Removed by the publisher.")


def engagement_stats(submissions: list[dict]) -> tuple[int, int]:
    """(views, interactions) for a publisher's live announcements and events,
    from content_views, bookmarks and event registrations."""
    db = get_supabase_admin()
    ids = {
        t: [s["content_id"] for s in submissions
            if s["type"] == t and s["status"] == "published" and s.get("content_id")]
        for t in ("announcement", "event")
    }
    views = interactions = 0
    for t, content_ids in ids.items():
        if not content_ids:
            continue
        views += len(
            db.table("content_views").select("id").eq("content_type", t)
            .in_("content_id", content_ids).execute().data
        )
        interactions += len(
            db.table("bookmarks").select("user_id").eq("content_type", t)
            .in_("content_id", content_ids).execute().data
        )
        if t == "event":
            interactions += len(
                db.table("event_registrations").select("user_id")
                .in_("event_id", content_ids).execute().data
            )
    return views, interactions


def compute_performance(
    submissions: list[dict], views: int = 0, interactions: int = 0
) -> dict:
    """§1.4 "Performance metrics and analytics" for publishers. All real:
    views come from content_views, and engagement is the share of views that
    ended in a bookmark or an event registration."""
    published = [s for s in submissions if s["status"] == "published"]
    removed = [s for s in submissions if s["status"] == "removed"]
    drafts = [s for s in submissions if s["status"] == "draft"]
    by_type = {
        t: len([s for s in submissions if s["type"] == t and s["status"] != "draft"])
        for t in CONTENT_TABLE_BY_TYPE
    }
    engagement_percent = round(min(interactions / views * 100, 100), 1) if views else 0.0
    return {
        "total_submissions": len(submissions),
        "published": len(published),
        "removed": len(removed),
        "drafts": len(drafts),
        "by_type": by_type,
        "estimated_views": views,
        "engagement_percent": engagement_percent,
    }
