from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.api.v1.router import api_router
from app.core.config import get_settings

app = FastAPI(title="MySun API", version="0.1.0")

settings = get_settings()
app.add_middleware(
    CORSMiddleware,
    # The Flutter app authenticates with a Bearer token, not cookies, so
    # allow_credentials stays False — that's what lets allow_origins be "*"
    # for local dev, when Flutter Web's dev server port changes every run.
    # Lock this down to real origins (settings.cors_origin_list) for
    # anything beyond local development.
    allow_origins=["*"] if settings.app_env == "development" else settings.cors_origin_list,
    allow_credentials=False,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(api_router)


@app.get("/health")
def health() -> dict:
    return {"status": "ok", "env": settings.app_env}
