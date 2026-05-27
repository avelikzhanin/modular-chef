"""Seed-script тесты: грузит каталог из общего JSON, идемпотентен."""
from sqlalchemy.ext.asyncio import AsyncSession

from app.seed.seed_modules import (
    count_modules,
    load_modules_payload,
    seed_modules,
)


async def test_seed_loads_modules_from_shared_json(session: AsyncSession) -> None:
    """Загружает реальные данные из assets/data/modules.json."""
    payload = load_modules_payload()
    assert len(payload) >= 30, "ожидается ≥30 модулей в каталоге"

    inserted = await seed_modules(session, payload=payload)
    await session.commit()

    assert inserted == len(payload)
    assert await count_modules(session) == len(payload)


async def test_seed_is_idempotent(session: AsyncSession) -> None:
    """Повторный сидинг не дублирует записи, обновляет существующие."""
    payload = load_modules_payload()

    await seed_modules(session, payload=payload)
    await session.commit()
    first_count = await count_modules(session)

    await seed_modules(session, payload=payload)
    await session.commit()
    second_count = await count_modules(session)

    assert first_count == second_count


async def test_seed_overwrites_changed_fields(session: AsyncSession) -> None:
    """Если поле в JSON изменилось — re-seed обновляет запись."""
    payload = [
        {
            "id": "test_module",
            "name": "Старое имя",
            "emoji": "❓",
            "category": "vegetable",
            "tags": ["old"],
            "methods": [],
            "storage": {"zone": "fridge", "days": 3, "tip": "old tip"},
        }
    ]
    await seed_modules(session, payload=payload)
    await session.commit()

    payload[0]["name"] = "Новое имя"
    payload[0]["tags"] = ["new"]
    await seed_modules(session, payload=payload)
    await session.commit()

    from app.models import Module

    refreshed = await session.get(Module, "test_module")
    assert refreshed is not None
    assert refreshed.name == "Новое имя"
    assert refreshed.tags == ["new"]


async def test_seed_payload_has_required_categories() -> None:
    """Каталог должен покрывать все 6 категорий, иначе UI будет полупустой."""
    payload = load_modules_payload()
    categories = {m["category"] for m in payload}
    expected = {"protein", "side", "soup", "breakfast", "vegetable", "sauce"}
    missing = expected - categories
    assert not missing, f"в каталоге не хватает категорий: {missing}"
