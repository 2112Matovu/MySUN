from typing import Literal

from pydantic import BaseModel, EmailStr

# Mirrors student_app/lib/data/models/user_role.dart.
Role = Literal["student", "publisher", "admin", "minor_admin"]


class UserProfile(BaseModel):
    id: str
    name: str
    email: EmailStr
    role: Role = "student"
    student_id: str | None = None
    faculty: str | None = None
    program: str | None = None
    image_url: str | None = None


class SignUpRequest(BaseModel):
    name: str
    email: EmailStr
    password: str
    faculty: str | None = None
    program: str | None = None


class LoginRequest(BaseModel):
    email: EmailStr
    password: str


class PasswordResetRequest(BaseModel):
    email: EmailStr


class RefreshRequest(BaseModel):
    refresh_token: str


class GoogleLoginRequest(BaseModel):
    """The Google-issued ID token from the Flutter app's `google_sign_in`
    call, exchanged server-side for a Supabase session."""

    id_token: str


class AuthResponse(BaseModel):
    access_token: str
    refresh_token: str | None = None
    user: UserProfile
    # Set when an admin-level account has two-factor on: the token is only a
    # first-factor session and the app must POST /auth/mfa/verify next.
    mfa_required: bool = False
    mfa_factor_id: str | None = None


class MfaVerifyRequest(BaseModel):
    factor_id: str
    code: str


class MfaStatus(BaseModel):
    enrolled: bool
    verified_this_session: bool
    required: bool


class MfaEnrollment(BaseModel):
    factor_id: str
    secret: str | None = None
    uri: str | None = None
