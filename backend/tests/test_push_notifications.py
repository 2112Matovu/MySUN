"""Push delivery, category preferences, removal notices and event reminders."""

from datetime import datetime, timedelta, timezone

import pytest

from app.api.v1 import admin as admin_module
from app.api.v1 import internal as internal_module
from app.api.v1 import notifications as notifications_module
from app.services import notify as notify_module
from app.services import publisher_service
from app.services import reminders as reminders_module
from tests.test_booking_rating_services import _Db

TOKEN = "t" * 30


@pytest.fixture
def db(monkeypatch):
    d = _Db()
    d.tables["profiles"] = [
        {"id": "u1", "name": "One", "notification_prefs": {}},
        {"id": "u2", "name": "Two", "notification_prefs": {"events": False, "reminders": False}},
        {"id": "pub", "name": "Pub"},
    ]
    for mod in (notify_module, notifications_module, reminders_module):
        monkeypatch.setattr(mod, "get_supabase_admin", lambda: d)
    monkeypatch.setattr(publisher_service, "TableRepo", lambda t: _NoopRepo())
    monkeypatch.setattr(notify_module.fcm, "is_configured", lambda: False)
    return d


class _NoopRepo:
    def delete(self, _id):
        pass


def _who(db, **where):
    return sorted(
        n["user_id"]
        for n in db.tables.get("notifications", [])
        if all(n.get(k) == v for k, v in where.items())
    )


# ── category preferences ─────────────────────────────────────────────────
def test_preferences_default_to_all_on(client, as_role, db):
    as_role("student", "u1")
    assert client.get("/api/v1/notifications/preferences").json() == {
        "announcements": True, "events": True, "reminders": True, "transport": True,
    }


def test_preferences_can_be_saved_and_read_back(client, as_role, db):
    as_role("student", "u1")
    body = {"announcements": False, "events": True, "reminders": True, "transport": False}
    assert client.put("/api/v1/notifications/preferences", json=body).json() == body
    assert db.tables["profiles"][0]["notification_prefs"] == body
    assert client.get("/api/v1/notifications/preferences").json() == body


def test_switched_off_category_is_not_delivered(db):
    notify_module.notify_users(["u1", "u2"], title="t", body="b", type="event")
    assert _who(db, type="event") == ["u1"]


def test_system_notices_ignore_preferences(db):
    notify_module.notify_users(["u2"], title="t", body="b", type="system")
    assert _who(db, type="system") == ["u2"]


# ── push to devices ──────────────────────────────────────────────────────
def test_push_goes_to_each_registered_device_and_dead_tokens_are_dropped(db, monkeypatch):
    db.tables["device_tokens"] = [
        {"token": "good" * 8, "user_id": "u1"},
        {"token": "dead" * 8, "user_id": "u1"},
    ]
    sent = []

    def fake_send(token, title, body, data=None):
        sent.append((token, title, data))
        return "invalid" if token.startswith("dead") else "ok"

    monkeypatch.setattr(notify_module.fcm, "is_configured", lambda: True)
    monkeypatch.setattr(notify_module.fcm, "send", fake_send)
    notify_module.notify_users(["u1"], title="Hi", body="b", type="announcement", related_id="a1")
    assert {s[0] for s in sent} == {"good" * 8, "dead" * 8}
    assert sent[0][2] == {"type": "announcement", "related_id": "a1"}
    assert [t["token"] for t in db.tables["device_tokens"]] == ["good" * 8]


def test_push_is_skipped_when_category_is_off(db, monkeypatch):
    db.tables["device_tokens"] = [{"token": "x" * 30, "user_id": "u2"}]
    sent = []
    monkeypatch.setattr(notify_module.fcm, "is_configured", lambda: True)
    monkeypatch.setattr(notify_module.fcm, "send", lambda *a, **k: sent.append(a) or "ok")
    notify_module.notify_users(["u2"], title="t", body="b", type="event")
    assert sent == []


def test_device_register_and_unregister(client, as_role, db):
    as_role("student", "u1")
    assert client.post("/api/v1/notifications/devices", json={"token": TOKEN}).status_code == 204
    assert db.tables["device_tokens"][0]["user_id"] == "u1"
    as_role("student", "u2")
    client.post("/api/v1/notifications/devices/unregister", json={"token": TOKEN})
    assert len(db.tables["device_tokens"]) == 1  # someone else's token is untouched
    as_role("student", "u1")
    client.post("/api/v1/notifications/devices/unregister", json={"token": TOKEN})
    assert db.tables["device_tokens"] == []


def test_device_token_must_look_real(client, as_role, db):
    as_role("student", "u1")
    assert client.post("/api/v1/notifications/devices", json={"token": "short"}).status_code == 422


