from datetime import datetime

from fastapi import APIRouter, BackgroundTasks, Depends
from pydantic import BaseModel

from fastapi import HTTPException, status

from app.core.security import get_current_user, require_publisher
from app.schemas.content import Announcement, AnnouncementCreate
from app.core.supabase_client import get_supabase_admin
from app.schemas.user import UserProfile
from app.services.announce import announce_announcement
from app.services.content_filters import (
    is_live,
    is_live_filter,
    not_expired_filter,
    validate_publish_at,
)
from app.services.scheduling import release_due_content, reschedule
from app.services.publisher_service import record_publish, remove_own_content
from app.services.table_repo import TableRepo

router = APIRouter(prefix="/announcements", tags=["announcements"])
repo = TableRepo("announcements")


@router.get("", response_model=list[Announcement])
def list_announcements(category: str | None = None, include_expired: bool = False) -> list[dict]:
    """Expired announcements are hidden unless [include_expired] is set
    (used by the app for bookmarks, which should still resolve)."""
    query = get_supabase_admin().table("announcements").select("*").or_(is_live_filter())
    if not include_expired:
        query = query.or_(not_expired_filter())
    if category and category != "All":
        query = query.eq("category", category)
    return query.order("published_at", desc=True).execute().data


@router.get("/{id}", response_model=Announcement)
def get_announcement(id: str) -> dict:
    row = repo.get(id)
    if not is_live(row):
        raise HTTPException(status.HTTP_404_NOT_FOUND, "announcements/%s not found" % id)
    return row


@router.post("", response_model=Announcement)
def create_announcement(
    body: AnnouncementCreate,
    background: BackgroundTasks,
    user: UserProfile = Depends(require_publisher),
) -> dict:
    """Publishes immediately — no pre-approval gate (§5.1) — or at
    [publish_at] when scheduled. An admin can still remove it later; see
    POST /admin/moderation/{submission_id}/remove."""
    publish_at = validate_publish_at(body.publish_at)
    if publish_at and body.expires_at and body.expires_at <= publish_at:
        raise HTTPException(
            status.HTTP_422_UNPROCESSABLE_ENTITY, "It would expire before it goes live"
        )
    payload = body.model_dump(mode="json", exclude={"draft_id", "department"})
    payload["publisher_name"] = user.faculty or body.department or user.name
    if publish_at:
        payload["publish_at"] = publish_at.isoformat()
        payload["published_at"] = payload["publish_at"]  # feed order = go-live time
    created = repo.create(payload)
    record_publish(
        publisher_id=user.id,
        publisher_name=payload["publisher_name"],
        type="announcement",
        title=created["title"],
        content_id=created["id"],
        draft_id=body.draft_id,
        publish_at=payload.get("publish_at"),
    )
    if not publish_at:
        background.add_task(announce_announcement, created, user.id)
    return created


class ScheduleChange(BaseModel):
    publish_at: datetime | None = None  # null = publish right now


@router.patch("/{id}/schedule", response_model=Announcement)
def reschedule_announcement(
    id: str,
    body: ScheduleChange,
    background: BackgroundTasks,
    user: UserProfile = Depends(require_publisher),
) -> dict:
    """Moves a still-scheduled announcement, or publishes it now (null)."""
    updated = reschedule("announcement", id, user, body.publish_at)
    if body.publish_at is None:
        background.add_task(release_due_content)
    return updated


@router.delete("/{id}", status_code=204)
def delete_announcement(id: str, user: UserProfile = Depends(get_current_user)) -> None:
    remove_own_content(user.id, "announcement", id)
