"""Mirrors student_app/lib/data/models/admin_analytics.dart and the
Admin dashboard/moderation/grant-role screens.
"""

from pydantic import BaseModel

from app.schemas.user import Role


class RemovalRequest(BaseModel):
    reason: str


class RoleGrantRequest(BaseModel):
    new_role: Role


class AdminAnalytics(BaseModel):
    daily_active_users: int
    monthly_active_users: int
    total_users: int
    publisher_count: int
    announcements_published: int
    events_created: int
    avg_engagement_percent: float
    api_online: bool = True
    database_health_percent: float = 100
    storage_used_percent: float = 0
