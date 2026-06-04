from sqlalchemy import Column, String, Boolean, DateTime, Integer, ForeignKey
from sqlalchemy.sql import func
import uuid
from app.core.database import Base

class Event(Base):
    __tablename__ = "events"
    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    user_id = Column(String, ForeignKey("users.id"))
    title = Column(String)
    start_at = Column(DateTime)
    end_at = Column(DateTime, nullable=True)
    is_all_day = Column(Boolean, default=False)
    category = Column(String, default="personal")
    location = Column(String, nullable=True)
    contact_email = Column(String, nullable=True)
    memo = Column(String, nullable=True)
    link = Column(String, nullable=True)
    reminder_minutes = Column(Integer, nullable=True)
    is_verified = Column(Boolean, default=False)
    created_at = Column(DateTime, server_default=func.now())
