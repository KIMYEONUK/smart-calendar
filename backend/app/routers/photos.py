import os
import uuid
from fastapi import APIRouter, Depends, HTTPException, UploadFile, File
from fastapi.responses import FileResponse
from sqlalchemy.orm import Session
from PIL import Image
import io

from app.core.deps import get_db, get_current_user
from app.models.user import User
from app.models.event import Event
from app.models.event_photo import EventPhoto

router = APIRouter(prefix="/events", tags=["photos"])

UPLOAD_DIR = "uploads"
MAX_SIZE = (1200, 1200)   # 최대 해상도
QUALITY = 70              # JPEG 압축 품질

os.makedirs(UPLOAD_DIR, exist_ok=True)


@router.post("/{event_id}/photos")
async def upload_photo(
    event_id: str,
    file: UploadFile = File(...),
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
):
    # 이벤트 소유권 확인
    event = db.query(Event).filter(
        Event.id == event_id, Event.user_id == user.id
    ).first()
    if not event:
        raise HTTPException(status_code=404, detail="이벤트를 찾을 수 없습니다.")

    # 이미지 형식 확인
    if not file.content_type.startswith("image/"):
        raise HTTPException(status_code=400, detail="이미지 파일만 업로드 가능합니다.")

    # 압축 처리
    raw = await file.read()
    img = Image.open(io.BytesIO(raw))

    # EXIF 회전 보정
    try:
        from PIL import ImageOps
        img = ImageOps.exif_transpose(img)
    except Exception:
        pass

    # RGB 변환 (PNG 투명도 제거)
    if img.mode != "RGB":
        img = img.convert("RGB")

    # 리사이즈 (비율 유지)
    img.thumbnail(MAX_SIZE, Image.LANCZOS)

    # 저장
    filename = f"{uuid.uuid4()}.jpg"
    file_path = os.path.join(UPLOAD_DIR, filename)
    img.save(file_path, "JPEG", quality=QUALITY, optimize=True)

    url_path = f"/api/photos/{filename}"
    photo = EventPhoto(
        event_id=event_id,
        user_id=user.id,
        file_path=file_path,
        url_path=url_path,
    )
    db.add(photo)
    db.commit()
    db.refresh(photo)

    return {"id": photo.id, "url": url_path}


@router.get("/{event_id}/photos")
def get_photos(
    event_id: str,
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
):
    event = db.query(Event).filter(
        Event.id == event_id, Event.user_id == user.id
    ).first()
    if not event:
        raise HTTPException(status_code=404)
    photos = db.query(EventPhoto).filter(EventPhoto.event_id == event_id).all()
    return [{"id": p.id, "url": p.url_path, "created_at": p.created_at} for p in photos]


@router.delete("/{event_id}/photos/{photo_id}")
def delete_photo(
    event_id: str,
    photo_id: str,
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
):
    photo = db.query(EventPhoto).filter(
        EventPhoto.id == photo_id, EventPhoto.user_id == user.id
    ).first()
    if not photo:
        raise HTTPException(status_code=404)
    # 파일 삭제
    if os.path.exists(photo.file_path):
        os.remove(photo.file_path)
    db.delete(photo)
    db.commit()
    return {"message": "deleted"}
