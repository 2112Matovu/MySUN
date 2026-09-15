"""Announcement, Event, Accommodation, Transport — mirrors
student_app/lib/data/models/{announcement,event,accommodation_listing,transport_provider}.dart
field-for-field.
"""

from datetime import datetime
from typing import Literal

from pydantic import BaseModel

AccommodationType = Literal["hostel", "rental"]
RoomSharing = Literal["shared", "private", "both"]


class AnnouncementCreate(BaseModel):
    title: str
    description: str
    category: str
    department: str | None = None  # falls back to the publisher's faculty/name
    is_important: bool = False
    image_url: str | None = None
    expires_at: datetime | None = None
    draft_id: str | None = None  # set when publishing resumes a saved draft


class Announcement(BaseModel):
    id: str
    title: str
    description: str
    category: str
    publisher_name: str
    published_at: datetime
    is_important: bool = False
    image_url: str | None = None
    expires_at: datetime | None = None


class EventCreate(BaseModel):
    title: str
    description: str
    category: str
    organizer_name: str
    date_time: datetime
    venue: str
    end_date_time: datetime | None = None
    image_url: str | None = None
    capacity: int | None = None
    is_featured: bool = False
    draft_id: str | None = None


class Event(BaseModel):
    id: str
    title: str
    description: str
    category: str
    organizer_name: str
    date_time: datetime
    venue: str
    end_date_time: datetime | None = None
    image_url: str | None = None
    capacity: int | None = None
    registered_count: int = 0
    is_featured: bool = False


class AccommodationCreate(BaseModel):
    name: str
    type: AccommodationType
    location: str
    price: int
    is_gazetted: bool = False
    room_sharing: RoomSharing = "shared"
    contact_phone: str
    image_urls: list[str] = []
    description: str | None = None
    draft_id: str | None = None


class Accommodation(BaseModel):
    id: str
    name: str
    type: AccommodationType
    location: str
    price: int
    is_gazetted: bool = False
    room_sharing: RoomSharing = "shared"
    contact_phone: str
    image_urls: list[str] = []
    description: str | None = None
    publisher_name: str | None = None
    is_available: bool = True


class TransportProviderCreate(BaseModel):
    name: str
    phone_number: str
    contact_person: str | None = None
    operating_hours: str | None = None
    service_areas: list[str] = []
    image_url: str | None = None
    draft_id: str | None = None


class TransportProvider(BaseModel):
    id: str
    name: str
    phone_number: str
    service_type: str = "boda"
    contact_person: str | None = None
    operating_hours: str | None = None
    service_areas: list[str] = []
    image_url: str | None = None
    is_verified: bool = False
    rating: float = 0
    rating_count: int = 0


class BusSchedule(BaseModel):
    id: str
    route_name: str
    departure_point: str
    destination: str
    departure_time: str
    estimated_duration_minutes: int
    operating_days: str
    status: str = "active"
    notes: str | None = None
