"""Ratings, bookings and campus services, against a tiny in-memory Supabase."""

import itertools
from datetime import datetime, timedelta, timezone

import pytest

from app.api.v1 import bookings as bookings_module
from app.api.v1 import campus_services as services_module
from app.api.v1 import transport as transport_module
from app.services import notify as notify_module


class _Query:
    def __init__(self, db, table):
        self.db, self.table = db, table
        self.filters, self._single, self._insert, self._update, self._limit = [], False, None, None, None
        self._delete, self._range = False, None

    def select(self, *_):
        return self

    def eq(self, col, val):
        self.filters.append(lambda r: r.get(col) == val)
        return self

    def in_(self, col, vals):
        self.filters.append(lambda r: r.get(col) in vals)
        return self

    def order(self, *_a, **_k):
        return self

    def limit(self, n):
        self._limit = n
        return self

    def maybe_single(self):
        self._single = True
        return self

    def insert(self, data):
        self._insert = data
        return self

    def upsert(self, data, on_conflict=None, ignore_duplicates=False):
        self._insert, self._conflict = data, on_conflict.split(",") if on_conflict else None
        return self

    def delete(self):
        self._delete = True
        return self

    def gt(self, col, val):
        self.filters.append(lambda r: r.get(col) is not None and r[col] > val)
        return self

    def gte(self, col, val):
        self.filters.append(lambda r: r.get(col) is not None and r[col] >= val)
        return self

    def lte(self, col, val):
        self.filters.append(lambda r: r.get(col) is not None and r[col] <= val)
        return self

    def is_(self, col, val):
        assert val == "null"
        self.filters.append(lambda r: r.get(col) is None)
        return self

    def or_(self, clause):
        """Supports the simple `col.is.null,col.lte|gt.value` clauses the
        app builds for scheduled/expiring content."""
        tests = []
        for part in clause.split(","):
            col, op, val = part.split(".", 2)
            if op == "is":
                tests.append(lambda r, c=col: r.get(c) is None)
            elif op == "lte":
                tests.append(lambda r, c=col, v=val: r.get(c) is not None and r[c] <= v)
            elif op == "gt":
                tests.append(lambda r, c=col, v=val: r.get(c) is not None and r[c] > v)
            else:
                raise AssertionError(f"unsupported op {op}")
        self.filters.append(lambda r: any(t(r) for t in tests))
        return self

    def range(self, a, b):
        self._range = (a, b)
        return self

    def update(self, data):
        self._update = data
        return self

    def execute(self):
        rows = self.db.tables.setdefault(self.table, [])
        if self._insert is not None:
            made = []
            for item in self._insert if isinstance(self._insert, list) else [self._insert]:
                key = getattr(self, "_conflict", None)
                if key and any(all(r.get(k) == item.get(k) for k in key) for r in rows):
                    continue
                row = {"id": f"id{next(self.db.ids)}", "status": "pending",
                       "created_at": datetime.now(timezone.utc).isoformat(),
                       "published_at": datetime.now(timezone.utc).isoformat(), **item}
                rows.append(row)
                made.append(row)
            return _Res(made)
        matched = [r for r in rows if all(f(r) for f in self.filters)]
        if self._delete:
            for r in matched:
                rows.remove(r)
            return _Res(matched)
        if self._range:
            matched = matched[self._range[0] : self._range[1] + 1]
        if self._update is not None:
            for r in matched:
                r.update(self._update)
            return _Res(matched)
        if self._limit:
            matched = matched[: self._limit]
        if self._single:
            return _Res(matched[0] if matched else None)
        return _Res(matched)


class _Res:
    def __init__(self, data):
        self.data = data


class _Rpc:
    def __init__(self, data):
        self._d = data

    def execute(self):
        return _Res(self._d)


class _Db:
    def __init__(self):
        self.tables, self.ids, self.rpc_result, self.rpc_calls = {}, itertools.count(1), None, []

    def table(self, name):
        return _Query(self, name)

    def rpc(self, fn, params):
        self.rpc_calls.append((fn, params))
        return _Rpc(self.rpc_result)


@pytest.fixture
def db(monkeypatch):
    d = _Db()
    d.tables["transport_providers"] = [{"id": "r1", "name": "Rider", "phone_number": "0700"}]
    d.tables["profiles"] = [{"id": "s1", "name": "Student"}, {"id": "p1", "name": "Pub"}]
    d.tables["publisher_submissions"] = [
        {"type": "transport", "content_id": "r1", "status": "published", "publisher_id": "p1"}
    ]
    for mod in (bookings_module, transport_module, services_module, notify_module):
        monkeypatch.setattr(mod, "get_supabase_admin", lambda: d, raising=False)
    monkeypatch.setattr(notify_module.fcm, "is_configured", lambda: False)
    monkeypatch.setattr(services_module.repo, "list", lambda **k: d.tables.get("campus_services", []))
    return d


BOOKING = {"provider_id": "r1", "pickup": "Main Gate", "destination": "Soroti Town"}


# ── ratings ──────────────────────────────────────────────────────────────
def test_rating_requires_login(client):
    assert client.post("/api/v1/transport/r1/rate", json={"stars": 5}).status_code in (401, 403)


@pytest.mark.parametrize("stars", [0, 6])
def test_rating_rejects_out_of_range_stars(client, as_role, db, stars):
    as_role("student")
    assert client.post("/api/v1/transport/r1/rate", json={"stars": stars}).status_code == 422


