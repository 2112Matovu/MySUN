"""New boda listings start unverified; only admins can flip the flag."""

from app.api.v1 import transport as transport_module


def test_create_forces_unverified_even_if_client_sends_true(client, as_role, monkeypatch):
    saved = {}

    def fake_create(data):
        saved.update(data)
        return {"id": "t1", "rating": 0, "rating_count": 0, **data}

    monkeypatch.setattr(transport_module.repo, "create", fake_create)
    monkeypatch.setattr(transport_module, "record_publish", lambda **k: None)
    as_role("publisher")
    res = client.post(
        "/api/v1/transport",
        json={"name": "Rider", "phone_number": "0700000000", "is_verified": True},
    )
    assert res.status_code == 200
    assert saved["is_verified"] is False
    assert res.json()["is_verified"] is False
