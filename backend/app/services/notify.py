"""One place that creates notifications: an in-app row for each recipient,
plus a push to their registered devices, honouring each user's category
preferences (profile settings)."""

import logging
from concurrent.futures import ThreadPoolExecutor
from typing import Iterable

from app.core.supabase_client import get_supabase_admin
from app.services import fcm

logger = logging.getLogger("mysun")

# notification `type` -> preference key. Types not listed here (e.g.
# "system": moderation notices) are always delivered.
CATEGORY_BY_TYPE = {
    "announcement": "announcements",
    "event": "events",
    "reminder": "reminders",
    "transport": "transport",
}
PREF_KEYS = tuple(CATEGORY_BY_TYPE.values())

_CHUNK = 100
_PUSH_WORKERS = 8


def _chunks(items: list, size: int = _CHUNK):
    for i in range(0, len(items), size):
        yield items[i : i + size]


def wants(prefs: dict | None, type: str) -> bool:
    key = CATEGORY_BY_TYPE.get(type)
    return key is None or (prefs or {}).get(key, True) is not False


def effective_prefs(prefs: dict | None) -> dict[str, bool]:
    return {k: (prefs or {}).get(k, True) is not False for k in PREF_KEYS}


def all_user_ids(exclude: Iterable[str] = ()) -> list[str]:
    skip = set(exclude)
    ids: list[str] = []
    start, page = 0, 1000
    db = get_supabase_admin()
    while True:
        rows = (
            db.table("profiles").select("id").order("id").range(start, start + page - 1).execute().data
        )
        ids.extend(r["id"] for r in rows if r["id"] not in skip)
        if len(rows) < page:
            return ids
        start += page


def notify_users(
    user_ids: Iterable[str],
    *,
    title: str,
    body: str,
    type: str,
    related_id: str | None = None,
) -> int:
    """Returns how many users were notified. Never raises for push problems."""
    ids = list(dict.fromkeys(i for i in user_ids if i))
    if not ids:
        return 0
    db = get_supabase_admin()

    recipients: list[str] = []
    for chunk in _chunks(ids):
        rows = db.table("profiles").select("id,notification_prefs").in_("id", chunk).execute().data
        recipients.extend(r["id"] for r in rows if wants(r.get("notification_prefs"), type))
    if not recipients:
        return 0

    for chunk in _chunks(recipients, 500):
        db.table("notifications").insert(
            [
                {"user_id": uid, "title": title, "body": body, "type": type, "related_id": related_id}
                for uid in chunk
            ]
        ).execute()

    try:
        _push(recipients, title, body, type, related_id)
    except Exception:
        logger.exception("Push delivery failed")
    return len(recipients)


def _push(user_ids: list[str], title: str, body: str, type: str, related_id: str | None) -> None:
    if not fcm.is_configured():
        return
    db = get_supabase_admin()
    data = {"type": type, **({"related_id": related_id} if related_id else {})}
    dead: list[str] = []
    tokens: list[str] = []
    for chunk in _chunks(user_ids):
        rows = db.table("device_tokens").select("token").in_("user_id", chunk).execute().data
        tokens.extend(r["token"] for r in rows)
    # Sends are blocking HTTP calls; fan them out so a big publish does not
    # hold the worker for (tokens x latency).
    with ThreadPoolExecutor(max_workers=_PUSH_WORKERS) as pool:
        results = pool.map(lambda tok: (tok, fcm.send(tok, title, body, data)), tokens)
        dead = [tok for tok, outcome in results if outcome == "invalid"]
    for chunk in _chunks(dead):
        db.table("device_tokens").delete().in_("token", chunk).execute()
