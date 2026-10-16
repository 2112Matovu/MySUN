import re

from fastapi import APIRouter, Query, Request
from pydantic import BaseModel

from app.core.limiter import limiter
from app.core.supabase_client import get_supabase_admin
from app.schemas.content import Accommodation, Announcement, Event, TransportProvider
from app.services.content_filters import is_live_filter, not_expired_filter

router = APIRouter(prefix="/search", tags=["search"])

# Text columns matched per table (case-insensitive substring match).
_COLUMNS = {
    "announcements": ["title", "description", "category", "publisher_name"],
    "events": ["title", "description", "category", "organizer_name", "venue"],
    "accommodation_listings": ["name", "location", "description", "publisher_name"],
    "transport_providers": ["name", "contact_person", "operating_hours"],
}
_PER_TABLE_LIMIT = 30


class SearchResults(BaseModel):
    announcements: list[Announcement]
    events: list[Event]
    accommodation: list[Accommodation]
    transport: list[TransportProvider]


def _clean(q: str) -> str:
    """Strips characters that are special in PostgREST filter syntax
    (commas, parentheses, wildcards, quotes, backslashes) so a search term
    can't alter the filter it is embedded in."""
    return re.sub(r'[,()%*\\"]', " ", q).strip()


def _search(table: str, term: str) -> list[dict]:
    pattern = f"*{term}*"
    clause = ",".join(f"{col}.ilike.{pattern}" for col in _COLUMNS[table])
    query = get_supabase_admin().table(table).select("*").or_(clause)
    if table in ("announcements", "events"):
        query = query.or_(is_live_filter())
    if table == "announcements":
        query = query.or_(not_expired_filter())
    return query.limit(_PER_TABLE_LIMIT).execute().data


@router.get("", response_model=SearchResults)
@limiter.limit("30/minute")
def search(request: Request, q: str = Query(min_length=2, max_length=100)) -> dict:
    """Searches announcements, events, accommodation and boda riders in one
    call. Expired announcements are left out, like the feed."""
    term = _clean(q)
    if len(term) < 2:
        return {"announcements": [], "events": [], "accommodation": [], "transport": []}
    return {
        "announcements": _search("announcements", term),
        "events": _search("events", term),
        "accommodation": _search("accommodation_listings", term),
        "transport": _search("transport_providers", term),
    }
