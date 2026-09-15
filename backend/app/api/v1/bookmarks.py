from fastapi import APIRouter, Depends

from app.core.security import get_current_user
from app.core.supabase_client import get_supabase_admin
from app.schemas.misc import BookmarkToggleRequest
from app.schemas.user import UserProfile

router = APIRouter(prefix="/bookmarks", tags=["bookmarks"])


@router.get("")
def list_bookmarks(user: UserProfile = Depends(get_current_user)) -> list[dict]:
    result = (
        get_supabase_admin().table("bookmarks").select("*").eq("user_id", user.id).execute()
    )
    return result.data


@router.post("/toggle")
def toggle_bookmark(
    body: BookmarkToggleRequest, user: UserProfile = Depends(get_current_user)
) -> dict:
    admin = get_supabase_admin()
    existing = (
        admin.table("bookmarks")
        .select("id")
        .eq("user_id", user.id)
        .eq("content_type", body.content_type)
        .eq("content_id", body.content_id)
        .maybe_single()
        .execute()
    )
    if existing and existing.data:
        admin.table("bookmarks").delete().eq("id", existing.data["id"]).execute()
        return {"bookmarked": False}

    admin.table("bookmarks").insert(
        {
            "user_id": user.id,
            "content_type": body.content_type,
            "content_id": body.content_id,
        }
    ).execute()
    return {"bookmarked": True}
