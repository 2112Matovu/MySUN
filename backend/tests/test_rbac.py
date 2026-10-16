"""Verifies the role gates in app/core/security.py actually reject the
roles they're meant to reject. Every one of these hits the dependency
before the route body runs, so none of them touch Supabase.
"""

import pytest

PUBLISHER_ENDPOINTS = [
    ("GET", "/api/v1/publisher/submissions", None),
    ("GET", "/api/v1/publisher/drafts", None),
    ("POST", "/api/v1/publisher/drafts", {"type": "announcement", "title": "t"}),
    ("DELETE", "/api/v1/publisher/drafts/abc", None),
    ("POST", "/api/v1/publisher/submissions/abc/remove", None),
    ("GET", "/api/v1/publisher/performance", None),
    (
        "POST",
        "/api/v1/events",
        {
            "title": "t",
            "description": "d",
            "category": "Academic",
            "organizer_name": "o",
            "date_time": "2030-01-01T00:00:00Z",
            "venue": "v",
        },
    ),
    (
        "POST",
        "/api/v1/announcements",
        {"title": "t", "description": "d", "category": "Academic"},
    ),
    (
        "POST",
        "/api/v1/accommodation",
        {
            "name": "n",
            "type": "hostel",
            "location": "l",
            "price": 1000,
            "contact_phone": "0700000000",
        },
    ),
    ("POST", "/api/v1/transport", {"name": "n", "phone_number": "0700000000"}),
]

ADMIN_LEVEL_ENDPOINTS = [
    ("GET", "/api/v1/admin/moderation", None),
    ("POST", "/api/v1/admin/moderation/abc/remove", {"reason": "spam"}),
    ("PATCH", "/api/v1/admin/transport/abc/verified", {"is_verified": True}),
]

SUPER_ADMIN_ENDPOINTS = [
    ("GET", "/api/v1/admin/users", None),
    ("PATCH", "/api/v1/admin/users/abc/role", {"new_role": "publisher"}),
    ("GET", "/api/v1/admin/analytics", None),
]


@pytest.mark.parametrize("method, path, body", PUBLISHER_ENDPOINTS)
@pytest.mark.parametrize("role", ["student", "admin", "minor_admin"])
def test_publisher_only_endpoints_reject_non_publishers(client, as_role, method, path, body, role):
    as_role(role)
    res = client.request(method, path, json=body)
    assert res.status_code == 403


@pytest.mark.parametrize("method, path, body", ADMIN_LEVEL_ENDPOINTS)
@pytest.mark.parametrize("role", ["student", "publisher"])
def test_admin_level_endpoints_reject_non_admins(client, as_role, method, path, body, role):
    as_role(role)
    res = client.request(method, path, json=body)
    assert res.status_code == 403


@pytest.mark.parametrize("method, path, body", SUPER_ADMIN_ENDPOINTS)
@pytest.mark.parametrize("role", ["student", "publisher", "minor_admin"])
def test_super_admin_endpoints_reject_non_super_admins(client, as_role, method, path, body, role):
    """minor_admin is the interesting case here — it's exactly the
    distinction require_super_admin vs. require_admin_level exists to draw
    (§5.1: a Minor Admin can moderate but not manage users/analytics)."""
    as_role(role)
    res = client.request(method, path, json=body)
    assert res.status_code == 403


def test_publisher_role_passes_the_publisher_gate(client, as_role):
    as_role("publisher")
    res = client.get("/api/v1/publisher/submissions")
    assert res.status_code not in (401, 403)


def test_minor_admin_passes_the_admin_level_gate(client, as_role):
    as_role("minor_admin")
    res = client.get("/api/v1/admin/moderation")
    assert res.status_code not in (401, 403)


def test_admin_passes_the_super_admin_gate(client, as_role):
    as_role("admin")
    res = client.get("/api/v1/admin/users")
    assert res.status_code not in (401, 403)


def test_no_bearer_token_rejected(client):
    res = client.get("/api/v1/publisher/submissions")
    assert res.status_code == 401
