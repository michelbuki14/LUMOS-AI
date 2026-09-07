# =============================================================================
# LUMOS AI — FastAPI Backend Application
# =============================================================================

from contextlib import asynccontextmanager

import structlog
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from lumos.config import settings
from lumos.database import close_db, init_db
from lumos.middleware import LoggingMiddleware, RateLimitMiddleware
from lumos.routers import ai, assets, auth, batch, export, galleries, projects, search

logger = structlog.get_logger()


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Application lifespan handler."""
    # Startup
    logger.info("Starting LUMOS AI API", version=settings.APP_VERSION)
    await init_db()
    logger.info("Database initialized")
    yield
    # Shutdown
    await close_db()
    logger.info("LUMOS AI API shutdown complete")


def create_app() -> FastAPI:
    """Create and configure the FastAPI application."""
    app = FastAPI(
        title="LUMOS AI API",
        description="AI Operating System for Professional Photography",
        version=settings.APP_VERSION,
        docs_url="/docs",
        redoc_url="/redoc",
        lifespan=lifespan,
    )

    # Middleware
    app.add_middleware(
        CORSMiddleware,
        allow_origins=settings.CORS_ORIGINS,
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
    )
    app.add_middleware(LoggingMiddleware)
    app.add_middleware(RateLimitMiddleware)

    # Include routers
    app.include_router(auth.router, prefix="/api/v1/auth", tags=["Auth"])
    app.include_router(assets.router, prefix="/api/v1/assets", tags=["Assets"])
    app.include_router(projects.router, prefix="/api/v1/projects", tags=["Projects"])
    app.include_router(galleries.router, prefix="/api/v1/galleries", tags=["Galleries"])
    app.include_router(ai.router, prefix="/api/v1/ai", tags=["AI"])
    app.include_router(batch.router, prefix="/api/v1/batch", tags=["Batch"])
    app.include_router(export.router, prefix="/api/v1/export", tags=["Export"])
    app.include_router(search.router, prefix="/api/v1/search", tags=["Search"])

    @app.get("/health")
    async def health_check():
        return {"status": "healthy", "version": settings.APP_VERSION}

    @app.get("/")
    async def root():
        return {
            "name": "LUMOS AI",
            "version": settings.APP_VERSION,
            "docs": "/docs",
        }

    return app


app = create_app()
