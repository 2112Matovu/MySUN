"""Re-runnable: creates the public Storage bucket that
app/api/v1/uploads.py writes content images into. Run once per Supabase
project (and again if this bucket was ever deleted).

Run from backend/ with the venv active:
    python scripts/create_storage_bucket.py
"""

import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from app.core.supabase_client import get_supabase_admin  # noqa: E402
from app.services.uploads_service import BUCKET_NAME  # noqa: E402

MAX_UPLOAD_BYTES = 5 * 1024 * 1024


def main() -> None:
    admin = get_supabase_admin()
    existing = [b.name for b in admin.storage.list_buckets()]
    if BUCKET_NAME in existing:
        print(f"Bucket '{BUCKET_NAME}' already exists — nothing to do.")
        return

    admin.storage.create_bucket(
        BUCKET_NAME,
        options={
            "public": True,
            "file_size_limit": MAX_UPLOAD_BYTES,
            "allowed_mime_types": ["image/jpeg", "image/png", "image/webp"],
        },
    )
    print(f"Created public bucket '{BUCKET_NAME}'.")


if __name__ == "__main__":
    main()
