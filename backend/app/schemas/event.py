from pydantic import BaseModel
from typing import Optional
from datetime import datetime

class EventCreate(BaseModel):
    title: str
    start_at: datetime
    end_at: Optional[datetime] = None
    is_all_day: bool = False
    category: str = "personal"
    location: Optional[str] = None
    contact_email: Optional[str] = None
    memo: Optional[str] = None
    link: Optional[str] = None
    reminder_minutes: Optional[int] = None

class EventResponse(EventCreate):
    id: str
    is_verified: bool = False

    class Config:
        from_attributes = True
