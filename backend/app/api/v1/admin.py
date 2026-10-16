import csv
import io
from datetime import datetime, timedelta, timezone

from fastapi import APIRouter, Depends, Query
from fastapi.responses import Response

from app.core.security import require_admin_level, require_super_admin
from app.core.supabase_client import get_supabase_admin
from app.schemas.admin import (
    AdminAnalytics,
    AuditEntry,
    RemovalRequest,
    RoleGrantRequest,
    VerifyRequest,
)
from app.schemas.content import TransportProvider
from app.schemas.publisher import PublisherSubmission
from app.schemas.user import Role, UserProfile
from app.services import audit, usage
from app.services.content_filters import is_live_filter
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
    submission_id: str, body: RemovalRequest, admin: UserProfile = Depends(require_admin_level)
) -> dict:
    submission = submissions_repo.get(submission_id)
    removed = remove_content(submission, body.reason, notify_publisher=True)
    audit.record(
        admin, "content_removed", submission["type"], submission.get("content_id"),
        {"submission_id": submission_id, "title": submission.get("title"), "reason": body.reason},
    )
    return removed


@router.patch("/transport/{provider_id}/verified", response_model=TransportProvider)
def set_transport_verified(
    provider_id: str, body: VerifyRequest, admin: UserProfile = Depends(require_admin_level)
) -> dict:
    """The only way a boda listing becomes verified; new listings start
    unverified. Open to Super Admin and Minor Admin."""
    updated = TableRepo("transport_providers").update(provider_id, {"is_verified": body.is_verified})
    audit.record(admin, "verify_toggle", "transport", provider_id, {"is_verified": body.is_verified})
    return updated


@router.get("/users", response_model=list[UserProfile])
def list_users(role: Role | None = None, _: UserProfile = Depends(require_super_admin)) -> list[dict]:
    """§5.3 User Management — Super Admin only."""
    return profiles_repo.list(order_by="name", role=role)


@router.patch("/users/{user_id}/role", response_model=UserProfile)
def grant_role(
    user_id: str, body: RoleGrantRequest, admin: UserProfile = Depends(require_super_admin)
) -> dict:
    """§7.3 Role Assignment — Super Admin only ("Grant Publisher Access" /
    "+ Add Minor Admin")."""
    before = profiles_repo.get(user_id)
    updated = profiles_repo.update(user_id, {"role": body.new_role})
    audit.record(
        admin, "role_change", "user", user_id,
        {"from": before.get("role"), "to": body.new_role, "name": before.get("name")},
    )
    return updated


_CSV_COLUMNS = ["id", "name", "email", "role", "student_id", "faculty", "program", "created_at"]


def _csv_safe(value):
    """Guards against spreadsheet formula injection from user-typed values."""
    text = "" if value is None else str(value)
    return "'" + text if text[:1] in ("=", "+", "-", "@") else text


@router.get("/users/export.csv")
def export_users(admin: UserProfile = Depends(require_super_admin)) -> Response:
    """Super Admin CSV export of all users (FR-ADM-06)."""
    rows = profiles_repo.list(order_by="name")
    out = io.StringIO()
    writer = csv.writer(out)
    writer.writerow(_CSV_COLUMNS)
    for row in rows:
        writer.writerow([_csv_safe(row.get(col)) for col in _CSV_COLUMNS])
    audit.record(admin, "users_exported", "user", None, {"count": len(rows)})
    return Response(
        out.getvalue(),
        media_type="text/csv",
        headers={"Content-Disposition": 'attachment; filename="mysun-users.csv"'},
    )


@router.get("/audit", response_model=list[AuditEntry])
def audit_log(
    limit: int = Query(100, ge=1, le=500), _: UserProfile = Depends(require_super_admin)
) -> list[dict]:
    """Newest-first log of administrator actions (FR-ADM-05)."""
    return (
        get_supabase_admin()
        .table("audit_log")
        .select("*")
        .order("created_at", desc=True)
        .limit(limit)
        .execute()
        .data
    )


@router.get("/analytics", response_model=AdminAnalytics)
def analytics(_: UserProfile = Depends(require_super_admin)) -> dict:
    """§5.3 Analytics Dashboard — Super Admin only. Everything is real:
    live content counts (scheduled items excluded) and DAU/MAU from
    profiles.last_seen_at. Database and storage health are not measured
    here and are reported as nominal."""
    db = get_supabase_admin()
    live = is_live_filter()
    announcements = len(db.table("announcements").select("id").or_(live).execute().data)
    events = len(db.table("events").select("id").or_(live).execute().data)
    publishers = len(db.table("profiles").select("id").eq("role", "publisher").execute().data)
    total_users = len(db.table("profiles").select("id").execute().data)
    now = datetime.now(timezone.utc)
    dau = usage.count_active_since(now - timedelta(days=1))
    mau = usage.count_active_since(now - timedelta(days=30))
    return {
        "daily_active_users": dau,
        "monthly_active_users": mau,
        "total_users": total_users,
        "publisher_count": publishers,
        "announcements_published": announcements,
        "events_created": events,
        # Share of all users seen in the last 30 days.
        "avg_engagement_percent": round(mau / total_users * 100, 1) if total_users else 0.0,
        "api_online": True,
        "database_health_percent": 100.0,
        "storage_used_percent": 0.0,
    }
