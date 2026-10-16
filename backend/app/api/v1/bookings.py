from datetime import datetime, timedelta, timezone

from fastapi import APIRouter, Depends, HTTPException, status

from app.core.security import get_current_user
from app.core.supabase_client import get_supabase_admin
from app.schemas.booking import Booking, BookingCreate, BookingRespond
from app.schemas.user import UserProfile
from app.services.notify import notify_users

router = APIRouter(prefix="/bookings", tags=["bookings"])

_ACTIVE = ("pending", "accepted")
_ADMIN_ROLES = ("admin", "minor_admin")
# action -> (status it moves to, statuses it may move from)
_TRANSITIONS = {
    "accept": ("accepted", ("pending",)),
    "decline": ("declined", ("pending",)),
    "complete": ("completed", ("accepted",)),
}


def _now() -> str:
    return datetime.now(timezone.utc).isoformat()


def _owner_id(provider_id: str) -> str | None:
    """The publisher who listed this rider (None for seeded listings, which
    admins handle)."""
    rows = (
        get_supabase_admin()
        .table("publisher_submissions")
        .select("publisher_id")
        .eq("type", "transport")
        .eq("content_id", provider_id)
        .eq("status", "published")
        .limit(1)
        .execute()
        .data
    )
    return rows[0]["publisher_id"] if rows else None


def _can_respond(user: UserProfile, provider_id: str) -> bool:
    return user.role in _ADMIN_ROLES or _owner_id(provider_id) == user.id


def _notify(user_id: str | None, title: str, body: str, booking_id: str) -> None:
    if user_id:
        notify_users([user_id], title=title, body=body, type="transport", related_id=booking_id)


def _enrich(rows: list[dict]) -> list[dict]:
    """Adds rider/student names and the rider's phone so the app needs no
    follow-up lookups."""
    if not rows:
        return rows
    db = get_supabase_admin()
    providers = {
        p["id"]: p
        for p in db.table("transport_providers")
        .select("id,name,phone_number")
        .in_("id", list({r["provider_id"] for r in rows}))
        .execute()
        .data
    }
    students = {
        s["id"]: s
        for s in db.table("profiles")
        .select("id,name")
        .in_("id", list({r["student_id"] for r in rows}))
        .execute()
        .data
    }
    for r in rows:
        p = providers.get(r["provider_id"], {})
        r["provider_name"] = p.get("name")
        r["provider_phone"] = p.get("phone_number")
        r["student_name"] = students.get(r["student_id"], {}).get("name")
    return rows


@router.post("", response_model=Booking, status_code=201)
def create_booking(body: BookingCreate, user: UserProfile = Depends(get_current_user)) -> dict:
    db = get_supabase_admin()
    provider = (
        db.table("transport_providers")
        .select("id")
        .eq("id", body.provider_id)
        .maybe_single()
        .execute()
    )
    if not provider or not provider.data:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Rider not found")
    if _owner_id(body.provider_id) == user.id:
        raise HTTPException(status.HTTP_400_BAD_REQUEST, "You cannot book your own listing")

    if body.requested_time and body.requested_time < datetime.now(timezone.utc) - timedelta(
        minutes=5
    ):
        raise HTTPException(status.HTTP_422_UNPROCESSABLE_ENTITY, "Pick-up time is in the past")

    open_ones = (
        db.table("bookings")
        .select("id")
        .eq("student_id", user.id)
        .eq("provider_id", body.provider_id)
        .in_("status", list(_ACTIVE))
        .execute()
        .data
    )
    if open_ones:
        raise HTTPException(
            status.HTTP_409_CONFLICT, "You already have an open booking with this rider"
        )

    payload = body.model_dump(mode="json")
    payload["student_id"] = user.id
    created = db.table("bookings").insert(payload).execute().data[0]
    _notify(
        _owner_id(body.provider_id),
        "New boda booking",
        f"{user.name} wants a ride from {body.pickup} to {body.destination}.",
        created["id"],
    )
    return _enrich([created])[0]


@router.get("/mine", response_model=list[Booking])
def my_bookings(user: UserProfile = Depends(get_current_user)) -> list[dict]:
    rows = (
        get_supabase_admin()
        .table("bookings")
        .select("*")
        .eq("student_id", user.id)
        .order("created_at", desc=True)
        .execute()
        .data
    )
    return _enrich(rows)


@router.get("/incoming", response_model=list[Booking])
def incoming_bookings(user: UserProfile = Depends(get_current_user)) -> list[dict]:
    """Bookings for the riders this user listed; admins see all of them."""
    db = get_supabase_admin()
    query = db.table("bookings").select("*").order("created_at", desc=True)
    if user.role not in _ADMIN_ROLES:
        mine = (
            db.table("publisher_submissions")
            .select("content_id")
            .eq("type", "transport")
            .eq("status", "published")
            .eq("publisher_id", user.id)
            .execute()
            .data
        )
        ids = [m["content_id"] for m in mine if m["content_id"]]
        if not ids:
            return []
        query = query.in_("provider_id", ids)
    return _enrich(query.execute().data)


def _get(booking_id: str) -> dict:
    result = (
        get_supabase_admin().table("bookings").select("*").eq("id", booking_id).maybe_single().execute()
    )
    if not result or not result.data:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Booking not found")
    return result.data


def _move(booking_id: str, to: str, from_: tuple[str, ...]) -> dict:
    """Conditional update, so two simultaneous responses can't both win."""
    result = (
        get_supabase_admin()
        .table("bookings")
        .update({"status": to, "updated_at": _now()})
        .eq("id", booking_id)
        .in_("status", list(from_))
        .execute()
    )
    if not result.data:
        raise HTTPException(
            status.HTTP_409_CONFLICT, f"Booking can't be {to} from its current state"
        )
    return result.data[0]


@router.post("/{booking_id}/cancel", response_model=Booking)
def cancel_booking(booking_id: str, user: UserProfile = Depends(get_current_user)) -> dict:
    booking = _get(booking_id)
    if booking["student_id"] != user.id:
        raise HTTPException(status.HTTP_403_FORBIDDEN, "Not your booking")
    updated = _move(booking_id, "cancelled", _ACTIVE)
    _notify(
        _owner_id(booking["provider_id"]),
        "Booking cancelled",
        f"{user.name} cancelled the ride from {booking['pickup']} to {booking['destination']}.",
        booking_id,
    )
    return _enrich([updated])[0]


@router.post("/{booking_id}/respond", response_model=Booking)
def respond_to_booking(
    booking_id: str, body: BookingRespond, user: UserProfile = Depends(get_current_user)
) -> dict:
    booking = _get(booking_id)
    if not _can_respond(user, booking["provider_id"]):
        raise HTTPException(status.HTTP_403_FORBIDDEN, "Not allowed to respond to this booking")
    to, from_ = _TRANSITIONS[body.action]
    updated = _move(booking_id, to, from_)
    _notify(
        booking["student_id"],
        f"Booking {to}",
        f"Your ride from {booking['pickup']} to {booking['destination']} was {to}.",
        booking_id,
    )
    return _enrich([updated])[0]
