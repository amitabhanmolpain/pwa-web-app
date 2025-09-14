from fastapi import APIRouter, Depends, HTTPException, status, Response, Cookie
from fastapi.security import OAuth2PasswordRequestForm
from typing import Optional

from ..schemas.auth import UserCreate, UserResponse, Token, ValidationResponse
from ..core.security import create_access_token, verify_password, get_password_hash
from ..db.session import get_db
from ..db.models import User
from sqlalchemy.orm import Session
import uuid
from datetime import timedelta

router = APIRouter()


@router.post("/register", response_model=UserResponse, status_code=status.HTTP_201_CREATED)
async def register(user_data: UserCreate, db: Session = Depends(get_db)):
    # Check if user already exists
    existing_user = db.query(User).filter(User.email == user_data.email).first()
    if existing_user:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Email already registered"
        )
    
    # Create new user
    hashed_password = get_password_hash(user_data.password)
    
    new_user = User(
        id=str(uuid.uuid4()),
        email=user_data.email,
        name=user_data.name,
        hashed_password=hashed_password,
        phone=user_data.phone
    )
    
    db.add(new_user)
    db.commit()
    db.refresh(new_user)
    
    return new_user


@router.post("/login", response_model=Token)
async def login(
    response: Response,
    form_data: OAuth2PasswordRequestForm = Depends(),
    db: Session = Depends(get_db)
):
    # Find user by email
    user = db.query(User).filter(User.email == form_data.username).first()
    
    # Verify user exists and password is correct
    if not user or not verify_password(form_data.password, user.hashed_password):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect email or password",
            headers={"WWW-Authenticate": "Bearer"},
        )
    
    # Create access token
    access_token_expires = timedelta(minutes=60 * 24 * 7)  # 7 days
    access_token = create_access_token(
        data={"sub": user.id}, expires_delta=access_token_expires
    )
    
    # Set cookie
    response.set_cookie(
        key="access_token",
        value=f"Bearer {access_token}",
        httponly=True,
        max_age=60 * 60 * 24 * 7,  # 7 days
        samesite="lax",
        secure=True,  # Set to False for development without HTTPS
    )
    
    return {"access_token": access_token, "token_type": "bearer"}


@router.post("/validate", response_model=ValidationResponse)
async def validate_token(
    access_token: Optional[str] = Cookie(None, alias="access_token"),
    db: Session = Depends(get_db)
):
    from ..core.security import decode_token
    
    if not access_token:
        return {"valid": False}
    
    # Remove "Bearer " prefix if present
    if access_token.startswith("Bearer "):
        access_token = access_token[7:]
    
    try:
        token_data = decode_token(access_token)
        user_id = token_data.get("sub")
        
        # Get user from database
        user = db.query(User).filter(User.id == user_id).first()
        if not user:
            return {"valid": False}
        
        return {"valid": True, "user": user}
    except:
        return {"valid": False}


@router.post("/logout")
async def logout(response: Response):
    # Clear cookie
    response.delete_cookie(
        key="access_token",
        httponly=True,
        samesite="lax",
        secure=True,  # Set to False for development without HTTPS
    )
    
    return {"success": True, "message": "Logged out successfully"}