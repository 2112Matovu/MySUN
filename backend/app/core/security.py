from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer

from app.core.config import get_settings
from app.core.supabase_client import get_supabase_admin
from app.services.mfa import token_aal
from app.schemas.user import UserProfile
from app.services.usage import touch_last_seen

_bearer = HTTPBearer(auto_error=False)


async def get_current_user(
    credentials: HTTPAuthorizationCredentials | None = Depends(_bearer),
) -> UserProfile:
    """Validates the bearer token against Supabase Auth's own `/auth/v1/user`
    endpoint (rather than decoding a shared JWT secret locally) — this works
    regardless of whether the project signs tokens with a legacy shared
    secret or Supabase's newer per-project signing keys. Then loads the
    matching `profiles` row (role, faculty, etc. — Supabase Auth itself only
    knows email)."""
    if credentials is None:
        raise HTTPException(status.HTTP_401_UNAUTHORIZED, "Missing bearer token")

    admin = get_supabase_admin()
    try:
        auth_user = admin.auth.get_user(credentials.credentials).user
    except Exception as exc:
        raise HTTPException(status.HTTP_401_UNAUTHORIZED, "Invalid or expired token") from exc

    if not auth_user:
        raise HTTPException(status.HTTP_401_UNAUTHORIZED, "Invalid or expired token")

    result = (
        admin.table("profiles").select("*").eq("id", auth_user.id).maybe_single().execute()
    )
    if not result or not result.data:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Profile not found for this account")

    touch_last_seen(result.data)
    return UserProfile.model_validate(result.data)


async def get_optional_user(
    credentials: HTTPAuthorizationCredentials | None = Depends(_bearer),
) -> UserProfile | None:
    """Like get_current_user, but anonymous or bad tokens give None instead
    of an error. For public endpoints that behave a little differently for
    their owner (e.g. previewing a scheduled post)."""
    if credentials is None:
        return None
    try:
        return await get_current_user(credentials)
    except HTTPException:
        return None


async def get_token(
    credentials: HTTPAuthorizationCredentials | None = Depends(_bearer),
) -> str:
    if credentials is None:
        raise HTTPException(status.HTTP_401_UNAUTHORIZED, "Missing bearer token")
    return credentials.credentials


def require_role(*roles: str):
    """§4.5 / §7.1-style role gate — same shape as the Flutter router's
    redirect guards (student_app/lib/core/router/app_router.dart)."""

    async def _dependency(
        user: UserProfile = Depends(get_current_user),
        credentials: HTTPAuthorizationCredentials | None = Depends(_bearer),
    ) -> UserProfile:
        if user.role not in roles:
            raise HTTPException(status.HTTP_403_FORBIDDEN, "Not allowed for this role")
        if (
            get_settings().admin_require_2fa
            and user.role in ("admin", "minor_admin")
            and (credentials is None or token_aal(credentials.credentials) != "aal2")
        ):
            raise HTTPException(status.HTTP_403_FORBIDDEN, "Two-factor authentication required")
        return user

    return _dependency


require_publisher = require_role("publisher")
require_admin_level = require_role("admin", "minor_admin")
require_super_admin = require_role("admin")
