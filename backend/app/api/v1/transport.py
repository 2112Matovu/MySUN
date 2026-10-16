from fastapi import APIRouter, Depends, HTTPException, status

from app.core.security import get_current_user, require_publisher
from app.core.supabase_client import get_supabase_admin
from app.schemas.booking import RatingRequest, RatingResult
from app.schemas.content import BusSchedule, TransportProvider, TransportProviderCreate
from app.schemas.user import UserProfile
from app.services.publisher_service import record_publish, remove_own_content
from app.services.table_repo import TableRepo

router = APIRouter(prefix="/transport", tags=["transport"])
repo = TableRepo("transport_providers")
schedules_repo = TableRepo("bus_schedules")


@router.get("", response_model=list[TransportProvider])
def list_providers(query: str | None = None) -> list[dict]:
    """Boda-only for now (§6 services framework). Search matches name or a
    place of service (a service area) — see the Services > Transport search
    bar in the Flutter app."""
    if not query:
        items = repo.list(order_by="rating", desc=True)
        return sorted(items, key=lambda p: (not p["is_verified"], -p["rating"]))

    q = query.strip().lower()
    result = get_supabase_admin().table("transport_providers").select("*").execute()
    return [
        p
        for p in result.data
        if q in p["name"].lower() or any(q in area.lower() for area in p.get("service_areas", []))
    ]


@router.get("/bus-schedule", response_model=list[BusSchedule])
def list_bus_schedules() -> list[dict]:
    return schedules_repo.list(order_by="departure_time")


@router.get("/{id}", response_model=TransportProvider)
def get_provider(id: str) -> dict:
    return repo.get(id)


@router.get("/{id}/my-rating")
def my_rating(id: str, user: UserProfile = Depends(get_current_user)) -> dict:
    """The signed-in user's own rating of this rider, or {"stars": null}."""
    rows = (
        get_supabase_admin()
        .table("transport_ratings")
        .select("stars")
        .eq("provider_id", id)
        .eq("user_id", user.id)
        .execute()
        .data
    )
    return {"stars": rows[0]["stars"] if rows else None}


@router.post("/{id}/rate", response_model=RatingResult)
def rate_provider(
    id: str, body: RatingRequest, user: UserProfile = Depends(get_current_user)
) -> dict:
    """One rating per user per rider; rating again replaces it. The rider's
    average and count are recomputed in Postgres."""
    result = (
        get_supabase_admin()
        .rpc(
            "rate_transport_provider",
            {
                "p_provider_id": id,
                "p_user_id": user.id,
                "p_stars": body.stars,
                "p_comment": body.comment,
            },
        )
        .execute()
        .data
    )
    if result["status"] == "not_found":
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Rider not found")
    return {
        "rating": result["rating"],
        "rating_count": result["rating_count"],
        "my_stars": body.stars,
    }


@router.post("", response_model=TransportProvider)
def create_provider(
    body: TransportProviderCreate, user: UserProfile = Depends(require_publisher)
) -> dict:
    """Publishes immediately, unverified until an admin reviews it (§5.1)."""
    payload = body.model_dump(mode="json", exclude={"draft_id"})
    payload["service_type"] = "boda"
    # Never trust the client for this: only an admin can verify a listing
    # (PATCH /admin/transport/{id}/verified).
    payload["is_verified"] = False
    created = repo.create(payload)
    record_publish(
        publisher_id=user.id,
        publisher_name=user.faculty or user.name,
        type="transport",
        title=created["name"],
        content_id=created["id"],
        draft_id=body.draft_id,
    )
    return created


@router.delete("/{id}", status_code=204)
def delete_provider(id: str, user: UserProfile = Depends(get_current_user)) -> None:
    remove_own_content(user.id, "transport", id)
