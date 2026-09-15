import pytest

from tests.fakes import FakeAuth, FakeSupabaseClient

DEFAULT_PROFILE = {
    "id": "usr-1",
    "name": "Test User",
    "email": "test@sun.ac.ug",
    "role": "student",
}


@pytest.fixture
def fake_supabase(monkeypatch):
    def _install(*, fail: bool = False, no_session: bool = False, profile: dict | None = None):
        fake_client = FakeSupabaseClient(
            FakeAuth(fail=fail, no_session=no_session), profile or DEFAULT_PROFILE
        )
        monkeypatch.setattr("app.api.v1.auth.get_supabase_admin", lambda: fake_client)
        monkeypatch.setattr("app.api.v1.auth.get_supabase_anon", lambda: fake_client)
        return fake_client

    return _install


def test_login_success(client, fake_supabase):
    fake_supabase()
    res = client.post(
        "/api/v1/auth/login", json={"email": "test@sun.ac.ug", "password": "whatever"}
    )
    assert res.status_code == 200
    body = res.json()
    assert body["access_token"] == "fake-access-token"
    assert body["refresh_token"] == "fake-refresh-token"
    assert body["user"]["email"] == "test@sun.ac.ug"


def test_login_bad_credentials(client, fake_supabase):
    fake_supabase(fail=True)
    res = client.post(
        "/api/v1/auth/login", json={"email": "test@sun.ac.ug", "password": "wrong"}
    )
    assert res.status_code == 401


def test_signup_success(client, fake_supabase):
    fake_supabase()
    res = client.post(
        "/api/v1/auth/signup",
        json={"name": "Test User", "email": "test@sun.ac.ug", "password": "whatever"},
    )
    assert res.status_code == 200


def test_signup_requires_email_confirmation(client, fake_supabase):
    """Supabase returns no session for a signup pending email confirmation
    (see backend/README.md) — that must surface as 400, not a crash."""
    fake_supabase(no_session=True)
    res = client.post(
        "/api/v1/auth/signup",
        json={"name": "Test User", "email": "new@sun.ac.ug", "password": "whatever"},
    )
    assert res.status_code == 400


def test_google_login_success(client, fake_supabase):
    fake_supabase()
    res = client.post("/api/v1/auth/google", json={"id_token": "some-google-id-token"})
    assert res.status_code == 200


def test_google_login_failure(client, fake_supabase):
    fake_supabase(fail=True)
    res = client.post("/api/v1/auth/google", json={"id_token": "bogus"})
    assert res.status_code == 401


def test_refresh_success(client, fake_supabase):
    fake_supabase()
    res = client.post("/api/v1/auth/refresh", json={"refresh_token": "some-refresh-token"})
    assert res.status_code == 200
    assert res.json()["access_token"] == "fake-access-token"


def test_refresh_failure(client, fake_supabase):
    fake_supabase(fail=True)
    res = client.post("/api/v1/auth/refresh", json={"refresh_token": "bogus"})
    assert res.status_code == 401
