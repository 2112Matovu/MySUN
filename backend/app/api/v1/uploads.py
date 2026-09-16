from fastapi import APIRouter, Depends, File, Request, UploadFile
from pydantic import BaseModel

from app.core.limiter import limiter
from app.core.security import require_publisher
from app.schemas.user import UserProfile
from app.services.uploads_service import upload_image

router = APIRouter(prefix="/uploads", tags=["uploads"])


class UploadResponse(BaseModel):
    url: str


@router.post("", response_model=UploadResponse)
@limiter.limit("20/minute")
async def upload(
    request: Request,
    file: UploadFile = File(...),
    user: UserProfile = Depends(require_publisher),
) -> UploadResponse:
    """Backs the "Add Image" button on every publishing form
    (student_app/lib/core/network/uploads_service.dart). Gated to
    publishers, same as the content-creation endpoints themselves —
    nothing else needs to burn Storage quota."""
    data = await file.read()
    url = upload_image(
        user_id=user.id,
        content_type=file.content_type or "application/octet-stream",
        data=data,
    )
    return UploadResponse(url=url)
