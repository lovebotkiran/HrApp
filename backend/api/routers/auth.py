from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from datetime import datetime

from infrastructure.database.connection import get_db
from infrastructure.database.models import User, UserRole, Role
from infrastructure.security.auth import (
    verify_password,
    get_password_hash,
    create_access_token,
    create_refresh_token,
    decode_token,
    get_current_user
)
from application.schemas import (
    UserCreate,
    UserLogin,
    UserResponse,
    TokenResponse,
    MessageResponse
)
from application.services.linkedin_service import LinkedInService
from core.config import settings
import secrets
from fastapi.responses import RedirectResponse

router = APIRouter()
linkedin_service = LinkedInService()

# In-memory storage for OAuth states (should ideally be Redis in production)
oauth_states = {}


@router.post("/register", response_model=UserResponse, status_code=status.HTTP_201_CREATED)
async def register(user_data: UserCreate, db: Session = Depends(get_db)):
    """
    Register a new user.
    """
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
        email=user_data.email,
        password_hash=hashed_password,
        first_name=user_data.first_name,
        last_name=user_data.last_name,
        phone=user_data.phone,
        department=user_data.department,
        designation=user_data.designation
    )
    
    db.add(new_user)
    db.commit()
    db.refresh(new_user)
    
    # Assign default role (if needed)
    # For now, users need to be assigned roles by admin
    
    return new_user


@router.post("/login", response_model=TokenResponse)
async def login(credentials: UserLogin, db: Session = Depends(get_db)):
    """
    Login and get access token.
    """
    # Find user
    user = db.query(User).filter(User.email == credentials.email).first()
    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect email or password"
        )
    
    # Verify password
    if not verify_password(credentials.password, user.password_hash):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect email or password"
        )
    
    # Check if user is active
    if not user.is_active:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="User account is inactive"
        )
    
    # Update last login
    user.last_login = datetime.utcnow()
    db.commit()
    
    # Create tokens
    access_token = create_access_token(data={"sub": str(user.id)})
    refresh_token = create_refresh_token(data={"sub": str(user.id)})
    
    return {
        "access_token": access_token,
        "refresh_token": refresh_token,
        "token_type": "bearer"
    }


@router.post("/refresh", response_model=TokenResponse)
async def refresh_token(refresh_token: str, db: Session = Depends(get_db)):
    """
    Refresh access token using refresh token.
    """
    try:
        payload = decode_token(refresh_token)
        
        if payload.get("type") != "refresh":
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid token type"
            )
        
        user_id = payload.get("sub")
        if not user_id:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid token"
            )
        
        # Verify user exists and is active
        user = db.query(User).filter(User.id == user_id).first()
        if not user or not user.is_active:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="User not found or inactive"
            )
        
        # Create new tokens
        new_access_token = create_access_token(data={"sub": str(user.id)})
        new_refresh_token = create_refresh_token(data={"sub": str(user.id)})
        
        return {
            "access_token": new_access_token,
            "refresh_token": new_refresh_token,
            "token_type": "bearer"
        }
    
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid or expired token"
        )


@router.get("/me", response_model=UserResponse)
async def get_current_user_info(current_user: User = Depends(get_current_user)):
    """
    Get current user information.
    """
    return current_user


@router.post("/logout", response_model=MessageResponse)
async def logout(current_user: User = Depends(get_current_user)):
    """
    Logout current user.
    Note: In a stateless JWT system, logout is handled client-side by removing the token.
    This endpoint is provided for consistency and can be extended for token blacklisting.
    """
    return {
        "message": "Successfully logged out",
        "success": True
    }


@router.get("/linkedin/login")
async def linkedin_login():
    """
    Initiate LinkedIn OAuth2 login flow.
    """
    state = secrets.token_urlsafe(32)
    # Store state for verification in callback
    oauth_states[state] = True
    
    redirect_uri = f"{settings.CORS_ORIGINS.split(',')[0]}/auth/linkedin/callback" # Fallback to frontend URL
    # or use a backend callback if the frontend can't handle it easily
    backend_callback = f"http://localhost:8000{settings.API_PREFIX}/auth/linkedin/callback"
    
    auth_url = linkedin_service.get_authorization_url(redirect_uri=backend_callback, state=state)
    return RedirectResponse(auth_url)


@router.get("/linkedin/callback")
async def linkedin_callback(code: str, state: str, db: Session = Depends(get_db)):
    """
    Handle LinkedIn OAuth2 callback.
    """
    # Verify state
    if state not in oauth_states:
        raise HTTPException(status_code=400, detail="Invalid state parameter")
    del oauth_states[state]
    
    backend_callback = f"http://localhost:8000{settings.API_PREFIX}/auth/linkedin/callback"
    
    # Exchange code for access token
    access_token = await linkedin_service.get_access_token(code=code, redirect_uri=backend_callback)
    if not access_token:
        raise HTTPException(status_code=400, detail="Failed to get access token from LinkedIn")
    
    # Get user info
    linkedin_user = await linkedin_service.get_user_info(access_token)
    if not linkedin_user:
        raise HTTPException(status_code=400, detail="Failed to get user info from LinkedIn")
    
    email = linkedin_user.get("email")
    first_name = linkedin_user.get("given_name", "")
    last_name = linkedin_user.get("family_name", "")
    
    if not email:
        raise HTTPException(status_code=400, detail="LinkedIn did not provide an email address")
    
    # Find or create user
    user = db.query(User).filter(User.email == email).first()
    if not user:
        # Create new user if they don't exist
        user = User(
            email=email,
            password_hash="LINKEDIN_LOGIN",  # Placeholder
            first_name=first_name,
            last_name=last_name,
            is_active=True,
            is_verified=True
        )
        db.add(user)
        db.commit()
        db.refresh(user)
    
    # Create tokens
    local_access_token = create_access_token(data={"sub": str(user.id)})
    local_refresh_token = create_refresh_token(data={"sub": str(user.id)})
    
    # Redirect back to frontend with tokens
    # In a real app, you might use a more secure way to pass tokens back to the frontend
    frontend_url = settings.CORS_ORIGINS.split(',')[0]
    redirect_url = f"{frontend_url}/auth/callback?access_token={local_access_token}&refresh_token={local_refresh_token}"
    
    return RedirectResponse(redirect_url)
