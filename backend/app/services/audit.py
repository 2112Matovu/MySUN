"""Audit log of administrator actions. Recording never breaks the action
being recorded: failures are logged and swallowed."""

import logging

from app.core.supabase_client import get_supabase_admin
from app.schemas.user import UserProfile

logger = logging.getLogger("mysun")


def record(
    actor: UserProfile | None,
    action: str,
    target_type: str | None = None,
    target_id: str | None = None,
    detail: dict | None = None,
) -> None:
    try:
        get_supabase_admin().table("audit_log").insert(
            {
                "actor_id": actor.id if actor else None,
                "actor_name": actor.name if actor else None,
                "action": action,
                "target_type": target_type,
                "target_id": target_id,
                "detail": detail or {},
            }
        ).execute()
    except Exception:
        logger.exception("Audit log write failed", extra={"audit_action": action})
