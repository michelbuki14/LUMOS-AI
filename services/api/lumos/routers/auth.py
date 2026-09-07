# =============================================================================
# LUMOS AI — Auth Router
# =============================================================================

from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer, OAuth2PasswordRequestForm
from pydantic import BaseModel, EmailStr
from datetime import datetime, timedelta
from jose import JWTError, jwt

from lumos.config import settings

import hashlib

router = APIRouter()

def _hash_password(password: str) -> str:
    """Simple SHA256 hash for local dev (use bcrypt in production)."""
    return hashlib.sha256(password.encode()).hexdigest()

def _verify_password(password: str, password_hash: str) -> bool:
    """Verify password against hash."""
    return _hash_password(password) == password_hash

oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/api/v1/auth/login")


class Token(BaseModel):
    access_token: str
    refresh_token: str
    token_type: str = "bearer"


class TokenData(BaseModel):
    user_id: str | None = None


class UserCreate(BaseModel):
    email: EmailStr
    password: str
    name: str | None = None


class UserResponse(BaseModel):
    id: str
    email: str
    name: str | None = None
    created_at: datetime


class UserInDB(BaseModel):
    id: str
    email: str
    name: str | None = None
    password_hash: str


# Demo users (in production, use database)
DEMO_USERS = {
    "demo@lumos.ai": UserInDB(
        id="usr_demo_001",
        email="demo@lumos.ai",
        name="Demo User",
        password_hash=_hash_password("demo123"),
    ),
}


def create_access_token(data: dict, expires_delta: timedelta | None = None) -> str:
    to_encode = data.copy()
    expire = datetime.utcnow() + (expires_delta or timedelta(minutes=15))
    to_encode.update({"exp": expire})
    return jwt.encode(to_encode, settings.JWT_SECRET, algorithm=settings.JWT_ALGORITHM)


def create_refresh_token(data: dict) -> str:
    to_encode = data.copy()
    expire = datetime.utcnow() + timedelta(days=settings.JWT_REFRESH_TOKEN_EXPIRE_DAYS)
    to_encode.update({"exp": expire})
    return jwt.encode(to_encode, settings.JWT_SECRET, algorithm=settings.JWT_ALGORITHM)


async def get_current_user(token: str = Depends(oauth2_scheme)) -> UserInDB:
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Could not validate credentials",
        headers={"WWW-Authenticate": "Bearer"},
    )
    try:
        payload = jwt.decode(token, settings.JWT_SECRET, algorithms=[settings.JWT_ALGORITHM])
        user_id: str = payload.get("sub")
        if user_id is None:
            raise credentials_exception
    except JWTError:
        raise credentials_exception
    
    user = DEMO_USERS.get(user_id)
    if user is None:
        raise credentials_exception
    return user


@router.post("/login", response_model=Token)
async def login(form_data: OAuth2PasswordRequestForm = Depends()):
    """Authenticate user and return JWT tokens."""
    user = DEMO_USERS.get(form_data.username)
    if not user or not _verify_password(form_data.password, user.password_hash):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect email or password",
            headers={"WWW-Authenticate": "Bearer"},
        )
    
    access_token = create_access_token(
        data={"sub": user.email},
        expires_delta=timedelta(minutes=settings.JWT_ACCESS_TOKEN_EXPIRE_MINUTES),
    )
    refresh_token = create_refresh_token(data={"sub": user.email})
    
    return Token(
        access_token=access_token,
        refresh_token=refresh_token,
    )


@router.post("/register", response_model=UserResponse)
async def register(user_data: UserCreate):
    """Register a new user account."""
    if user_data.email in DEMO_USERS:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Email already registered",
        )
    
    # In production: save to database
    return UserResponse(
        id="usr_new_001",
        email=user_data.email,
        name=user_data.name,
        created_at=datetime.utcnow(),
    )


@router.get("/me", response_model=UserResponse)
async def get_me(current_user: UserInDB = Depends(get_current_user)):
    """Get current user profile."""
    return UserResponse(
        id=current_user.id,
        email=current_user.email,
        name=current_user.name,
        created_at=datetime.utcnow(),
    )


@router.post("/refresh", response_model=Token)
async def refresh_token():
    """Refresh an expired access token."""
    return {"message": "Token refreshed"}
