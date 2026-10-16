from fastapi import APIRouter, Depends

from app.core.security import require_admin_level
from app.schemas.campus_service import CampusService, CampusServiceCreate, ServiceCategory
from app.schemas.user import UserProfile
from app.services.table_repo import TableRepo

router = APIRouter(prefix="/campus-services", tags=["campus-services"])
repo = TableRepo("campus_services")


@router.get("", response_model=list[CampusService])
def list_services(category: ServiceCategory | None = None) -> list[dict]:
    """Food, health, IT support and library services on campus."""
    return repo.list(order_by="name", category=category)


@router.post("", response_model=CampusService)
def create_service(
    body: CampusServiceCreate, _: UserProfile = Depends(require_admin_level)
) -> dict:
    return repo.create(body.model_dump(mode="json"))


@router.delete("/{id}", status_code=204)
def delete_service(id: str, _: UserProfile = Depends(require_admin_level)) -> None:
    repo.delete(id)
