"""Audit log, CSV export, real analytics, account data export/delete,
password reset, owner preview of scheduled posts, self-booking guard."""

from datetime import datetime, timedelta, timezone

import pytest

from app.api.v1 import admin as admin_module
from app.api.v1 import announcements as announcements_module
from app.api.v1 import auth as auth_module
from app.api.v1 import bookings as bookings_module
from app.core.security import get_optional_user
from app.main import app
from app.schemas.user import UserProfile
from app.services import audit as audit_module
from app.services import table_repo as table_repo_module
from app.services import usage as usage_module
from app.services.table_repo import TableRepo  # noqa: F401
from tests.test_booking_rating_services import _Db

NOW = datetime(2026, 10, 16, 12, 0, tzinfo=timezone.utc)


class _Auth:
    def __init__(self):
        self.deleted = []
        self.admin = self

    def delete_user(self, uid):
        self.deleted.append(uid)

    def reset_password_for_email(self, email):
        self.reset = email


class _Wrapped:
    """The fake table db plus an `auth` namespace."""

    def __init__(self, db):
        self._db, self.auth = db, _Auth()

    def table(self, name):
        return self._db.table(name)


@pytest.fixture
def db(monkeypatch):
    d = _Db()
    w = _Wrapped(d)
    d.tables["profiles"] = [
        {"id": "u1", "name": "Alice", "email": "a@x.ug", "role": "student", "last_seen_at": NOW.isoformat()},
        {"id": "u2", "name": "=Evil", "email": "e@x.ug", "role": "student", "last_seen_at": (NOW - timedelta(days=10)).isoformat()},
        {"id": "pub", "name": "Pub", "email": "p@x.ug", "role": "publisher", "last_seen_at": None},
    ]
    for mod in (table_repo_module, admin_module, audit_module, usage_module, auth_module, bookings_module, announcements_module):
        monkeypatch.setattr(mod, "get_supabase_admin", lambda: w, raising=False)
    monkeypatch.setattr(auth_module, "get_supabase_anon", lambda: w)
    monkeypatch.setattr(usage_module, "datetime", type("D", (), {"now": staticmethod(lambda tz=None: NOW), "fromisoformat": datetime.fromisoformat}))
    d.wrapped = w
    return d


def test_role_change_is_written_to_the_audit_log(client, as_role, db):
    as_role("admin", "boss")
    res = client.patch("/api/v1/admin/users/u1/role", json={"new_role": "publisher"})
    assert res.status_code == 200
    entry = db.tables["audit_log"][0]
    assert entry["action"] == "role_change" and entry["target_id"] == "u1"
    assert entry["detail"]["to"] == "publisher"


def test_audit_log_is_super_admin_only(client, as_role, db):
    as_role("minor_admin")
    assert client.get("/api/v1/admin/audit").status_code == 403
    as_role("admin")
    assert client.get("/api/v1/admin/audit").status_code == 200


def test_csv_export_neutralises_formulas_and_is_logged(client, as_role, db):
    as_role("admin", "boss")
    res = client.get("/api/v1/admin/users/export.csv")
    assert res.status_code == 200 and res.headers["content-type"].startswith("text/csv")
    assert "'=Evil" in res.text and "\n=Evil" not in res.text
    assert db.tables["audit_log"][-1]["action"] == "users_exported"


def test_csv_export_blocked_for_minor_admin(client, as_role, db):
    as_role("minor_admin")
    assert client.get("/api/v1/admin/users/export.csv").status_code == 403


def test_analytics_uses_real_active_users(client, as_role, db):
    as_role("admin")
    body = client.get("/api/v1/admin/analytics").json()
    assert body["total_users"] == 3
    assert body["daily_active_users"] == 1 and body["monthly_active_users"] == 2


def test_password_reset_always_answers_202(client, db):
    assert client.post("/api/v1/auth/password-reset", json={"email": "nobody@x.ug"}).status_code == 202
    assert db.wrapped.auth.reset == "nobody@x.ug"


def test_account_export_lists_own_data(client, as_role, db):
    as_role("student", "u1")
    db.tables["bookmarks"] = [{"user_id": "u1", "content_id": "c1"}, {"user_id": "u2", "content_id": "c2"}]
    body = client.get("/api/v1/auth/me/export").json()
    assert [b["content_id"] for b in body["bookmarks"]] == ["c1"]
    assert body["profile"]["id"] == "u1"


def test_delete_account_removes_the_auth_user(client, as_role, db):
    as_role("student", "u1")
    assert client.delete("/api/v1/auth/me").status_code == 204
    assert db.wrapped.auth.deleted == ["u1"]


def test_super_admin_cannot_delete_themselves(client, as_role, db):
    as_role("admin", "boss")
    assert client.delete("/api/v1/auth/me").status_code == 409
    assert db.wrapped.auth.deleted == []


