import asyncio
import contextlib
import logging

from fastapi import FastAPI, Request, status
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from slowapi import _rate_limit_exceeded_handler
from slowapi.errors import RateLimitExceeded
from slowapi.middleware import SlowAPIMiddleware

from app.api.v1.router import api_router
from app.core.config import get_settings
from app.core.limiter import limiter
from app.core.logging import request_logging_middleware, setup_logging

settings = get_settings()
setup_logging(settings.log_level)
logger = logging.getLogger("mysun")

if settings.sentry_dsn:
    import sentry_sdk

    sentry_sdk.init(dsn=settings.sentry_dsn, environment=settings.app_env, traces_sample_rate=0.1)
    logger.info("Sentry initialized", extra={"path": "startup"})

async def _reminder_loop() -> None:
    """Releases scheduled posts and sends event reminders every 5 minutes. Each (event, user, reminder)
    is logged in the database, so overlapping runs never double-send."""
    from app.services.reminders import run_event_reminders
    from app.services.scheduling import release_due_content

    await asyncio.sleep(30)
    while True:
        try:
            await asyncio.to_thread(release_due_content)
            await asyncio.to_thread(run_event_reminders)
        except Exception:
            logger.exception("Event reminder run failed")
        await asyncio.sleep(300)


@contextlib.asynccontextmanager
async def lifespan(_: FastAPI):
    task = asyncio.create_task(_reminder_loop()) if settings.reminders_enabled else None
    yield
    if task:
        task.cancel()


# The interactive docs list every route, so only serve them during local development.
_docs = settings.app_env == "development"
app = FastAPI(
    title="MySun API",
    version="0.1.0",
    lifespan=lifespan,
    docs_url="/docs" if _docs else None,
    redoc_url="/redoc" if _docs else None,
    openapi_url="/openapi.json" if _docs else None,
)

app.state.limiter = limiter
app.add_exception_handler(RateLimitExceeded, _rate_limit_exceeded_handler)
app.add_middleware(SlowAPIMiddleware)

app.middleware("http")(request_logging_middleware)

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


@app.exception_handler(Exception)
async def unhandled_exception_handler(request: Request, exc: Exception) -> JSONResponse:
    # Registering a handler for the bare `Exception` class makes Starlette
    # install it on ServerErrorMiddleware (the outermost layer) rather than
    # ExceptionMiddleware, so this response bypasses request_logging_middleware's
    # own return path entirely — request_id/X-Request-ID must be set here too,
    # not just there, or an error response goes out without either.
    request_id = getattr(request.state, "request_id", "unknown")
    logger.exception(
        "Unhandled exception",
        extra={
            "request_id": request_id,
            "method": request.method,
            "path": request.url.path,
            "status_code": status.HTTP_500_INTERNAL_SERVER_ERROR,
        },
    )
    return JSONResponse(
        status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
        content={"detail": "Internal server error"},
        headers={"X-Request-ID": request_id},
    )


@app.get("/health")
def health() -> dict:
    return {"status": "ok", "env": settings.app_env}
