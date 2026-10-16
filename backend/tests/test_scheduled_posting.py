"""Scheduled posting: hidden until publish_at, released (and announced) on
time, reschedulable and cancellable by the publisher."""

from datetime import datetime, timedelta, timezone

import pytest

from app.api.v1 import announcements as ann_module
from app.api.v1 import events as events_module
from app.services import notify as notify_module
from app.services import publisher_service, scheduling, table_repo
from tests.test_booking_rating_services import _Db


@pytest.fixture
def db(monkeypatch):
    d = _Db()
    d.tables["profiles"] = [{"id": "pub"}, {"id": "u1"}, {"id": "u2"}]
    for mod in (ann_module, events_module, notify_module, scheduling, table_repo):
        monkeypatch.setattr(mod, "get_supabase_admin", lambda: d)
    monkeypatch.setattr(notify_module.fcm, "is_configured", lambda: False)
    return d


def _in(**delta):
    return (datetime.now(timezone.utc) + timedelta(**delta)).isoformat()


def _announcement(**extra):
    return {"title": "Exam timetable", "description": "Out soon", "category": "Academic", **extra}


def _event(**extra):
    return {
        "title": "Career fair", "description": "d", "category": "Career",
        "organizer_name": "Student Affairs", "venue": "Main Hall",
        "date_time": _in(days=10), **extra,
    }


def _types(db):
    return sorted(n["type"] for n in db.tables.get("notifications", []))


# ── creating ─────────────────────────────────────────────────────────────
def test_immediate_post_is_live_and_announced(client, as_role, db):
    as_role("publisher", "pub")
    res = client.post("/api/v1/announcements", json=_announcement())
    assert res.status_code == 200
    assert db.tables["publisher_submissions"][0]["status"] == "published"
    assert _types(db) == ["announcement", "announcement"]  # u1, u2 (not the author)


def test_scheduled_post_is_recorded_as_scheduled_and_not_announced_yet(client, as_role, db):
    as_role("publisher", "pub")
    when = _in(hours=5)
    res = client.post("/api/v1/announcements", json=_announcement(publish_at=when))
    assert res.status_code == 200
    row = db.tables["announcements"][0]
    assert row["publish_at"] and row["published_at"] == row["publish_at"]
    sub = db.tables["publisher_submissions"][0]
    assert sub["status"] == "scheduled" and sub["publish_at"] == row["publish_at"]
    assert db.tables.get("notifications", []) == []


@pytest.mark.parametrize("delta", [{"seconds": -30}, {"seconds": 10}, {"days": 400}])
def test_schedule_must_be_between_a_minute_and_a_year_ahead(client, as_role, db, delta):
    as_role("publisher", "pub")
    res = client.post("/api/v1/announcements", json=_announcement(publish_at=_in(**delta)))
    assert res.status_code == 422
    assert db.tables.get("announcements", []) == []


def test_announcement_cannot_expire_before_it_goes_live(client, as_role, db):
    as_role("publisher", "pub")
    res = client.post(
        "/api/v1/announcements",
        json=_announcement(publish_at=_in(days=2), expires_at=_in(days=1)),
    )
    assert res.status_code == 422


def test_event_cannot_start_before_it_goes_live(client, as_role, db):
    as_role("publisher", "pub")
    res = client.post("/api/v1/events", json=_event(date_time=_in(hours=2), publish_at=_in(hours=5)))
    assert res.status_code == 422


def test_only_publishers_can_schedule(client, as_role, db):
    as_role("student", "u1")
    assert client.post("/api/v1/announcements", json=_announcement(publish_at=_in(hours=2))).status_code == 403


# ── visibility ───────────────────────────────────────────────────────────
def test_scheduled_items_are_hidden_from_lists_and_detail_until_their_time(client, db):
    db.tables["announcements"] = [
        {"id": "a1", "title": "Soon", "description": "d", "category": "Academic",
         "publisher_name": "p", "published_at": _in(hours=3), "publish_at": _in(hours=3)},
        {"id": "a2", "title": "Now", "description": "d", "category": "Academic",
         "publisher_name": "p", "published_at": _in(hours=-1), "publish_at": _in(hours=-1)},
        {"id": "a3", "title": "Normal", "description": "d", "category": "Academic",
         "publisher_name": "p", "published_at": _in(hours=-2), "publish_at": None},
    ]
    shown = {a["id"] for a in client.get("/api/v1/announcements").json()}
    assert shown == {"a2", "a3"}
    assert client.get("/api/v1/announcements/a1").status_code == 404
    assert client.get("/api/v1/announcements/a2").status_code == 200


