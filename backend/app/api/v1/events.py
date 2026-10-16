from datetime import datetime, timezone

from fastapi import APIRouter, BackgroundTasks, Depends, HTTPException, status
from pydantic import BaseModel

from app.core.security import get_current_user, get_optional_user, require_publisher
from app.core.supabase_client import get_supabase_admin
from app.schemas.content import Event, EventCreate
from app.schemas.user import UserProfile
from app.services.announce import announce_event
from app.services.content_filters import is_live, is_live_filter, validate_publish_at
from app.services.scheduling import release_due_content, reschedule
from app.services.publisher_service import record_publish, remove_own_content
from app.services.table_repo import TableRepo
from app.services.usage import can_preview, record_view

router = APIRouter(prefix="/events", tags=["events"])
repo = TableRepo("events")


@router.get("", response_model=list[Event])
def list_events(category: str | None = None) -> list[dict]:
    query = get_supabase_admin().table("events").select("*").or_(is_live_filter())
    if category and category != "All":
        query = query.eq("category", category)
    return query.order("date_time").execute().data


@router.get("/registrations/mine")
def my_registrations(user: UserProfile = Depends(get_current_user)) -> list[str]:
    """Ids of the events the signed-in user is registered for."""
    rows = (
        get_supabase_admin()
        .table("event_registrations")
        .select("event_id")
        .eq("user_id", user.id)
        .execute()
        .data
    )
    return [r["event_id"] for r in rows]


def _registration(fn: str, event_id: str, user: UserProfile) -> dict:
    result = (
        get_supabase_admin().rpc(fn, {"p_event_id": event_id, "p_user_id": user.id}).execute().data
    )
    if result["status"] == "not_found":
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Event not found")
    if result["status"] == "full":
        raise HTTPException(status.HTTP_409_CONFLICT, "This event is full")
    return {"registered": result["registered"], "registered_count": result["registered_count"]}


@router.post("/{id}/register")
def register(id: str, user: UserProfile = Depends(get_current_user)) -> dict:
    """Registers the signed-in user and bumps registered_count. Rejects with
    409 once capacity is reached; registering twice is a no-op."""
    return _registration("register_for_event", id, user)


@router.delete("/{id}/register")
def unregister(id: str, user: UserProfile = Depends(get_current_user)) -> dict:
    return _registration("unregister_from_event", id, user)


@router.get("/{id}", response_model=Event)
def get_event(id: str, viewer: UserProfile | None = Depends(get_optional_user)) -> dict:
    row = repo.get(id)
    if not is_live(row):
        if not can_preview("event", id, viewer):
            raise HTTPException(status.HTTP_404_NOT_FOUND, "events/%s not found" % id)
        return row
    record_view("event", id, viewer.id if viewer else None)
    return row


@router.post("", response_model=Event)
def create_event(
    body: EventCreate, background: BackgroundTasks, user: UserProfile = Depends(require_publisher)
) -> dict:
    """Publishes immediately — no pre-approval gate (§5.1) — or at
    [publish_at] when scheduled."""
    publish_at = validate_publish_at(body.publish_at)
    if publish_at and body.date_time <= publish_at:
        raise HTTPException(
            status.HTTP_422_UNPROCESSABLE_ENTITY, "The event would start before it goes live"
        )
    payload = body.model_dump(mode="json", exclude={"draft_id"})
    if publish_at:
        payload["publish_at"] = publish_at.isoformat()
    created = repo.create(payload)
    record_publish(
        publisher_id=user.id,
        publisher_name=body.organizer_name,
        type="event",
        title=created["title"],
        content_id=created["id"],
        draft_id=body.draft_id,
        publish_at=payload.get("publish_at"),
    )
    if not publish_at:
        background.add_task(announce_event, created, user.id)
    return created


class ScheduleChange(BaseModel):
    publish_at: datetime | None = None  # null = publish right now


@router.patch("/{id}/schedule", response_model=Event)
def reschedule_event(
    id: str,
    body: ScheduleChange,
    background: BackgroundTasks,
    user: UserProfile = Depends(require_publisher),
) -> dict:
    """Moves a still-scheduled event, or publishes it now (null)."""
    event = repo.get(id)
    when = body.publish_at
    if when and when.tzinfo is None:
        when = when.replace(tzinfo=timezone.utc)  # naive times are taken as UTC
    if when and datetime.fromisoformat(event["date_time"]) <= when:
        raise HTTPException(
            status.HTTP_422_UNPROCESSABLE_ENTITY, "The event would start before it goes live"
        )
    updated = reschedule("event", id, user, when)
    if when is None:
        background.add_task(release_due_content)
    return updated


@router.delete("/{id}", status_code=204)
def delete_event(id: str, user: UserProfile = Depends(get_current_user)) -> None:
    remove_own_content(user.id, "event", id)
