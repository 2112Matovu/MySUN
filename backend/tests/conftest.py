import os

# Must be set before `app.main` (and therefore `app.core.config.get_settings`)
# is imported anywhere below — pydantic-settings reads real values out of
# backend/.env otherwise, and we never want a test run touching the live
# Supabase project. 127.0.0.1:1 (not a real DNS name) means any code path
# that slips through un-mocked and actually calls Supabase fails instantly
# with "connection refused" instead of hanging on a DNS lookup.
os.environ.setdefault("SUPABASE_URL", "http://127.0.0.1:1")
os.environ.setdefault("SUPABASE_ANON_KEY", "test-anon-key")
os.environ.setdefault("SUPABASE_SERVICE_ROLE_KEY", "test-service-role-key")
os.environ.setdefault("APP_ENV", "development")

import pytest
from fastapi.testclient import TestClient

from app.core.limiter import limiter
from app.core.security import get_current_user
from app.main import app
from app.schemas.user import UserProfile


def make_user(role: str, user_id: str = "usr-test") -> UserProfile:
    return UserProfile(id=user_id, name="Test User", email="test@sun.ac.ug", role=role)


@pytest.fixture
def client():
    # raise_server_exceptions=False so a route crash comes back as the real
    # sanitized 500 response (what a real client sees, via app/main.py's
    # global handler) instead of re-raising into the test process.
    return TestClient(app, raise_server_exceptions=False)


@pytest.fixture
def as_role():
    """Overrides `get_current_user` so a route's role gate sees the given
    role without needing a real bearer token or a Supabase round-trip."""

    def _set(role: str, user_id: str = "usr-test") -> UserProfile:
        user = make_user(role, user_id)
        app.dependency_overrides[get_current_user] = lambda: user
        return user

    return _set


@pytest.fixture(autouse=True)
def _reset_state():
    yield
    app.dependency_overrides.clear()
    limiter.reset()
