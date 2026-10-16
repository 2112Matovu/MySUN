from typing import Literal

from pydantic import BaseModel, Field

ServiceCategory = Literal["food", "health", "it_support", "library"]


class CampusServiceCreate(BaseModel):
    category: ServiceCategory
    name: str = Field(min_length=2, max_length=100)
    description: str | None = Field(default=None, max_length=500)
    location: str | None = Field(default=None, max_length=120)
    opening_hours: str | None = Field(default=None, max_length=80)
    contact_phone: str | None = Field(default=None, max_length=30)


class CampusService(CampusServiceCreate):
    id: str
