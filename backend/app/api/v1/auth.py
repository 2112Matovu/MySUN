import logging
import time

from fastapi import APIRouter, Depends, HTTPException, Request, status

from app.core.limiter import limiter
from app.core.config import get_settings
from app.core.security import get_current_user, get_token
from app.core.supabase_client import get_supabase_admin, get_supabase_anon
from app.schemas.user import (
    AuthResponse,
    GoogleLoginRequest,
    LoginRequest,
    MfaEnrollment,
    MfaStatus,
    MfaVerifyRequest,
    PasswordResetRequest,
    RefreshRequest,
    SignUpRequest,
    UserProfile,
)

from app.services import audit, mfa

logger = logging.getLogger("mysun")

router = APIRouter(prefix="/auth", tags=["auth"])


# Per-email lockout on repeated wrong passwords (NFR-SEC-10). In-process, so
# with several workers each counts separately; the per-IP limiter and
# Supabase's own limits still apply on top.
_MAX_FAILS = 5
_FAIL_WINDOW = 15 * 60
_failures: dict[str, list[float]] = {}


def _check_lockout(email: str) -> None:
    now = time.monotonic()
    recent = [t for t in _failures.get(email, []) if now - t < _FAIL_WINDOW]
    _failures[email] = recent
    if len(recent) >= _MAX_FAILS:
        wait = int((_FAIL_WINDOW - (now - recent[0])) // 60) + 1
        raise HTTPException(
            status.HTTP_429_TOO_MANY_REQUESTS,
            f"Too many failed attempts. Try again in about {wait} minute{'s' if wait != 1 else ''}.",
        )


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
    email = body.email.lower()
    _check_lockout(email)
    try:
        result = get_supabase_anon().auth.sign_in_with_password(
            {"email": body.email, "password": body.password}
        )
    except Exception as exc:  # supabase-py raises AuthApiError on bad credentials
        _failures.setdefault(email, []).append(time.monotonic())
        raise HTTPException(status.HTTP_401_UNAUTHORIZED, "Incorrect email or password.") from exc
    _failures.pop(email, None)

    user = _load_profile(result.user.id)
    response = AuthResponse(
        access_token=result.session.access_token,
        refresh_token=result.session.refresh_token,
        user=user,
    )
    if user.role in ("admin", "minor_admin"):
        try:
            factor = mfa.verified_totp_factor(result.session.access_token)
        except mfa.MfaError:
            logger.exception("Could not check two-factor status at login")
            factor = None
        if factor:
            response.mfa_required = True
            response.mfa_factor_id = factor
    return response


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


def _mfa_error(exc: mfa.MfaError) -> HTTPException:
    return HTTPException(exc.status_code, exc.message)


@router.get("/mfa/status", response_model=MfaStatus)
def mfa_status(
    user: UserProfile = Depends(get_current_user), token: str = Depends(get_token)
) -> MfaStatus:
    try:
        enrolled = mfa.verified_totp_factor(token) is not None
    except mfa.MfaError as exc:
        raise _mfa_error(exc) from exc
    return MfaStatus(
        enrolled=enrolled,
        verified_this_session=mfa.token_aal(token) == "aal2",
        required=get_settings().admin_require_2fa and user.role in ("admin", "minor_admin"),
    )


@router.post("/mfa/enroll", response_model=MfaEnrollment)
def mfa_enroll(
    user: UserProfile = Depends(get_current_user), token: str = Depends(get_token)
) -> MfaEnrollment:
    """Starts TOTP enrolment for an admin-level account. Scan or type the
    returned secret into an authenticator app, then confirm with
    POST /auth/mfa/verify."""
    if user.role not in ("admin", "minor_admin"):
        raise HTTPException(status.HTTP_403_FORBIDDEN, "Two-factor is for admin accounts")
    try:
        return MfaEnrollment(**mfa.enroll(token))
    except mfa.MfaError as exc:
        raise _mfa_error(exc) from exc


@router.post("/mfa/verify", response_model=AuthResponse)
@limiter.limit("10/minute")
def mfa_verify(
    request: Request,
    body: MfaVerifyRequest,
    user: UserProfile = Depends(get_current_user),
    token: str = Depends(get_token),
) -> AuthResponse:
    """Checks a 6-digit code. Used both to finish enrolment and as the second
    step of sign-in; returns the upgraded (aal2) session."""
    try:
        session = mfa.verify(token, body.factor_id, body.code.strip())
    except mfa.MfaError as exc:
        raise HTTPException(status.HTTP_401_UNAUTHORIZED, "That code didn't work. Try the newest one.") from exc
    audit.record(user, "mfa_verified", "user", user.id)
    return AuthResponse(
        access_token=session["access_token"],
        refresh_token=session.get("refresh_token"),
        user=user,
    )
