from sqlalchemy import Column, Integer, String, Boolean, ForeignKey
from app.core.database import Base

class EventCheck(Base):
    __tablename__ = "event_checks"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(String, ForeignKey("users.id"))
    event_id = Column(String)
    check_index = Column(Integer)
    is_checked = Column(Boolean, default=False)