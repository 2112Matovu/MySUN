from fastapi import APIRouter, Depends

from app.core.security import require_admin_level, require_super_admin
from app.core.supabase_client import get_supabase_admin
from app.schemas.admin import AdminAnalytics, RemovalRequest, RoleGrantRequest, VerifyRequest
from app.schemas.content import TransportProvider
from app.schemas.publisher import PublisherSubmission
from app.schemas.user import Role, UserProfile
from app.services.publisher_service import remove_content, submissions_repo
from app.services.table_repo import TableRepo

router = APIRouter(prefix="/admin", tags=["admin"])
profiles_repo = TableRepo("profiles")


@router.get("/moderation", response_model=list[PublisherSubmission])
def moderation_queue(_: UserProfile = Depends(require_admin_level)) -> list[dict]:
    """§5.3 Moderation Queue, adapted: publishing is immediate, so this is a
    review-and-remove list, not an approve/reject queue (§5.1). Open to both
    Super Admin and Minor Admin."""
    live = [
        row
        for status_ in ("published", "scheduled")
        for row in submissions_repo.list(order_by="updated_at", desc=True, status=status_)
    ]
    return sorted(live, key=lambda r: r["updated_at"], reverse=True)


@router.post("/moderation/{submission_id}/remove", response_model=PublisherSubmission)
def remove_submission(
    submission_id: str, body: RemovalRequest, _: UserProfile = Depends(require_admin_level)
) -> dict:
    submission = submissions_repo.get(submission_id)
    return remove_content(submission, body.reason, notify_publisher=True)


@router.patch("/transport/{provider_id}/verified", response_model=TransportProvider)
def set_transport_verified(
    provider_id: str, body: VerifyRequest, _: UserProfile = Depends(require_admin_level)
) -> dict:
    """The only way a boda listing becomes verified; new listings start
    unverified. Open to Super Admin and Minor Admin."""
    return TableRepo("transport_providers").update(provider_id, {"is_verified": body.is_verified})


@router.get("/users", response_model=list[UserProfile])
def list_users(role: Role | None = None, _: UserProfile = Depends(require_super_admin)) -> list[dict]:
    """§5.3 User Management — Super Admin only."""
    return profiles_repo.list(order_by="name", role=role)


@router.patch("/users/{user_id}/role", response_model=UserProfile)
def grant_role(
    user_id: str, body: RoleGrantRequest, _: UserProfile = Depends(require_super_admin)
) -> dict:
    """§7.3 Role Assignment — Super Admin only ("Grant Publisher Access" /
    "+ Add Minor Admin")."""
    return profiles_repo.update(user_id, {"role": body.new_role})


@router.get("/analytics", response_model=AdminAnalytics)
def analytics(_: UserProfile = Depends(require_super_admin)) -> dict:
    """§5.3 Analytics Dashboard — Super Admin only. Content counts are
    real; DAU/MAU/engagement are illustrative until real usage tracking
    exists, same as the Flutter mock's AdminAnalytics.mock."""
    admin = get_supabase_admin()
    announcements = len(admin.table("announcements").select("id").execute().data)
    events = len(admin.table("events").select("id").execute().data)
    publishers = len(admin.table("profiles").select("id").eq("role", "publisher").execute().data)
    total_users = len(admin.table("profiles").select("id").execute().data)
    return {
        "daily_active_users": 1240,
        "monthly_active_users": 3450,
        "total_users": total_users,
        "publisher_count": publishers,
        "announcements_published": announcements,
        "events_created": events,
        "avg_engagement_percent": 18.5,
        "api_online": True,
        "database_health_percent": 98.2,
        "storage_used_percent": 67,
    }
