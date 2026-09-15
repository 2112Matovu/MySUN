from fastapi import APIRouter, Depends, HTTPException, status

from app.core.security import get_current_user
from app.core.supabase_client import get_supabase_admin, get_supabase_anon
from app.schemas.user import AuthResponse, LoginRequest, SignUpRequest, UserProfile

router = APIRouter(prefix="/auth", tags=["auth"])


def _load_profile(user_id: str) -> UserProfile:
    result = (
        get_supabase_admin().table("profiles").select("*").eq("id", user_id).maybe_single().execute()
    )
    if not result or not result.data:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Profile not found")
    return UserProfile.model_validate(result.data)


@router.post("/signup", response_model=AuthResponse)
def signup(body: SignUpRequest) -> AuthResponse:
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
def login(body: LoginRequest) -> AuthResponse:
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


@router.get("/me", response_model=UserProfile)
def me(user: UserProfile = Depends(get_current_user)) -> UserProfile:
    return user
