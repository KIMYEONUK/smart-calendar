from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
import os

from app.core.config import settings
from app.core.database import Base, engine
from app.routers import auth, events, ocr
from app.routers import photos
from app.models import event_photo  # 테이블 생성용

os.makedirs("uploads", exist_ok=True)
Base.metadata.create_all(bind=engine)

app = FastAPI(
    title=settings.APP_NAME,
    version="1.0.0",
    docs_url="/docs",
    redoc_url="/redoc",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# static 파일 서빙 (업로드된 사진)
app.mount("/api/photos", StaticFiles(directory="uploads"), name="photos")

app.include_router(auth.router, prefix="/api")
app.include_router(events.router, prefix="/api")
app.include_router(ocr.router, prefix="/api")
app.include_router(photos.router, prefix="/api")

@app.get("/")
def root():
    return {"app": settings.APP_NAME, "status": "running"}
