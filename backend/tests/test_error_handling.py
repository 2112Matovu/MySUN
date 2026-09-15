from app.api.v1 import events as events_module


def test_unhandled_exception_returns_generic_500(client, monkeypatch):
    """A route-level crash (e.g. a malformed-UUID Postgres error, hit for
    real in backend/README.md's history) must never leak internals to the
    client — app/main.py's global handler is what guarantees that."""

    def _boom(_id):
        raise RuntimeError("internal detail that must never reach the client")

    monkeypatch.setattr(events_module.repo, "get", _boom)

    res = client.get("/api/v1/events/anything")

    assert res.status_code == 500
    assert res.json() == {"detail": "Internal server error"}
    assert "internal detail" not in res.text
    assert "X-Request-ID" in res.headers
