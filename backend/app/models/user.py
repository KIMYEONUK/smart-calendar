from sqlalchemy import Column, String, DateTime
from sqlalchemy.sql import func
import uuid
from app.core.database import Base

class User(Base):
    __tablename__ = "users"
    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    username = Column(String, unique=True, index=True)
    email = Column(String, unique=True, index=True)
    name = Column(String)
    hashed_password = Column(String)
    phone_number = Column(String, nullable=True)
    connected_calendar = Column(String, nullable=True)
    recovery_message = Column(String, nullable=True)
    created_at = Column(DateTime, server_default=func.now())
