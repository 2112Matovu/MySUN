import uuid

from fastapi import HTTPException, status

from app.core.supabase_client import get_supabase_admin

BUCKET_NAME = "content-images"
MAX_UPLOAD_BYTES = 5 * 1024 * 1024

# Maps an accepted MIME type to the file extension stored in Supabase
# Storage — keeps uploaded paths predictable and rejects anything that
# isn't actually an image up front, before it touches Storage.
_ALLOWED_CONTENT_TYPES = {
    "image/jpeg": "jpg",
    "image/png": "png",
    "image/webp": "webp",
}


def upload_image(*, user_id: str, content_type: str, data: bytes) -> str:
    ext = _ALLOWED_CONTENT_TYPES.get(content_type)
    if ext is None:
        raise HTTPException(
            status.HTTP_400_BAD_REQUEST,
            "Unsupported image type — use JPEG, PNG, or WebP.",
        )
    if len(data) > MAX_UPLOAD_BYTES:
        raise HTTPException(
            status.HTTP_413_CONTENT_TOO_LARGE,
            "Image is too large — 5MB maximum.",
        )
    if not data:
        raise HTTPException(status.HTTP_400_BAD_REQUEST, "Empty file.")

    path = f"{user_id}/{uuid.uuid4()}.{ext}"
    admin = get_supabase_admin()
    admin.storage.from_(BUCKET_NAME).upload(
        path, data, {"content-type": content_type}
    )
    return admin.storage.from_(BUCKET_NAME).get_public_url(path)
