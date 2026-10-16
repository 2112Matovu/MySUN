import logging

from fastapi import APIRouter, Depends, HTTPException, Request, status

from app.core.limiter import limiter
from app.core.security import get_current_user
from app.core.supabase_client import get_supabase_admin, get_supabase_anon
from app.schemas.user import (
    AuthResponse,
    GoogleLoginRequest,
    LoginRequest,
    PasswordResetRequest,
    RefreshRequest,
    SignUpRequest,
    UserProfile,
)

from app.services import audit

logger = logging.getLogger("mysun")

router = APIRouter(prefix="/auth", tags=["auth"])


def _load_profile(user_id: str) -> UserProfile:
    result = (
        get_supabase_admin().table("profiles").select("*").eq("id", user_id).maybe_single().execute()
    )
    if not result or not result.data:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Profile not found")
    return UserProfile.model_validate(result.data)


@router.post("/signup", response_model=AuthResponse)
@limiter.limit("5/minute")
def signup(request: Request, body: SignUpRequest) -> AuthResponse:
    """New accounts always start as students (§4.2) — only an admin can
    promote via PATCH /admin/users/{id}/role (§7.3). The `profiles` row is
    created by a DB trigger (see supabase/migrations/0001_init.sql)."""
    result = get_supabase_anon().auth.sign_up(
        {
            "email": body.email,
            "password": body.password,
            "options": {
                "data": {"name": body.name, "faculty": body.faculty, "program": body.program},
            },
        }
    )
    if result.session is None or result.user is None:
        raise HTTPException(
            status.HTTP_400_BAD_REQUEST,
            "Account created — check your email to confirm before signing in.",
        )
    return AuthResponse(
        access_token=result.session.access_token,
        refresh_token=result.session.refresh_token,
        user=_load_profile(result.user.id),
    )


@router.post("/login", response_model=AuthResponse)
@limiter.limit("8/minute")
def login(request: Request, body: LoginRequest) -> AuthResponse:
    try:
        result = get_supabase_anon().auth.sign_in_with_password(
            {"email": body.email, "password": body.password}
        )
    except Exception as exc:  # supabase-py raises AuthApiError on bad credentials
        raise HTTPException(status.HTTP_401_UNAUTHORIZED, "Incorrect email or password.") from exc

    return AuthResponse(
        access_token=result.session.access_token,
        refresh_token=result.session.refresh_token,
        user=_load_profile(result.user.id),
    )


@router.post("/google", response_model=AuthResponse)
@limiter.limit("8/minute")
def google_login(request: Request, body: GoogleLoginRequest) -> AuthResponse:
    """Exchanges a Google ID token (from the Flutter app's native/web
    `google_sign_in` flow) for a Supabase session. Requires the Google
    provider to be enabled in the Supabase dashboard with this app's OAuth
    client ID registered — see backend/README.md. First-time Google
    sign-ins get a `profiles` row auto-created by the same DB trigger as
    email sign-up (§ supabase/migrations/0001_init.sql), always as
    `student` role."""
    try:
        result = get_supabase_anon().auth.sign_in_with_id_token(
            {"provider": "google", "token": body.id_token}
        )
    except Exception as exc:
        raise HTTPException(status.HTTP_401_UNAUTHORIZED, "Google sign-in failed.") from exc

    return AuthResponse(
        access_token=result.session.access_token,
        refresh_token=result.session.refresh_token,
        user=_load_profile(result.user.id),
    )


@router.post("/refresh", response_model=AuthResponse)
@limiter.limit("20/minute")
def refresh(request: Request, body: RefreshRequest) -> AuthResponse:
    """Exchanges a still-valid refresh token for a new access/refresh pair.
    Called by the Flutter app's Dio interceptor on a 401 (`api_client.dart`)
    so an expired access token doesn't force a re-login mid-session."""
    try:
        result = get_supabase_anon().auth.refresh_session(body.refresh_token)
    except Exception as exc:
        raise HTTPException(
            status.HTTP_401_UNAUTHORIZED, "Session expired. Please sign in again."
        ) from exc

    if result.session is None or result.user is None:
        raise HTTPException(status.HTTP_401_UNAUTHORIZED, "Session expired. Please sign in again.")

    return AuthResponse(
        access_token=result.session.access_token,
        refresh_token=result.session.refresh_token,
        user=_load_profile(result.user.id),
    )


@router.get("/me", response_model=UserProfile)
def me(user: UserProfile = Depends(get_current_user)) -> UserProfile:
    return user


@router.post("/password-reset", status_code=202)
@limiter.limit("5/minute")
def password_reset(request: Request, body: PasswordResetRequest) -> dict:
    """Emails a reset link through Supabase Auth. Always answers 202, whether
    or not the address has an account, so it cannot be used to find out who
    is registered."""
    try:
        get_supabase_anon().auth.reset_password_for_email(body.email)
    except Exception:
        logger.exception("Password reset request failed")
    return {"status": "If an account exists for that email, a reset link has been sent."}


def _rows(table: str, column: str, user_id: str) -> list[dict]:
    return get_supabase_admin().table(table).select("*").eq(column, user_id).execute().data


@router.get("/me/export")
def export_my_data(user: UserProfile = Depends(get_current_user)) -> dict:
    """Everything MySun holds about the signed-in user, as JSON (FR-AUTH-08)."""
    return {
        "profile": user.model_dump(),
        "bookmarks": _rows("bookmarks", "user_id", user.id),
        "notifications": _rows("notifications", "user_id", user.id),
        "event_registrations": _rows("event_registrations", "user_id", user.id),
        "bookings": _rows("bookings", "student_id", user.id),
        "ratings": _rows("transport_ratings", "user_id", user.id),
        "submissions": _rows("publisher_submissions", "publisher_id", user.id),
        "devices": [
            {"platform": d.get("platform"), "updated_at": d.get("updated_at")}
            for d in _rows("device_tokens", "user_id", user.id)
        ],
    }


@router.delete("/me", status_code=204)
def delete_my_account(user: UserProfile = Depends(get_current_user)) -> None:
    """Permanently deletes the account (FR-AUTH-08). The auth user goes, and
    the profile with its bookmarks, notifications, registrations, bookings
    and submissions follow by cascade. Content already published stays live;
    ask an admin to remove it first if it should go too."""
    if user.role == "admin":
        raise HTTPException(
            status.HTTP_409_CONFLICT,
            "Super Admin accounts cannot delete themselves. Ask another Super Admin to change your role first.",
        )
    audit.record(user, "account_deleted", "user", user.id, {"email": user.email})
    get_supabase_admin().auth.admin.delete_user(user.id)
