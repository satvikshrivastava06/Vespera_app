"""SQLAlchemy async engine and session factory.

The DATABASE_URL env var selects the backend:
  - PostgreSQL (production):  postgresql+asyncpg://user:pass@host/dbname
  - SQLite (tests / offline):  sqlite+aiosqlite:///./vespera_test.db

Call ``init_db()`` once at startup to create tables that have no migration yet
(i.e. in test environments). Production uses Alembic; init_db() is a no-op
when tables already exist.
"""

from __future__ import annotations

from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker, create_async_engine
from sqlalchemy.orm import DeclarativeBase

from app.config import settings

engine = create_async_engine(
    settings.DATABASE_URL,
    echo=False,
    # Pool configuration that works for both SQLite and Postgres.
    # asyncpg doesn't support check_same_thread; aiosqlite requires it disabled.
    connect_args={"check_same_thread": False}
    if settings.DATABASE_URL.startswith("sqlite")
    else {},
    pool_pre_ping=True,
)

AsyncSessionLocal = async_sessionmaker(
    bind=engine,
    class_=AsyncSession,
    expire_on_commit=False,
    autoflush=False,
    autocommit=False,
)


class Base(DeclarativeBase):
    pass


async def get_db() -> AsyncSession:  # FastAPI dependency
    async with AsyncSessionLocal() as session:
        try:
            yield session
            await session.commit()
        except Exception:
            await session.rollback()
            raise


async def init_db() -> None:
    """Create all tables that do not yet exist (test / SQLite only).

    In production the schema is managed by Alembic migrations.
    """
    async with engine.begin() as conn:
        # Import models so their metadata is registered before create_all.
        import app.infrastructure.models  # noqa: F401

        await conn.run_sync(Base.metadata.create_all)