def test_rating_returns_new_average(client, as_role, db):
    db.rpc_result = {"status": "ok", "rating": 4.5, "rating_count": 2}
    as_role("student", "s1")
    res = client.post("/api/v1/transport/r1/rate", json={"stars": 4})
    assert res.json() == {"rating": 4.5, "rating_count": 2, "my_stars": 4}
    assert db.rpc_calls[0][1]["p_user_id"] == "s1"


def test_rating_unknown_rider_is_404(client, as_role, db):
    db.rpc_result = {"status": "not_found"}
    as_role("student")
    assert client.post("/api/v1/transport/nope/rate", json={"stars": 3}).status_code == 404


# ── bookings ─────────────────────────────────────────────────────────────
def test_booking_is_created_pending_and_notifies_the_rider_owner(client, as_role, db):
    as_role("student", "s1")
    res = client.post("/api/v1/bookings", json=BOOKING)
    assert res.status_code == 201
    body = res.json()
    assert body["status"] == "pending" and body["student_id"] == "s1"
    assert body["provider_name"] == "Rider"
    assert [n["user_id"] for n in db.tables["notifications"]] == ["p1"]


def test_booking_in_the_past_is_rejected(client, as_role, db):
    as_role("student", "s1")
    past = (datetime.now(timezone.utc) - timedelta(hours=1)).isoformat()
    assert client.post("/api/v1/bookings", json={**BOOKING, "requested_time": past}).status_code == 422


def test_second_open_booking_with_same_rider_is_409(client, as_role, db):
    as_role("student", "s1")
    client.post("/api/v1/bookings", json=BOOKING)
    assert client.post("/api/v1/bookings", json=BOOKING).status_code == 409


def test_booking_unknown_rider_is_404(client, as_role, db):
    as_role("student", "s1")
    assert client.post("/api/v1/bookings", json={**BOOKING, "provider_id": "zz"}).status_code == 404


def test_owner_can_accept_then_complete(client, as_role, db):
    as_role("student", "s1")
    bid = client.post("/api/v1/bookings", json=BOOKING).json()["id"]
    as_role("publisher", "p1")
    assert client.post(f"/api/v1/bookings/{bid}/respond", json={"action": "accept"}).json()["status"] == "accepted"
    assert client.post(f"/api/v1/bookings/{bid}/respond", json={"action": "complete"}).json()["status"] == "completed"
    assert "s1" in [n["user_id"] for n in db.tables["notifications"]]


def test_cannot_complete_a_pending_booking(client, as_role, db):
    as_role("student", "s1")
    bid = client.post("/api/v1/bookings", json=BOOKING).json()["id"]
    as_role("publisher", "p1")
    assert client.post(f"/api/v1/bookings/{bid}/respond", json={"action": "complete"}).status_code == 409


def test_unrelated_publisher_cannot_respond(client, as_role, db):
    as_role("student", "s1")
    bid = client.post("/api/v1/bookings", json=BOOKING).json()["id"]
    as_role("publisher", "other")
    assert client.post(f"/api/v1/bookings/{bid}/respond", json={"action": "accept"}).status_code == 403


def test_admin_can_respond_to_any_booking(client, as_role, db):
    as_role("student", "s1")
    bid = client.post("/api/v1/bookings", json=BOOKING).json()["id"]
    as_role("minor_admin", "a1")
    assert client.post(f"/api/v1/bookings/{bid}/respond", json={"action": "decline"}).json()["status"] == "declined"


def test_only_the_student_can_cancel_and_it_frees_the_slot(client, as_role, db):
    as_role("student", "s1")
    bid = client.post("/api/v1/bookings", json=BOOKING).json()["id"]
    as_role("student", "s2")
    assert client.post(f"/api/v1/bookings/{bid}/cancel").status_code == 403
    as_role("student", "s1")
    assert client.post(f"/api/v1/bookings/{bid}/cancel").json()["status"] == "cancelled"
    assert client.post("/api/v1/bookings", json=BOOKING).status_code == 201


def test_mine_lists_only_own_and_incoming_only_for_owned_riders(client, as_role, db):
    as_role("student", "s1")
    client.post("/api/v1/bookings", json=BOOKING)
    assert len(client.get("/api/v1/bookings/mine").json()) == 1
    as_role("student", "s2")
    assert client.get("/api/v1/bookings/mine").json() == []
    as_role("publisher", "p1")
    assert len(client.get("/api/v1/bookings/incoming").json()) == 1
    as_role("publisher", "other")
    assert client.get("/api/v1/bookings/incoming").json() == []


# ── campus services ──────────────────────────────────────────────────────
def test_services_are_public(client, db):
    db.tables["campus_services"] = [
        {"id": "c1", "category": "library", "name": "Library"}
    ]
    res = client.get("/api/v1/campus-services")
    assert res.status_code == 200 and res.json()[0]["name"] == "Library"


def test_services_reject_unknown_category(client, db):
    assert client.get("/api/v1/campus-services", params={"category": "nope"}).status_code == 422


@pytest.mark.parametrize("role", ["student", "publisher"])
def test_only_admins_can_manage_services(client, as_role, db, role):
    as_role(role)
    body = {"category": "food", "name": "Canteen"}
    assert client.post("/api/v1/campus-services", json=body).status_code == 403
    assert client.delete("/api/v1/campus-services/c1").status_code == 403
