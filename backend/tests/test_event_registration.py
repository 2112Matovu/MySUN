"""Event registration endpoints (rpc-backed, so atomic in Postgres)."""

import pytest

from app.api.v1 import events as events_module


class _Rpc:
    def __init__(self, data):
        self._data = data

    def execute(self):
        class R:
            data = self._data

        return R()


class _Db:
    def __init__(self, result):
        self.result, self.calls = result, []

    def rpc(self, fn, params):
        self.calls.append((fn, params))
        return _Rpc(self.result)


@pytest.fixture
def db(monkeypatch):
    def _make(result):
        d = _Db(result)
        monkeypatch.setattr(events_module, "get_supabase_admin", lambda: d)
        return d

    return _make


def test_register_requires_login(client):
    assert client.post("/api/v1/events/e1/register").status_code in (401, 403)


def test_register_returns_updated_count(client, as_role, db):
    d = db({"registered": True, "registered_count": 5, "status": "ok"})
    as_role("student", "u1")
    res = client.post("/api/v1/events/e1/register")
    assert res.status_code == 200
    assert res.json() == {"registered": True, "registered_count": 5}
    assert d.calls == [("register_for_event", {"p_event_id": "e1", "p_user_id": "u1"})]


def test_register_full_event_is_409(client, as_role, db):
    db({"registered": False, "registered_count": 10, "status": "full"})
    as_role("student")
    assert client.post("/api/v1/events/e1/register").status_code == 409


def test_register_unknown_event_is_404(client, as_role, db):
    db({"registered": False, "registered_count": 0, "status": "not_found"})
    as_role("student")
    assert client.post("/api/v1/events/nope/register").status_code == 404


def test_unregister_uses_unregister_function(client, as_role, db):
    d = db({"registered": False, "registered_count": 4, "status": "ok"})
    as_role("student", "u1")
    res = client.delete("/api/v1/events/e1/register")
    assert res.json() == {"registered": False, "registered_count": 4}
    assert d.calls[0][0] == "unregister_from_event"