def test_publisher_can_open_their_scheduled_announcement_but_public_cannot(client, db):
    future = (NOW + timedelta(days=3)).isoformat()
    db.tables["announcements"] = [{"id": "a1", "title": "T", "publish_at": future}]
    db.tables["publisher_submissions"] = [
        {"type": "announcement", "content_id": "a1", "publisher_id": "pub", "status": "scheduled"}
    ]
    monkey_future = lambda: UserProfile(id="pub", name="Pub", email="p@x.ug", role="publisher")
    assert usage_module.can_preview("announcement", "a1", None) is False
    assert usage_module.can_preview("announcement", "a1", monkey_future()) is True
    stranger = UserProfile(id="zz", name="Z", email="z@x.ug", role="student")
    assert usage_module.can_preview("announcement", "a1", stranger) is False
    admin = UserProfile(id="ad", name="A", email="a@x.ug", role="minor_admin")
    assert usage_module.can_preview("announcement", "a1", admin) is True


def test_owner_cannot_book_their_own_rider(client, as_role, db):
    db.tables["transport_providers"] = [{"id": "r1", "name": "Rider", "phone_number": "0700"}]
    db.tables["publisher_submissions"] = [
        {"type": "transport", "content_id": "r1", "publisher_id": "pub", "status": "published"}
    ]
    as_role("publisher", "pub")
    res = client.post("/api/v1/bookings", json={"provider_id": "r1", "pickup": "Main Gate", "destination": "Town"})
    assert res.status_code == 400


# ── lockout and two-factor ───────────────────────────────────────────────
from app.api.v1 import auth as _auth
from app.services import mfa as mfa_module


@pytest.fixture
def failing_login(monkeypatch):
    _auth._failures.clear()

    class _Anon:
        class auth:
            @staticmethod
            def sign_in_with_password(_):
                raise RuntimeError("bad password")

    monkeypatch.setattr(_auth, "get_supabase_anon", lambda: _Anon)
    yield
    _auth._failures.clear()


def test_five_wrong_passwords_lock_the_account_for_a_while(client, failing_login):
    body = {"email": "a@x.ug", "password": "wrong"}
    for _ in range(5):
        assert client.post("/api/v1/auth/login", json=body).status_code == 401
    res = client.post("/api/v1/auth/login", json=body)
    assert res.status_code == 429 and "Try again" in res.json()["detail"]
    # another address is unaffected
    assert client.post("/api/v1/auth/login", json={**body, "email": "b@x.ug"}).status_code == 401


def _jwt(claims):
    import base64, json
    enc = lambda d: base64.urlsafe_b64encode(json.dumps(d).encode()).decode().rstrip("=")
    return f"{enc({'alg': 'none'})}.{enc(claims)}.sig"


def test_token_aal_reads_the_claim():
    assert mfa_module.token_aal(_jwt({"aal": "aal2"})) == "aal2"
    assert mfa_module.token_aal(_jwt({})) == "aal1"
    assert mfa_module.token_aal("garbage") == "aal1"


def test_admin_endpoints_demand_aal2_when_2fa_is_required(client, monkeypatch):
    from app.core import security
    from app.core.security import get_current_user

    admin = UserProfile(id="ad", name="A", email="a@x.ug", role="admin")
    app.dependency_overrides[get_current_user] = lambda: admin
    monkeypatch.setattr(security, "get_settings", lambda: type("S", (), {"admin_require_2fa": True})())
    low = {"Authorization": f"Bearer {_jwt({'aal': 'aal1'})}"}
    high = {"Authorization": f"Bearer {_jwt({'aal': 'aal2'})}"}
    assert client.get("/api/v1/admin/audit", headers=low).status_code == 403
    assert client.get("/api/v1/admin/audit", headers=low).json()["detail"].startswith("Two-factor")
    # passes the gate with aal2 (then fails on the unmocked database, which is not a 403)
    assert client.get("/api/v1/admin/audit", headers=high).status_code != 403


def test_mfa_verify_returns_the_upgraded_session(client, as_role, monkeypatch, db):
    as_role("admin", "boss")
    monkeypatch.setattr(
        mfa_module, "verify",
        lambda token, fid, code: {"access_token": "aal2-token", "refresh_token": "r2"},
    )
    res = client.post(
        "/api/v1/auth/mfa/verify",
        json={"factor_id": "f1", "code": " 123456 "},
        headers={"Authorization": "Bearer aal1-token"},
    )
    assert res.status_code == 200 and res.json()["access_token"] == "aal2-token"


def test_mfa_verify_wrong_code_is_401(client, as_role, monkeypatch, db):
    as_role("admin", "boss")

    def boom(*a):
        raise mfa_module.MfaError("invalid", 400)

    monkeypatch.setattr(mfa_module, "verify", boom)
    res = client.post(
        "/api/v1/auth/mfa/verify",
        json={"factor_id": "f1", "code": "000000"},
        headers={"Authorization": "Bearer t"},
    )
    assert res.status_code == 401


def test_students_cannot_enrol_in_2fa(client, as_role, db):
    as_role("student", "u1")
    assert client.post("/api/v1/auth/mfa/enroll", headers={"Authorization": "Bearer t"}).status_code == 403
