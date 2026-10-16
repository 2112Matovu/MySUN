import secrets
from datetime import datetime, timedelta, timezone

from fastapi import APIRouter, Header, HTTPException, status

from app.core.config import get_settings
from app.core.supabase_client import get_supabase_admin
from app.services.reminders import run_event_reminders
from app.services.scheduling import release_due_content

router = APIRouter(prefix="/internal", tags=["internal"], include_in_schema=False)


@router.post("/run-reminders")
def run_reminders(x_cron_secret: str | None = Header(default=None)) -> dict:
    """Lets an external scheduler (e.g. a Render cron job) trigger the event
    reminders and the release of scheduled posts when the API itself may be asleep. Disabled unless
    CRON_SECRET is set."""
    _check_secret(x_cron_secret)
    return {**run_event_reminders(), "released": release_due_content()}


def _check_secret(x_cron_secret: str | None) -> None:
    expected = get_settings().cron_secret
    if not expected:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Not found")
    if not x_cron_secret or not secrets.compare_digest(x_cron_secret, expected):
        raise HTTPException(status.HTTP_403_FORBIDDEN, "Bad secret")


@router.post("/purge-inactive")
def purge_inactive(x_cron_secret: str | None = Header(default=None), years: int = 2) -> dict:
    """Data retention (DR-05): deletes student accounts not seen for [years]
    (default two), judged by last_seen_at, or created_at when never seen.
    Staff roles are never purged automatically."""
    _check_secret(x_cron_secret)
    db = get_supabase_admin()
    cutoff = (datetime.now(timezone.utc) - timedelta(days=365 * max(years, 1))).isoformat()
    stale = (
        db.table("profiles").select("id,last_seen_at,created_at").eq("role", "student")
        .or_(f"last_seen_at.lt.{cutoff},and(last_seen_at.is.null,created_at.lt.{cutoff})")
        .execute().data
    )
    for row in stale:
        db.auth.admin.delete_user(row["id"])
    return {"purged": len(stale)}
