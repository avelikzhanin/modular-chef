"""Async SQLAlchemy engine + session factory + FastAPI dependency."""
from collections.abc import AsyncGenerator

from sqlalchemy.ext.asyncio import (
    AsyncSession,
    async_sessionmaker,
    create_async_engine,
)

from app.config import settings

# `echo=False` в продакшне; для отладки заменить на settings.log_level == "DEBUG".
# pool_pre_ping: Railway рвёт простаивающие соединения, без проверки
# первый запрос после паузы падал с «connection is closed».
engine = create_async_engine(
    settings.database_url,
    echo=False,
    future=True,
    pool_pre_ping=True,
    pool_recycle=300,
)

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
