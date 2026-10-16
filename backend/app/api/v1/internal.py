import secrets

from fastapi import APIRouter, Header, HTTPException, status

from app.core.config import get_settings
from app.services.reminders import run_event_reminders
from app.services.scheduling import release_due_content

router = APIRouter(prefix="/internal", tags=["internal"], include_in_schema=False)


@router.post("/run-reminders")
def run_reminders(x_cron_secret: str | None = Header(default=None)) -> dict:
    """Lets an external scheduler (e.g. a Render cron job) trigger the event
    reminders and the release of scheduled posts when the API itself may be asleep. Disabled unless
    CRON_SECRET is set."""
    expected = get_settings().cron_secret
    if not expected:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Not found")
    if not x_cron_secret or not secrets.compare_digest(x_cron_secret, expected):
        raise HTTPException(status.HTTP_403_FORBIDDEN, "Bad secret")
    return {**run_event_reminders(), "released": release_due_content()}
