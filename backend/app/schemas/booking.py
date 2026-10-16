from datetime import datetime
from typing import Literal

from pydantic import BaseModel, Field

BookingStatus = Literal["pending", "accepted", "declined", "cancelled", "completed"]


class BookingCreate(BaseModel):
    provider_id: str
    pickup: str = Field(min_length=2, max_length=120)
    destination: str = Field(min_length=2, max_length=120)
    requested_time: datetime | None = None  # None = as soon as possible
    note: str | None = Field(default=None, max_length=300)


class BookingRespond(BaseModel):
    action: Literal["accept", "decline", "complete"]


class Booking(BaseModel):
    id: str
    student_id: str
    provider_id: str
    pickup: str
    destination: str
    requested_time: datetime | None = None
    note: str | None = None
    status: BookingStatus
    created_at: datetime
    provider_name: str | None = None
    provider_phone: str | None = None
    student_name: str | None = None


class RatingRequest(BaseModel):
    stars: int = Field(ge=1, le=5)
    comment: str | None = Field(default=None, max_length=300)


class RatingResult(BaseModel):
    rating: float
    rating_count: int
    my_stars: int
