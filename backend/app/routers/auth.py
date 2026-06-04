from fastapi import APIRouter, Depends, HTTPException
from fastapi.security import OAuth2PasswordRequestForm
from sqlalchemy.orm import Session
from app.core.deps import get_db, get_current_user
from app.core.security import verify_password, get_password_hash, create_access_token, create_refresh_token
from app.models.user import User
from app.schemas.auth import RegisterRequest, LoginResponse, UserResponse

router = APIRouter(prefix="/auth", tags=["auth"])

@router.post("/register")
def register(req: RegisterRequest, db: Session = Depends(get_db)):
    if db.query(User).filter(User.username == req.username).first():
        raise HTTPException(status_code=409, detail="Username already exists")
    if db.query(User).filter(User.email == req.email).first():
        raise HTTPException(status_code=409, detail="Email already exists")
    user = User(
        username=req.username, email=req.email, name=req.name,
        hashed_password=get_password_hash(req.password),
        phone_number=req.phone_number, connected_calendar=req.connected_calendar,
        recovery_message=req.recovery_message,
    )
    db.add(user); db.commit(); db.refresh(user)
    return LoginResponse(
        access_token=create_access_token({"sub": user.id}),
        refresh_token=create_refresh_token({"sub": user.id}),
    )

@router.post("/login")
def login(form: OAuth2PasswordRequestForm = Depends(), db: Session = Depends(get_db)):
    user = db.query(User).filter(User.username == form.username).first()
    if not user or not verify_password(form.password, user.hashed_password):
        raise HTTPException(status_code=401, detail="Invalid credentials")
    return LoginResponse(
        access_token=create_access_token({"sub": user.id}),
        refresh_token=create_refresh_token({"sub": user.id}),
    )

@router.get("/me", response_model=UserResponse)
def me(user: User = Depends(get_current_user)):
    return user

@router.post("/logout")
def logout():
    return {"message": "logged out"}

@router.post("/refresh")
def refresh(data: dict, db: Session = Depends(get_db)):
    from app.core.security import decode_token
    try:
        payload = decode_token(data.get("refresh_token", ""))
        user_id = payload.get("sub")
        user = db.query(User).filter(User.id == user_id).first()
        if not user:
            raise HTTPException(status_code=401)
        return {"access_token": create_access_token({"sub": user.id})}
    except:
        raise HTTPException(status_code=401, detail="Invalid refresh token")

@router.post("/find-password")
def find_password(data: dict):
    return {"message": "If email exists, reset link sent"}
