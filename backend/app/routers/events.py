from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import Optional
from datetime import datetime
from app.core.deps import get_db, get_current_user
from app.models.user import User
from app.models.event import Event
from app.schemas.event import EventCreate, EventResponse

router = APIRouter(prefix="/events", tags=["events"])

@router.get("", response_model=list[EventResponse])
def get_events(from_: Optional[datetime] = None, to: Optional[datetime] = None,
               db: Session = Depends(get_db), user: User = Depends(get_current_user)):
    q = db.query(Event).filter(Event.user_id == user.id)
    if from_: q = q.filter(Event.start_at >= from_)
    if to: q = q.filter(Event.start_at <= to)
    return q.order_by(Event.start_at).all()

@router.post("", response_model=EventResponse)
def create_event(req: EventCreate, db: Session = Depends(get_db), user: User = Depends(get_current_user)):
    event = Event(**req.model_dump(), user_id=user.id)
    db.add(event); db.commit(); db.refresh(event)
    return event

@router.put("/{event_id}", response_model=EventResponse)
def update_event(event_id: str, req: EventCreate, db: Session = Depends(get_db), user: User = Depends(get_current_user)):
    event = db.query(Event).filter(Event.id == event_id, Event.user_id == user.id).first()
    if not event: raise HTTPException(status_code=404)
    for k, v in req.model_dump().items(): setattr(event, k, v)
    db.commit(); db.refresh(event)
    return event

@router.delete("/{event_id}")
def delete_event(event_id: str, db: Session = Depends(get_db), user: User = Depends(get_current_user)):
    event = db.query(Event).filter(Event.id == event_id, Event.user_id == user.id).first()
    if not event: raise HTTPException(status_code=404)
    db.delete(event); db.commit()
    return {"message": "deleted"}

@router.get("/upcoming", response_model=list[EventResponse])
def upcoming(limit: int = 5, db: Session = Depends(get_db), user: User = Depends(get_current_user)):
    return db.query(Event).filter(Event.user_id == user.id, Event.start_at >= datetime.utcnow()).order_by(Event.start_at).limit(limit).all()
