"""CRUD-smoke на все 6 таблиц. Гарантирует, что схема консистентна:
SQLAlchemy-модели и миграция описывают одно и то же.
"""
import uuid

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models import (
    Module,
    ShoppingList,
    StorageItem,
    User,
    UserDish,
    WeeklyMenu,
)


async def test_user_crud(session: AsyncSession) -> None:
    u = User(email="alice@example.com", display_name="Alice")
    session.add(u)
    await session.flush()
    assert u.id is not None
    assert u.created_at is not None

    result = await session.execute(select(User).where(User.email == "alice@example.com"))
    fetched = result.scalar_one()
    assert fetched.display_name == "Alice"


async def test_module_crud(session: AsyncSession) -> None:
    m = Module(
        id="chicken_breast",
        name="Курица",
        emoji="🍗",
        category="protein",
        tags=["lean", "fast"],
        methods=["Запечь 40мин", "Гриль 25мин"],
        storage_zone="fridge",
        storage_days=3,
        storage_tip="Контейнеры подписаны",
        calories_per_100g=165,
        prep_minutes=25,
    )
    session.add(m)
    await session.flush()

    fetched = await session.get(Module, "chicken_breast")
    assert fetched is not None
    assert fetched.tags == ["lean", "fast"]
    assert fetched.methods[1] == "Гриль 25мин"


async def test_weekly_menu_with_cascade(session: AsyncSession) -> None:
    u = User(email="bob@example.com")
    session.add(u)
    await session.flush()

    menu = WeeklyMenu(
        user_id=u.id,
        menu_json={"weeks": [{"index": 0, "name": "Неделя 1", "days": []}]},
        is_active=True,
    )
    session.add(menu)
    await session.flush()

    fetched = await session.get(WeeklyMenu, menu.id)
    assert fetched is not None
    assert fetched.menu_json["weeks"][0]["name"] == "Неделя 1"
    assert fetched.is_active is True


async def test_shopping_list(session: AsyncSession) -> None:
    u = User(email="carol@example.com")
    session.add(u)
    await session.flush()
    menu = WeeklyMenu(user_id=u.id, menu_json={"weeks": []})
    session.add(menu)
    await session.flush()

    sl = ShoppingList(
        menu_id=menu.id,
        week_index=0,
        items_json=[
            {"name": "Куриное филе, 1.2 кг", "section": "Мясо", "checked": False},
            {"name": "Брокколи, 2 кочана", "section": "Овощи", "checked": True},
        ],
    )
    session.add(sl)
    await session.flush()

    fetched = await session.get(ShoppingList, sl.id)
    assert fetched is not None
    assert len(fetched.items_json) == 2
    assert fetched.items_json[1]["checked"] is True


async def test_user_dish(session: AsyncSession) -> None:
    u = User(email="dave@example.com")
    session.add(u)
    await session.flush()

    d = UserDish(
        user_id=u.id,
        name="Шакшука",
        emoji="🍳",
        tags=["weekend", "protein"],
        recipe_text="Помидоры + яйца на сковороде",
        storage_zone="fridge",
        storage_days=2,
    )
    session.add(d)
    await session.flush()

    fetched = await session.get(UserDish, d.id)
    assert fetched is not None
    assert fetched.tags == ["weekend", "protein"]


async def test_storage_item_with_module_fk(session: AsyncSession) -> None:
    u = User(email="eve@example.com")
    m = Module(
        id="rice",
        name="Рис",
        emoji="🍚",
        category="side",
        tags=[],
        methods=[],
        storage_zone="fridge",
        storage_days=3,
    )
    session.add_all([u, m])
    await session.flush()

    item = StorageItem(
        user_id=u.id,
        module_id="rice",
        module_name="Рис",
        emoji="🍚",
        zone="fridge",
        portion_count=4,
    )
    session.add(item)
    await session.flush()

    fetched = await session.get(StorageItem, item.id)
    assert fetched is not None
    assert fetched.module_id == "rice"
    assert fetched.portion_count == 4


async def test_storage_item_without_module(session: AsyncSession) -> None:
    """module_id опционален — можно добавить произвольный продукт."""
    u = User(email="frank@example.com")
    session.add(u)
    await session.flush()

    item = StorageItem(
        user_id=u.id,
        module_id=None,
        module_name="Свежий хлеб",
        zone="pantry",
        portion_count=1,
    )
    session.add(item)
    await session.flush()

    assert item.id is not None


async def test_unique_email_constraint(session: AsyncSession) -> None:
    session.add(User(email="dup@example.com"))
    await session.flush()
    session.add(User(email="dup@example.com"))
    try:
        await session.flush()
    except Exception as e:  # noqa: BLE001
        # SQLite поднимает IntegrityError; Postgres — UniqueViolation
        assert "UNIQUE" in str(e) or "unique" in str(e).lower()
        return
    raise AssertionError("expected UNIQUE constraint failure on duplicate email")


async def test_user_uuid_returns_uuid_type(session: AsyncSession) -> None:
    u = User(email="g@example.com")
    session.add(u)
    await session.flush()
    assert isinstance(u.id, uuid.UUID)
