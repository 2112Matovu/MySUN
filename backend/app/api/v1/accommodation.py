from fastapi import APIRouter, Depends

from app.core.security import get_current_user, require_publisher
from app.schemas.content import Accommodation, AccommodationCreate, AccommodationType
from app.schemas.user import UserProfile
from app.services.publisher_service import record_publish, remove_own_content
from app.services.table_repo import TableRepo

router = APIRouter(prefix="/accommodation", tags=["accommodation"])
repo = TableRepo("accommodation_listings")


@router.get("", response_model=list[Accommodation])
def list_accommodation(type: AccommodationType | None = None) -> list[dict]:
    return repo.list(order_by="id", desc=True, type=type)


@router.get("/{id}", response_model=Accommodation)
def get_accommodation(id: str) -> dict:
    return repo.get(id)


@router.post("", response_model=Accommodation)
def create_accommodation(
    body: AccommodationCreate, user: UserProfile = Depends(require_publisher)
) -> dict:
    """Publishes immediately, unverified/gazetted status as submitted — an
    admin can still remove it later (§5.1)."""
    payload = body.model_dump(mode="json", exclude={"draft_id"})
    payload["publisher_name"] = user.faculty or user.name
    created = repo.create(payload)
    record_publish(
        publisher_id=user.id,
        publisher_name=payload["publisher_name"],
        type="accommodation",
        title=created["name"],
        content_id=created["id"],
        draft_id=body.draft_id,
    )
    return created


@router.delete("/{id}", status_code=204)
def delete_accommodation(id: str, user: UserProfile = Depends(get_current_user)) -> None:
    remove_own_content(user.id, "accommodation", id)
