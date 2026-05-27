"""Сидинг каталога модулей из общего JSON в таблицу `modules`.

Запуск:
    python -m app.seed.seed_modules

Идемпотентно: использует upsert по PK (на Postgres — ON CONFLICT DO UPDATE,
на SQLite — DELETE/INSERT через merge()).

Источник: ``D:/Desktop/modular_chef/assets/data/modules.json`` — тот же JSON,
который читает Flutter-клиент через ``CatalogService``. Один источник правды
для каталога между мобильным приложением и бэком.
"""
import asyncio
import json
import logging
from pathlib import Path

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.db import SessionLocal
from app.models import Module

logger = logging.getLogger(__name__)


def _modules_json_path() -> Path:
    """Поднимается из backend/app/seed/ к корню проекта и берёт assets/data."""
    here = Path(__file__).resolve()
    project_root = here.parents[3]  # backend/app/seed/seed_modules.py → modular_chef/
    return project_root / "assets" / "data" / "modules.json"


def load_modules_payload(path: Path | None = None) -> list[dict]:
    """Читает JSON в плоский список dict'ов."""
    target = path or _modules_json_path()
    with target.open(encoding="utf-8") as f:
        return json.load(f)


def _payload_to_columns(entry: dict) -> dict:
    """Раскладывает JSON-объект модуля в kwargs SQLAlchemy-модели."""
    storage = entry.get("storage") or {}
    return {
        "id": entry["id"],
        "name": entry["name"],
        "emoji": entry["emoji"],
        "category": entry["category"],
        "tags": entry.get("tags") or [],
        "methods": entry.get("methods") or [],
        "storage_zone": storage.get("zone", "fridge"),
        "storage_days": int(storage.get("days") or 0),
        "storage_tip": storage.get("tip") or None,
        "calories_per_100g": entry.get("caloriesPer100g"),
        "prep_minutes": entry.get("prepMinutes"),
    }


async def seed_modules(
    session: AsyncSession,
    payload: list[dict] | None = None,
) -> int:
    """Сидит каталог в сессию. Возвращает количество upsert'нутых записей.

    Один транзакционный апсерт через merge() — переносимо между Postgres и SQLite,
    идемпотентно при повторных запусках (обновляет существующие, добавляет новые).
    """
    data = payload if payload is not None else load_modules_payload()
    for entry in data:
        cols = _payload_to_columns(entry)
        existing = await session.get(Module, cols["id"])
        if existing is None:
            session.add(Module(**cols))
        else:
            for k, v in cols.items():
                setattr(existing, k, v)
    await session.flush()
    return len(data)


async def count_modules(session: AsyncSession) -> int:
    """Helper для тестов: сколько модулей в таблице."""
    result = await session.execute(select(Module))
    return len(result.scalars().all())


async def _main() -> None:
    logging.basicConfig(level=logging.INFO, format="%(levelname)s %(message)s")
    async with SessionLocal() as session:
        count = await seed_modules(session)
        await session.commit()
        logger.info("Seeded %d modules", count)


if __name__ == "__main__":
    asyncio.run(_main())