def test_scheduled_events_are_hidden_from_the_event_list(client, db):
    base = {"description": "d", "category": "Career", "organizer_name": "o", "venue": "v",
            "date_time": _in(days=5)}
    db.tables["events"] = [
        {"id": "e1", "title": "Hidden", "publish_at": _in(hours=1), **base},
        {"id": "e2", "title": "Shown", "publish_at": None, **base},
    ]
    assert [e["id"] for e in client.get("/api/v1/events").json()] == ["e2"]
    assert client.get("/api/v1/events/e1").status_code == 404


# ── release ──────────────────────────────────────────────────────────────
def _scheduled_announcement(db, when_iso):
    db.tables["announcements"] = [{
        "id": "a1", "title": "Exam timetable", "description": "Out soon", "category": "Academic",
        "publisher_name": "p", "published_at": when_iso, "publish_at": when_iso, "notified_at": None,
    }]
    db.tables["publisher_submissions"] = [{
        "id": "s1", "type": "announcement", "content_id": "a1", "publisher_id": "pub",
        "status": "scheduled", "publish_at": when_iso, "title": "Exam timetable",
    }]


def test_release_announces_once_and_marks_the_submission_published(db):
    _scheduled_announcement(db, _in(minutes=-2))
    assert scheduling.release_due_content() == 1
    assert db.tables["publisher_submissions"][0]["status"] == "published"
    assert sorted(n["user_id"] for n in db.tables["notifications"]) == ["u1", "u2"]
    assert scheduling.release_due_content() == 0  # already claimed
    assert len(db.tables["notifications"]) == 2


def test_release_leaves_future_items_alone(db):
    _scheduled_announcement(db, _in(hours=1))
    assert scheduling.release_due_content() == 0
    assert db.tables["publisher_submissions"][0]["status"] == "scheduled"
    assert db.tables.get("notifications", []) == []


# ── reschedule / cancel ──────────────────────────────────────────────────
def test_publisher_can_move_a_scheduled_post(client, as_role, db):
    _scheduled_announcement(db, _in(hours=1))
    as_role("publisher", "pub")
    new = _in(days=2)
    res = client.patch("/api/v1/announcements/a1/schedule", json={"publish_at": new})
    assert res.status_code == 200
    assert db.tables["announcements"][0]["publish_at"][:16] == new[:16]
    assert db.tables["publisher_submissions"][0]["publish_at"][:16] == new[:16]


def test_publish_now_releases_immediately(client, as_role, db):
    _scheduled_announcement(db, _in(days=1))
    as_role("publisher", "pub")
    assert client.patch("/api/v1/announcements/a1/schedule", json={"publish_at": None}).status_code == 200
    assert db.tables["publisher_submissions"][0]["status"] == "published"
    assert len(db.tables["notifications"]) == 2


def test_other_publisher_cannot_reschedule(client, as_role, db):
    _scheduled_announcement(db, _in(hours=1))
    as_role("publisher", "someone-else")
    res = client.patch("/api/v1/announcements/a1/schedule", json={"publish_at": _in(days=2)})
    assert res.status_code == 404


def test_cannot_reschedule_something_already_live(client, as_role, db):
    _scheduled_announcement(db, _in(minutes=-5))
    as_role("publisher", "pub")
    res = client.patch("/api/v1/announcements/a1/schedule", json={"publish_at": _in(days=2)})
    assert res.status_code == 409


def test_scheduled_post_can_be_cancelled_by_its_publisher(db, monkeypatch):
    _scheduled_announcement(db, _in(hours=4))
    monkeypatch.setattr(publisher_service, "TableRepo", lambda t: table_repo.TableRepo(t))
    publisher_service.remove_own_content("pub", "announcement", "a1")
    assert db.tables["publisher_submissions"][0]["status"] == "removed"
    assert db.tables["announcements"] == []
