"""Async SQLAlchemy engine + session factory + FastAPI dependency."""
from collections.abc import AsyncGenerator

from sqlalchemy.ext.asyncio import (
    AsyncSession,
    async_sessionmaker,
    create_async_engine,
)

from app.config import settings

# `echo=False` в продакшне; для отладки заменить на settings.log_level == "DEBUG".
engine = create_async_engine(settings.database_url, echo=False, future=True)

SessionLocal = async_sessionmaker(
    engine,
    class_=AsyncSession,
    expire_on_commit=False,
    autoflush=False,
)


async def get_session() -> AsyncGenerator[AsyncSession, None]:
    """FastAPI dependency: даёт сессию, гарантирует commit или rollback."""
    async with SessionLocal() as session:
        try:
            yield session
            await session.commit()
        except Exception:
            await session.rollback()
            raise
