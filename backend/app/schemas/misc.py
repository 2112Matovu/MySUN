"""Bookmarks + notifications — mirrors
student_app/lib/providers/bookmarks_provider.dart and
student_app/lib/data/models/app_notification.dart.
"""

from datetime import datetime
from typing import Literal

from pydantic import BaseModel

ContentType = Literal["announcement", "event"]


class BookmarkToggleRequest(BaseModel):
    content_type: ContentType
    content_id: str


class Notification(BaseModel):
    id: str
    title: str
    body: str
    type: str  # 'announcement' | 'event' | 'reminder' | 'transport' | 'system'
    created_at: datetime
    related_id: str | None = None
    is_read: bool = False
