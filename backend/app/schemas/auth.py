from typing import Optional
from pydantic import BaseModel, EmailStr, Field, validator
import re


class UserBase(BaseModel):
    email: EmailStr
    name: Optional[str] = None


class UserCreate(UserBase):
    password: str = Field(..., min_length=6)
    phone: Optional[str] = None

    @validator('password')
    def password_strength(cls, v):
        if len(v) < 6:
            raise ValueError('Password must be at least 6 characters')
        return v
    
    @validator('phone')
    def validate_phone(cls, v):
        if v is None:
            return v
        
        # Simple phone validation - can be enhanced
        pattern = r'^\+?[0-9]{10,15}$'
        if not re.match(pattern, v):
            raise ValueError('Invalid phone number format')
        return v


class UserLogin(BaseModel):
    email: EmailStr
    password: str


class UserResponse(UserBase):
    id: str

    class Config:
        orm_mode = True


class Token(BaseModel):
    access_token: str
    token_type: str = "bearer"


class TokenData(BaseModel):
    sub: Optional[str] = None
    exp: Optional[int] = None


class ValidationResponse(BaseModel):
    valid: bool
    user: Optional[UserResponse] = None


class SuccessResponse(BaseModel):
    success: bool = True
    message: Optional[str] = None