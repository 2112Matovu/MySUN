from fastapi import APIRouter, Depends

from app.core.security import get_current_user
from app.schemas.misc import Notification
from app.schemas.user import UserProfile
from app.services.table_repo import TableRepo

router = APIRouter(prefix="/notifications", tags=["notifications"])
repo = TableRepo("notifications")


@router.get("", response_model=list[Notification])
def list_notifications(user: UserProfile = Depends(get_current_user)) -> list[dict]:
    return repo.list(order_by="created_at", desc=True, user_id=user.id)


@router.post("/{id}/read", response_model=Notification)
def mark_read(id: str, user: UserProfile = Depends(get_current_user)) -> dict:
    return repo.update(id, {"is_read": True})
