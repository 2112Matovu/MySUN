from fastapi import APIRouter, Depends

from app.core.security import get_current_user, require_publisher
from app.schemas.content import Announcement, AnnouncementCreate
from app.schemas.user import UserProfile
from app.services.publisher_service import record_publish, remove_own_content
from app.services.table_repo import TableRepo

router = APIRouter(prefix="/announcements", tags=["announcements"])
repo = TableRepo("announcements")


@router.get("", response_model=list[Announcement])
def list_announcements(category: str | None = None) -> list[dict]:
    items = repo.list(order_by="published_at", desc=True)
    if category and category != "All":
        items = [i for i in items if i["category"] == category]
    return items


@router.get("/{id}", response_model=Announcement)
def get_announcement(id: str) -> dict:
    return repo.get(id)


@router.post("", response_model=Announcement)
def create_announcement(
    body: AnnouncementCreate, user: UserProfile = Depends(require_publisher)
) -> dict:
    """Publishes immediately — no pre-approval gate (§5.1). An admin can
    still remove it later; see POST /admin/moderation/{submission_id}/remove."""
    payload = body.model_dump(mode="json", exclude={"draft_id", "department"})
    payload["publisher_name"] = user.faculty or body.department or user.name
    created = repo.create(payload)
    record_publish(
        publisher_id=user.id,
        publisher_name=payload["publisher_name"],
        type="announcement",
        title=created["title"],
        content_id=created["id"],
        draft_id=body.draft_id,
    )
    return created


@router.delete("/{id}", status_code=204)
def delete_announcement(id: str, user: UserProfile = Depends(get_current_user)) -> None:
    remove_own_content(user.id, "announcement", id)
