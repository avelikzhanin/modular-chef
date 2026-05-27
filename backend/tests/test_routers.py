"""Endpoint smoke-tests через FastAPI TestClient.

Подменяем `ClaudeClient.generate` mock'ом — без сетевых вызовов и без ключа.
БД для роутов всё ещё нужна (поэтому override и для `get_session`).
"""
from collections.abc import AsyncGenerator

import pytest
import pytest_asyncio
from fastapi.testclient import TestClient
from sqlalchemy.ext.asyncio import (
    AsyncEngine,
    AsyncSession,
    async_sessionmaker,
    create_async_engine,
)

from app.db import get_session
from app.main import app
from app.models import Base, Module
from app.routers.menus import get_claude_client
from app.schemas import (
    DayPlanSchema,
    GenerationRequestSchema,
    MenuSummarySchema,
    MenuWeekSchema,
    PlannedMealSchema,
    WeeklyMenuSchema,
)


@pytest_asyncio.fixture
async def engine() -> AsyncGenerator[AsyncEngine, None]:
    eng = create_async_engine("sqlite+aiosqlite:///:memory:", future=True)
    async with eng.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
    yield eng
    await eng.dispose()


@pytest_asyncio.fixture
async def seeded_session(engine: AsyncEngine) -> AsyncGenerator[AsyncSession, None]:
    sm = async_sessionmaker(engine, class_=AsyncSession, expire_on_commit=False)
    async with sm() as s:
        s.add(
            Module(
                id="chicken_breast",
                name="Курица",
                emoji="🍗",
                category="protein",
                tags=["lean"],
                methods=["Запечь 40мин"],
                storage_zone="fridge",
                storage_days=3,
                storage_tip="Контейнеры",
            )
        )
        await s.commit()
        yield s


class _FakeClaudeClient:
    """Возвращает фиксированный WeeklyMenu — никаких сетевых вызовов."""

    async def generate(self, request, session) -> WeeklyMenuSchema:  # noqa: ARG002
        meal = PlannedMealSchema(title="Курица + рис", moduleIds=["chicken_breast", "rice"], reheatMinutes=2)
        day = DayPlanSchema(
            weekday="monday",
            shortName="Пн",
            breakfast=PlannedMealSchema(title="Овсянка", moduleIds=["oatmeal_jar"]),
            lunch=meal,
            dinner=PlannedMealSchema(title="Лосось", moduleIds=["salmon"]),
        )
        week = MenuWeekSchema(index=0, name="Неделя 1", days=[day])
        return WeeklyMenuSchema(
            weeks=[week],
            summary=MenuSummarySchema(uniqueDishes=3, totalMeals=3, modulesUsed=4),
        )


@pytest.fixture
def client(seeded_session: AsyncSession) -> TestClient:
    """TestClient с DI override: фейковый Claude + наша сессия."""

    async def _override_session():
        yield seeded_session

    app.dependency_overrides[get_session] = _override_session
    app.dependency_overrides[get_claude_client] = lambda: _FakeClaudeClient()
    try:
        yield TestClient(app)
    finally:
        app.dependency_overrides.clear()


def test_health(client: TestClient) -> None:
    r = client.get("/health")
    assert r.status_code == 200
    assert r.json() == {"status": "ok"}


def test_generate_menu_returns_well_formed_menu(client: TestClient) -> None:
    body = GenerationRequestSchema(
        picks={"proteins": ["chicken_breast"], "sides": ["rice"], "soups": [], "breakfasts": ["oatmeal_jar"], "custom": []}
    ).model_dump()

    r = client.post("/menus/generate", json=body)

    assert r.status_code == 200, r.text
    data = r.json()
    assert "weeks" in data
    assert data["weeks"][0]["days"][0]["lunch"]["title"] == "Курица + рис"
    assert data["summary"]["totalMeals"] == 3


def test_catalog_modules_returns_seeded_data(client: TestClient) -> None:
    r = client.get("/catalog/modules")
    assert r.status_code == 200
    modules = r.json()
    assert len(modules) == 1
    assert modules[0]["id"] == "chicken_breast"
    assert modules[0]["storage"]["zone"] == "fridge"


def test_generate_menu_rejects_invalid_request(client: TestClient) -> None:
    """`picks` обязателен — без него 422 от pydantic."""
    r = client.post("/menus/generate", json={})
    assert r.status_code == 422
