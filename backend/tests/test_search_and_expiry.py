"""Search across content types and hiding of expired announcements."""

import pytest

from app.api.v1 import announcements as announcements_module
from app.api.v1 import search as search_module


class _Query:
    """Records every builder call so tests can assert the filters sent to
    PostgREST without a network round-trip."""

    def __init__(self, table, rows, log):
        self.table_name, self._rows, self.log = table, rows, log

    def _rec(self, name, *args):
        self.log.append((self.table_name, name, args))
        return self

    def select(self, *a, **k):
        return self._rec("select", *a)

    def or_(self, clause):
        return self._rec("or_", clause)

    def eq(self, *a):
        return self._rec("eq", *a)

    def order(self, *a, **k):
        return self._rec("order", *a)

    def limit(self, n):
        return self._rec("limit", n)

    def execute(self):
        class R:
            data = self._rows

        return R()


class _Client:
    def __init__(self, rows_by_table):
        self.rows, self.log = rows_by_table, []

    def table(self, name):
        return _Query(name, self.rows.get(name, []), self.log)


@pytest.fixture
def fake_db(monkeypatch):
    db = _Client({})
    monkeypatch.setattr(search_module, "get_supabase_admin", lambda: db)
    monkeypatch.setattr(announcements_module, "get_supabase_admin", lambda: db)
    return db


def test_search_queries_every_content_table(client, fake_db):
    res = client.get("/api/v1/search", params={"q": "library"})
    assert res.status_code == 200
    assert set(res.json()) == {"announcements", "events", "accommodation", "transport"}
    tables = {t for t, name, _ in fake_db.log if name == "select"}
    assert tables == {"announcements", "events", "accommodation_listings", "transport_providers"}


def test_search_matches_with_ilike_on_text_columns(client, fake_db):
    client.get("/api/v1/search", params={"q": "hostel"})
    clauses = [a[0] for t, n, a in fake_db.log if t == "events" and n == "or_"]
    assert "title.ilike.*hostel*" in clauses[0]
    assert "venue.ilike.*hostel*" in clauses[0]


def test_search_hides_expired_announcements(client, fake_db):
    client.get("/api/v1/search", params={"q": "notice"})
    ann_clauses = [a[0] for t, n, a in fake_db.log if t == "announcements" and n == "or_"]
    assert any(c.startswith("expires_at.is.null,expires_at.gt.") for c in ann_clauses)


def test_search_strips_filter_syntax_characters(client, fake_db):
    client.get("/api/v1/search", params={"q": "a),title.eq.x(b"})
    for _, name, args in fake_db.log:
        if name == "or_" and "ilike" in args[0]:
            assert ")," not in args[0].split("ilike.")[1].split(",")[0]
            assert "(" not in args[0]


def test_search_rejects_short_query(client, fake_db):
    assert client.get("/api/v1/search", params={"q": "a"}).status_code == 422


def test_search_symbols_only_returns_empty(client, fake_db):
    res = client.get("/api/v1/search", params={"q": "(),"})
    assert res.status_code == 200
    assert res.json() == {"announcements": [], "events": [], "accommodation": [], "transport": []}


def test_announcement_list_hides_expired_by_default(client, fake_db):
    client.get("/api/v1/announcements")
    clauses = [a[0] for _, n, a in fake_db.log if n == "or_"]
    assert any(c.startswith("expires_at.is.null,expires_at.gt.") for c in clauses)
    assert any(c.startswith("publish_at.is.null,publish_at.lte.") for c in clauses)


def test_announcement_list_can_include_expired(client, fake_db):
    client.get("/api/v1/announcements", params={"include_expired": "true"})
    clauses = [a[0] for _, n, a in fake_db.log if n == "or_"]
    assert not any(c.startswith("expires_at") for c in clauses)
    assert any(c.startswith("publish_at") for c in clauses)  # scheduled posts stay hidden


def test_announcement_list_filters_category(client, fake_db):
    client.get("/api/v1/announcements", params={"category": "Academic"})
    assert ("announcements", "eq", ("category", "Academic")) in fake_db.log
