import re
from pydantic import BaseModel, field_validator
from typing import Optional

class RegisterRequest(BaseModel):
    username: str
    email: str
    password: str
    name: str
    phone_number: Optional[str] = None
    connected_calendar: Optional[str] = None
    recovery_message: Optional[str] = None

    @field_validator('password')
    @classmethod
    def password_must_have_special_char(cls, v: str) -> str:
        if len(v) < 8:
            raise ValueError('비밀번호는 8자 이상이어야 합니다.')
        if not re.search(r'[!@#$%^&*(),.?":{}|<>]', v):
            raise ValueError('비밀번호에 특수문자(!@#$%^&* 등)를 1개 이상 포함해야 합니다.')
        return v

class LoginResponse(BaseModel):
    access_token: str
    refresh_token: str
    token_type: str = "bearer"

class UserResponse(BaseModel):
    id: str
    username: str
    email: str
    name: str
    phone_number: Optional[str] = None
    connected_calendar: Optional[str] = None

    class Config:
        from_attributes = True
