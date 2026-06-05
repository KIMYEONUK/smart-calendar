from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from app.core.deps import get_db, get_current_user
from app.models.user import User
from app.models.event_check import EventCheck

router = APIRouter(prefix="/events", tags=["checks"])

@router.get("/{event_id}/checks")
def get_checks(event_id: str, db: Session = Depends(get_db), user: User = Depends(get_current_user)):
    checks = db.query(EventCheck).filter(
        EventCheck.event_id == event_id,
        EventCheck.user_id == user.id
    ).all()
    return checks

@router.post("/{event_id}/checks")
def save_check(event_id: str, data: dict, db: Session = Depends(get_db), user: User = Depends(get_current_user)):
    check_index = data.get("check_index")
    is_checked = data.get("is_checked", False)

    check = db.query(EventCheck).filter(
        EventCheck.event_id == event_id,
        EventCheck.user_id == user.id,
        EventCheck.check_index == check_index
    ).first()

    if check:
        check.is_checked = is_checked
    else:
        check = EventCheck(
            user_id=user.id,
            event_id=event_id,
            check_index=check_index,
            is_checked=is_checked
        )
        db.add(check)

    db.commit()
    return {"message": "저장됨", "is_checked": is_checked}