"""Pytest fixtures: SQLite-in-memory engine + чистая сессия на каждый тест.

Postgres для тестов не нужен — модели спроектированы переносимыми:
`Uuid(native_uuid=...)` + `JSON` тип работают и в SQLite, и в Postgres.
"""
from collections.abc import AsyncGenerator

import pytest_asyncio
from sqlalchemy.ext.asyncio import (
    AsyncEngine,
    AsyncSession,
    async_sessionmaker,
    create_async_engine,
)

from app.models import Base


@pytest_asyncio.fixture
async def engine() -> AsyncGenerator[AsyncEngine, None]:
    """Каждый тест получает свежий SQLite-в-памяти с поднятой схемой."""
    eng = create_async_engine("sqlite+aiosqlite:///:memory:", future=True)
    async with eng.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
    yield eng
    await eng.dispose()


@pytest_asyncio.fixture
async def session(engine: AsyncEngine) -> AsyncGenerator[AsyncSession, None]:
    """Сессия для CRUD-тестов. Откатывается в конце теста."""
    sm = async_sessionmaker(engine, class_=AsyncSession, expire_on_commit=False)
    async with sm() as s:
        yield s
