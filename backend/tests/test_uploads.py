import io

import pytest

# A 1x1 transparent PNG — small, valid image bytes for the "real upload" path.
TINY_PNG = bytes.fromhex(
    "89504e470d0a1a0a0000000d494844520000000100000001080600000"
    "01f15c4890000000a49444154789c6360000002000155273de5000000"
    "0049454e44ae426082"
)


class _FakeBucket:
    def __init__(self):
        self.uploaded = None

    def upload(self, path, data, options):
        self.uploaded = (path, data, options)
        return {"path": path}

    def get_public_url(self, path):
        return f"https://fake.supabase.co/storage/v1/object/public/content-images/{path}"


class _FakeStorage:
    def __init__(self, bucket):
        self._bucket = bucket

    def from_(self, _name):
        return self._bucket


class _FakeAdminClient:
    def __init__(self, bucket):
        self.storage = _FakeStorage(bucket)


@pytest.fixture
def fake_bucket(monkeypatch):
    bucket = _FakeBucket()
    monkeypatch.setattr(
        "app.services.uploads_service.get_supabase_admin",
        lambda: _FakeAdminClient(bucket),
    )
    return bucket


def test_upload_rejects_non_publisher(client, as_role, fake_bucket):
    as_role("student")
    res = client.post(
        "/api/v1/uploads",
        files={"file": ("photo.png", io.BytesIO(TINY_PNG), "image/png")},
    )
    assert res.status_code == 403


def test_upload_requires_auth(client, fake_bucket):
    res = client.post(
        "/api/v1/uploads",
        files={"file": ("photo.png", io.BytesIO(TINY_PNG), "image/png")},
    )
    assert res.status_code == 401


def test_upload_success(client, as_role, fake_bucket):
    as_role("publisher")
    res = client.post(
        "/api/v1/uploads",
        files={"file": ("photo.png", io.BytesIO(TINY_PNG), "image/png")},
    )
    assert res.status_code == 200
    url = res.json()["url"]
    assert url.startswith(
        "https://fake.supabase.co/storage/v1/object/public/content-images/"
    )
    # Path is namespaced under the uploading user's id.
    path, data, options = fake_bucket.uploaded
    assert path.startswith("usr-test/")
    assert path.endswith(".png")
    assert data == TINY_PNG
    assert options["content-type"] == "image/png"


def test_upload_rejects_unsupported_type(client, as_role, fake_bucket):
    as_role("publisher")
    res = client.post(
        "/api/v1/uploads",
        files={"file": ("doc.pdf", io.BytesIO(b"%PDF-1.4 not an image"), "application/pdf")},
    )
    assert res.status_code == 400
    assert fake_bucket.uploaded is None


def test_upload_rejects_oversized_file(client, as_role, fake_bucket):
    as_role("publisher")
    oversized = b"\x00" * (5 * 1024 * 1024 + 1)
    res = client.post(
        "/api/v1/uploads",
        files={"file": ("big.png", io.BytesIO(oversized), "image/png")},
    )
    assert res.status_code == 413
    assert fake_bucket.uploaded is None
