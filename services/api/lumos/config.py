# =============================================================================
# LUMOS AI — Configuration
# =============================================================================

from pydantic_settings import BaseSettings
from typing import List


class Settings(BaseSettings):
    """Application settings loaded from environment variables."""
    
    # Application
    APP_NAME: str = "LUMOS AI"
    APP_VERSION: str = "1.0.0"
    APP_ENV: str = "development"
    APP_DEBUG: bool = True
    APP_SECRET_KEY: str = "dev_secret_key_change_in_production"
    
    # Database
    DATABASE_URL: str = "postgresql+asyncpg://lumos:lumos_dev_password@localhost:5432/lumos"
    
    # Redis
    REDIS_URL: str = "redis://localhost:6379/0"
    
    # Storage
    MINIO_ENDPOINT: str = "localhost:9000"
    MINIO_ACCESS_KEY: str = "lumos"
    MINIO_SECRET_KEY: str = "lumos_dev_password"
    MINIO_BUCKET: str = "lumos-assets"
    MINIO_USE_SSL: bool = False
    
    # Auth
    JWT_SECRET: str = "dev_jwt_secret_change_in_production"
    JWT_ALGORITHM: str = "HS256"
    JWT_ACCESS_TOKEN_EXPIRE_MINUTES: int = 30
    JWT_REFRESH_TOKEN_EXPIRE_DAYS: int = 7
    
    # Services
    AI_SERVICE_URL: str = "http://localhost:8001"
    RENDER_SERVICE_URL: str = "http://localhost:8002"
    
    # CORS
    CORS_ORIGINS: List[str] = ["http://localhost:3000", "http://localhost:8080", "http://localhost:5173"]
    
    # Performance
    WORKERS: int = 4
    MAX_CONCURRENT_UPLOADS: int = 10
    
    # Features
    ENABLE_AI_FEATURES: bool = True
    ENABLE_CLOUD_SYNC: bool = False
    ENABLE_OFFLINE_MODE: bool = True
    
    class Config:
        env_file = ".env"
        case_sensitive = True


settings = Settings()
