from fastapi import APIRouter, Depends, HTTPException, status, Request
from fastapi.responses import RedirectResponse
import httpx
from authlib.integrations.starlette_client import OAuth
from starlette.config import Config

from ..schemas.auth import Token, UserResponse
from ..core.security import create_access_token
from ..db.session import get_db
from ..db.models import User
from ..core.oauth_config import get_oauth_client, get_oauth_settings
from sqlalchemy.orm import Session
import uuid
from datetime import timedelta

router = APIRouter()
oauth_settings = get_oauth_settings()


@router.get("/google")
async def login_google():
    """
    Redirect to Google OAuth login page
    """
    oauth = get_oauth_client()
    redirect_uri = f"{oauth_settings.BASE_URL}/api/auth/google/callback"
    return await oauth.google.authorize_redirect(redirect_uri)


@router.get("/google/callback")
async def auth_google_callback(request: Request, db: Session = Depends(get_db)):
    """
    Handle Google OAuth callback
    """
    oauth = get_oauth_client()
    try:
        token = await oauth.google.authorize_access_token(request)
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Could not validate OAuth credentials: {str(e)}"
        )
    
    user_info = token.get('userinfo')
    if not user_info or not user_info.get('email'):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid user info received from OAuth provider"
        )
    
    # Check if user exists
    email = user_info['email']
    db_user = db.query(User).filter(User.email == email).first()
    
    if not db_user:
        # Create new user
        db_user = User(
            id=str(uuid.uuid4()),
            email=email,
            name=user_info.get('name'),
            is_verified=user_info.get('email_verified', False),
            oauth_provider="google",
            oauth_id=user_info.get('sub')
        )
        db.add(db_user)
        db.commit()
        db.refresh(db_user)
    elif not db_user.oauth_provider:
        # Update existing user with OAuth info
        db_user.oauth_provider = "google"
        db_user.oauth_id = user_info.get('sub')
        db_user.is_verified = user_info.get('email_verified', False)
        db.commit()
    
    # Create access token
    access_token_expires = timedelta(minutes=60 * 24 * 7)  # 7 days
    access_token = create_access_token(
        data={"sub": db_user.id}, expires_delta=access_token_expires
    )
    
    # Redirect to frontend with token
    frontend_url = oauth_settings.FRONTEND_URL
    return RedirectResponse(
        url=f"{frontend_url}/auth/oauth-callback?token={access_token}&provider=google"
    )