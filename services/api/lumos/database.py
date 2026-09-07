# =============================================================================
# LUMOS AI — Database Connection & Session Management (SQLite-compatible)
# =============================================================================

from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession, async_sessionmaker
from sqlalchemy.orm import DeclarativeBase

from lumos.config import settings

# Detect if we're using SQLite
is_sqlite = settings.DATABASE_URL.startswith("sqlite")

# SQLite doesn't support pool_size/max_overflow
if is_sqlite:
    engine = create_async_engine(
        settings.DATABASE_URL,
        echo=settings.APP_DEBUG,
    )
else:
    engine = create_async_engine(
        settings.DATABASE_URL,
        echo=settings.APP_DEBUG,
        pool_size=20,
        max_overflow=10,
        pool_pre_ping=True,
    )

# Create async session factory
AsyncSessionLocal = async_sessionmaker(
    engine,
    class_=AsyncSession,
    expire_on_commit=False,
)


class Base(DeclarativeBase):
    """Base class for all database models."""
    pass


async def get_db() -> AsyncSession:
    """Dependency that provides a database session."""
    async with AsyncSessionLocal() as session:
        try:
            yield session
        finally:
            await session.close()


async def init_db():
    """Initialize database tables."""
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)


async def close_db():
    """Close database connections."""
    await engine.dispose()
