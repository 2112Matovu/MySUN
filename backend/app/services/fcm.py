"""Firebase Cloud Messaging (HTTP v1) sender.

Needs FCM_SERVICE_ACCOUNT_JSON (the service-account key JSON itself, or a
path to the file). When it is unset, [is_configured] is False and nothing is
sent: in-app notifications still work, the phone just isn't pushed.
"""

import json
import logging
from functools import lru_cache
from typing import Literal

import requests
from google.auth.transport.requests import Request
from google.oauth2 import service_account

from app.core.config import get_settings

logger = logging.getLogger("mysun")

_SCOPE = "https://www.googleapis.com/auth/firebase.messaging"
SendResult = Literal["ok", "invalid", "error"]


@lru_cache
def _credentials() -> tuple[service_account.Credentials, str] | None:
    raw = get_settings().fcm_service_account_json
    if not raw:
        return None
    raw = raw.strip()
    info = json.loads(raw) if raw.startswith("{") else json.load(open(raw, encoding="utf-8"))
    creds = service_account.Credentials.from_service_account_info(info, scopes=[_SCOPE])
    return creds, info["project_id"]


def is_configured() -> bool:
    try:
        return _credentials() is not None
    except Exception:
        logger.exception("FCM service account is configured but unreadable")
        return False


def send(token: str, title: str, body: str, data: dict[str, str] | None = None) -> SendResult:
    """Sends one push. "invalid" means the token is dead and should be deleted."""
    loaded = _credentials()
    if loaded is None:
        return "error"
    creds, project_id = loaded
    if not creds.valid:
        creds.refresh(Request())
    message = {
        "message": {
            "token": token,
            "notification": {"title": title, "body": body},
            "data": data or {},
            "android": {"priority": "HIGH"},
        }
    }
    try:
        res = requests.post(
            f"https://fcm.googleapis.com/v1/projects/{project_id}/messages:send",
            headers={"Authorization": f"Bearer {creds.token}"},
            data=json.dumps(message),
            timeout=10,
        )
    except requests.RequestException:
        logger.exception("FCM request failed")
        return "error"
    if res.ok:
        return "ok"
    if res.status_code in (400, 404) and any(
        marker in res.text for marker in ("UNREGISTERED", "INVALID_ARGUMENT")
    ):
        return "invalid"
    logger.error("FCM rejected a message", extra={"status_code": res.status_code})
    return "error"
