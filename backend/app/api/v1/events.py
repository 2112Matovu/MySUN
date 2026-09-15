from fastapi import APIRouter, Depends

from app.core.security import get_current_user, require_publisher
from app.schemas.content import Event, EventCreate
from app.schemas.user import UserProfile
from app.services.publisher_service import record_publish, remove_own_content
from app.services.table_repo import TableRepo

router = APIRouter(prefix="/events", tags=["events"])
repo = TableRepo("events")


@router.get("", response_model=list[Event])
def list_events(category: str | None = None) -> list[dict]:
    items = repo.list(order_by="date_time", desc=False)
    if category and category != "All":
        items = [i for i in items if i["category"] == category]
    return items


@router.get("/{id}", response_model=Event)
def get_event(id: str) -> dict:
    return repo.get(id)


@router.post("", response_model=Event)
def create_event(body: EventCreate, user: UserProfile = Depends(require_publisher)) -> dict:
    """Publishes immediately — no pre-approval gate (§5.1)."""
    payload = body.model_dump(mode="json", exclude={"draft_id"})
    created = repo.create(payload)
    record_publish(
        publisher_id=user.id,
        publisher_name=body.organizer_name,
        type="event",
        title=created["title"],
        content_id=created["id"],
        draft_id=body.draft_id,
    )
    return created


@router.delete("/{id}", status_code=204)
def delete_event(id: str, user: UserProfile = Depends(get_current_user)) -> None:
    remove_own_content(user.id, "event", id)
