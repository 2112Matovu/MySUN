import pytest

from tests.fakes import FakeAuth, FakeSupabaseClient


@pytest.fixture
def fake_supabase_always_rejects(monkeypatch):
    fake_client = FakeSupabaseClient(FakeAuth(fail=True), profile={})
    monkeypatch.setattr("app.api.v1.auth.get_supabase_admin", lambda: fake_client)
    monkeypatch.setattr("app.api.v1.auth.get_supabase_anon", lambda: fake_client)


def test_login_is_rate_limited(client, fake_supabase_always_rejects):
    """auth.py caps /auth/login at 8/minute per IP (see backend/README.md)
    to blunt brute-force/credential-stuffing."""
    statuses = [
        client.post(
            "/api/v1/auth/login", json={"email": "x@sun.ac.ug", "password": "wrong"}
        ).status_code
        for _ in range(10)
    ]
    assert statuses[:8] == [401] * 8
    assert statuses[8] == 429
    assert statuses[9] == 429
