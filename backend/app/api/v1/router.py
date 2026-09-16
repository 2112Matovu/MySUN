from fastapi import APIRouter

from app.api.v1 import (
    accommodation,
    admin,
    announcements,
    auth,
    bookmarks,
    events,
    notifications,
    publisher,
    transport,
    uploads,
)

api_router = APIRouter(prefix="/api/v1")
api_router.include_router(auth.router)
api_router.include_router(announcements.router)
api_router.include_router(events.router)
api_router.include_router(accommodation.router)
api_router.include_router(transport.router)
api_router.include_router(bookmarks.router)
api_router.include_router(notifications.router)
api_router.include_router(publisher.router)
api_router.include_router(admin.router)
api_router.include_router(uploads.router)
