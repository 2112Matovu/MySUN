from datetime import datetime, timezone

from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel, Field

from app.core.security import get_current_user
from app.core.supabase_client import get_supabase_admin
from app.schemas.misc import Notification
from app.schemas.user import UserProfile
from app.services.notify import effective_prefs
from app.services.table_repo import TableRepo

router = APIRouter(prefix="/notifications", tags=["notifications"])
repo = TableRepo("notifications")


class NotificationPrefs(BaseModel):
    """Categories a user can switch on or off in their profile settings."""

    announcements: bool = True
    events: bool = True
    reminders: bool = True
    transport: bool = True


class DeviceRegistration(BaseModel):
    token: str = Field(min_length=20, max_length=4096)
    platform: str = Field(default="android", max_length=20)


class DeviceToken(BaseModel):
    token: str = Field(min_length=20, max_length=4096)


@router.get("", response_model=list[Notification])
def list_notifications(user: UserProfile = Depends(get_current_user)) -> list[dict]:
    return repo.list(order_by="created_at", desc=True, user_id=user.id)


@router.get("/preferences", response_model=NotificationPrefs)
def get_preferences(user: UserProfile = Depends(get_current_user)) -> dict:
    row = (
        get_supabase_admin()
        .table("profiles")
        .select("notification_prefs")
        .eq("id", user.id)
        .maybe_single()
        .execute()
    )
    return effective_prefs(row.data.get("notification_prefs") if row and row.data else None)


@router.put("/preferences", response_model=NotificationPrefs)
def set_preferences(body: NotificationPrefs, user: UserProfile = Depends(get_current_user)) -> dict:
    prefs = body.model_dump()
    get_supabase_admin().table("profiles").update({"notification_prefs": prefs}).eq(
        "id", user.id
    ).execute()
    return prefs


@router.post("/devices", status_code=204)
def register_device(body: DeviceRegistration, user: UserProfile = Depends(get_current_user)) -> None:
    """Saves this phone's push token. A token belongs to one user at a time,
    so signing in as someone else on the same phone moves it."""
    get_supabase_admin().table("device_tokens").upsert(
        {
            "token": body.token,
            "user_id": user.id,
            "platform": body.platform,
            "updated_at": datetime.now(timezone.utc).isoformat(),
        }
    ).execute()


@router.post("/devices/unregister", status_code=204)
def unregister_device(body: DeviceToken, user: UserProfile = Depends(get_current_user)) -> None:
    """Called on sign-out so a shared phone stops receiving the old user's pushes."""
    get_supabase_admin().table("device_tokens").delete().eq("token", body.token).eq(
        "user_id", user.id
    ).execute()


@router.post("/{id}/read", response_model=Notification)
def mark_read(id: str, user: UserProfile = Depends(get_current_user)) -> dict:
    result = (
        get_supabase_admin()
        .table("notifications")
        .update({"is_read": True})
        .eq("id", id)
        .eq("user_id", user.id)
        .execute()
    )
    if not result.data:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Notification not found")
    return result.data[0]
