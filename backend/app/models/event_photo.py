from sqlalchemy import Column, String, ForeignKey, DateTime
from sqlalchemy.sql import func
import uuid
from app.core.database import Base

class EventPhoto(Base):
    __tablename__ = "event_photos"
    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    event_id = Column(String, ForeignKey("events.id", ondelete="CASCADE"))
    user_id = Column(String, ForeignKey("users.id"))
    file_path = Column(String)  # 서버 저장 경로
    url_path = Column(String)   # 클라이언트 접근 URL
    created_at = Column(DateTime, server_default=func.now())
