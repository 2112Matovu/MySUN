"""TOTP two-factor sign-in through Supabase Auth's MFA endpoints (GoTrue).

The user's own access token authorises every call, so these run as the user,
not as the service role. A sign-in becomes "aal2" (assurance level 2) once a
TOTP code has been verified; admin endpoints check that claim when
ADMIN_REQUIRE_2FA is on."""

import base64
import json
import logging

import requests

from app.core.config import get_settings

logger = logging.getLogger("mysun")

_TIMEOUT = 10


class MfaError(Exception):
    def __init__(self, message: str, status_code: int = 400):
        super().__init__(message)
        self.message, self.status_code = message, status_code


def _call(method: str, path: str, token: str, body: dict | None = None) -> dict:
    s = get_settings()
    try:
        res = requests.request(
            method,
            f"{s.supabase_url}/auth/v1{path}",
            headers={
                "apikey": s.supabase_anon_key,
                "Authorization": f"Bearer {token}",
                "Content-Type": "application/json",
            },
            data=json.dumps(body) if body is not None else None,
            timeout=_TIMEOUT,
        )
    except requests.RequestException as exc:
        logger.exception("Supabase MFA request failed")
        raise MfaError("Two-factor service unavailable", 502) from exc
    if not res.ok:
        try:
            message = res.json().get("msg") or res.json().get("message") or res.text
        except ValueError:
            message = res.text
        raise MfaError(str(message)[:200], 400 if res.status_code < 500 else 502)
    return res.json() if res.content else {}


def token_aal(token: str) -> str:
    """The `aal` claim of an already-validated Supabase access token."""
    try:
        payload = token.split(".")[1]
        payload += "=" * (-len(payload) % 4)
        return json.loads(base64.urlsafe_b64decode(payload)).get("aal", "aal1")
    except Exception:
        return "aal1"


def verified_totp_factor(token: str) -> str | None:
    user = _call("GET", "/user", token)
    for f in user.get("factors") or []:
        if f.get("factor_type") == "totp" and f.get("status") == "verified":
            return f["id"]
    return None


def enroll(token: str) -> dict:
    """Starts enrolment; returns the factor id and the secret/URI to put in an
    authenticator app. The factor counts only after the first verify()."""
    data = _call("POST", "/factors", token, {"factor_type": "totp", "friendly_name": "MySun admin"})
    totp = data.get("totp") or {}
    return {"factor_id": data["id"], "secret": totp.get("secret"), "uri": totp.get("uri")}


def verify(token: str, factor_id: str, code: str) -> dict:
    """Challenge + verify in one go. Returns the new (aal2) session:
    access_token, refresh_token, user."""
    challenge = _call("POST", f"/factors/{factor_id}/challenge", token, {})
    return _call(
        "POST", f"/factors/{factor_id}/verify", token,
        {"challenge_id": challenge["id"], "code": code},
    )
