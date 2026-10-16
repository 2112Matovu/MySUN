"""Mirrors student_app/lib/data/models/publisher_submission.dart and
publisher_performance.dart.
"""

from datetime import datetime
from typing import Any, Literal

from pydantic import BaseModel

SubmissionType = Literal["announcement", "event", "accommodation", "transport"]
SubmissionStatus = Literal["draft", "scheduled", "published", "removed"]


class DraftSave(BaseModel):
    id: str | None = None  # set to update an existing draft in place
    type: SubmissionType
    title: str
    form_data: dict[str, Any] | None = None


class PublisherSubmission(BaseModel):
    id: str
    publisher_id: str
    type: SubmissionType
    title: str
    status: SubmissionStatus
    content_id: str | None = None
    form_data: dict[str, Any] | None = None
    publisher_name: str | None = None
    removal_reason: str | None = None
    publish_at: datetime | None = None  # set while status is scheduled
    updated_at: datetime


class PublisherPerformance(BaseModel):
    total_submissions: int
    published: int
    removed: int
    drafts: int
    by_type: dict[str, int]
    estimated_views: int
    engagement_percent: float
