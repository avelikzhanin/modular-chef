"""GET /catalog/modules — клиент может обновить каталог не пересобирая APK."""
from fastapi import APIRouter, Depends
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.db import get_session
from app.models import Module

router = APIRouter(prefix="/catalog", tags=["catalog"])


@router.get("/modules")
async def list_modules(session: AsyncSession = Depends(get_session)) -> list[dict]:
    """Возвращает модули в том же формате, что и `assets/data/modules.json`.

    Клиент может закэшировать ответ и подменить bundle-ную копию свежими данными.
    """
    result = await session.execute(select(Module).order_by(Module.category, Module.name))
    modules = result.scalars().all()
    return [
        {
            "id": m.id,
            "name": m.name,
            "emoji": m.emoji,
            "category": m.category,
            "tags": m.tags,
            "methods": m.methods,
            "storage": {
                "zone": m.storage_zone,
                "days": m.storage_days,
                "tip": m.storage_tip or "",
            },
            "caloriesPer100g": m.calories_per_100g,
            "prepMinutes": m.prep_minutes,
        }
        for m in modules
    ]