# ── removal notice ───────────────────────────────────────────────────────
def _submission():
    return {"id": "s1", "type": "announcement", "title": "Free pizza", "content_id": "c1",
            "publisher_id": "pub", "status": "published"}


def test_admin_removal_notifies_the_publisher_with_the_reason(client, as_role, db, monkeypatch):
    sub = _submission()
    monkeypatch.setattr(admin_module.submissions_repo, "get", lambda _id: sub)
    monkeypatch.setattr(
        publisher_service.submissions_repo, "update", lambda _id, data: {**sub, **data}
    )
    as_role("admin", "a1")
    res = client.post("/api/v1/admin/moderation/s1/remove", json={"reason": "Spam"})
    assert res.status_code == 200
    [note] = db.tables["notifications"]
    assert note["user_id"] == "pub" and note["type"] == "system"
    assert "Free pizza" in note["body"] and "Reason: Spam" in note["body"]


def test_self_removal_does_not_send_a_notice(db, monkeypatch):
    monkeypatch.setattr(publisher_service.submissions_repo, "update", lambda _id, d: d)
    publisher_service.remove_content(_submission(), "Removed by the publisher.")
    assert db.tables.get("notifications", []) == []


# ── event reminders ──────────────────────────────────────────────────────
NOW = datetime(2030, 1, 1, 12, 0, tzinfo=timezone.utc)


def _event(db, eid, hours_ahead):
    db.tables.setdefault("events", []).append({
        "id": eid, "title": f"Event {eid}", "venue": "Hall",
        "date_time": (NOW + timedelta(hours=hours_ahead)).isoformat(),
    })


def test_day_and_hour_reminders_go_to_registered_and_bookmarked_users(db):
    _event(db, "e1", 20)
    db.tables["event_registrations"] = [{"event_id": "e1", "user_id": "u1"}]
    db.tables["bookmarks"] = [{"content_type": "event", "content_id": "e1", "user_id": "pub"}]

    assert reminders_module.run_event_reminders(NOW) == {"day": 2, "hour": 0}
    assert _who(db, type="reminder") == ["pub", "u1"]
    assert "20 hours" in db.tables["notifications"][0]["title"]

    later = NOW + timedelta(hours=19, minutes=30)
    assert reminders_module.run_event_reminders(later) == {"day": 0, "hour": 2}
    assert "30 minutes" in db.tables["notifications"][-1]["title"]


def test_reminders_are_sent_once_per_kind(db):
    _event(db, "e1", 5)
    db.tables["event_registrations"] = [{"event_id": "e1", "user_id": "u1"}]
    assert reminders_module.run_event_reminders(NOW)["day"] == 1
    assert reminders_module.run_event_reminders(NOW + timedelta(minutes=5)) == {"day": 0, "hour": 0}
    assert len(db.tables["notifications"]) == 1


def test_reminders_ignore_far_future_past_and_unfollowed_events(db):
    _event(db, "far", 48)
    _event(db, "past", -2)
    _event(db, "nobody", 3)
    db.tables["event_registrations"] = [
        {"event_id": "far", "user_id": "u1"}, {"event_id": "past", "user_id": "u1"},
    ]
    assert reminders_module.run_event_reminders(NOW) == {"day": 0, "hour": 0}
    assert db.tables.get("notifications", []) == []


def test_reminder_respects_the_reminders_preference(db):
    _event(db, "e1", 3)
    db.tables["event_registrations"] = [{"event_id": "e1", "user_id": "u2"}]
    reminders_module.run_event_reminders(NOW)
    assert db.tables.get("notifications", []) == []


# ── cron endpoint ────────────────────────────────────────────────────────
def test_cron_endpoint_is_off_without_a_secret(client, monkeypatch):
    monkeypatch.setattr(internal_module, "get_settings", lambda: type("S", (), {"cron_secret": None})())
    assert client.post("/api/v1/internal/run-reminders").status_code == 404


def test_cron_endpoint_checks_the_secret(client, monkeypatch):
    monkeypatch.setattr(internal_module, "get_settings", lambda: type("S", (), {"cron_secret": "s3cret"})())
    monkeypatch.setattr(internal_module, "run_event_reminders", lambda: {"day": 0, "hour": 0})
    monkeypatch.setattr(internal_module, "release_due_content", lambda: 3)
    assert client.post("/api/v1/internal/run-reminders").status_code == 403
    assert client.post("/api/v1/internal/run-reminders", headers={"X-Cron-Secret": "no"}).status_code == 403
    ok = client.post("/api/v1/internal/run-reminders", headers={"X-Cron-Secret": "s3cret"})
    assert ok.status_code == 200 and ok.json() == {"day": 0, "hour": 0, "released": 3}
