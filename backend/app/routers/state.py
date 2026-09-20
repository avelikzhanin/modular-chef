"""Синк состояния домохозяйства: ключ-значение, last-write-wins.

Клиент (Flutter) пишет сюда локальные разделы (запасы, план дня, покупки...)
и читает их при старте / смене роли — так телефоны Шефа и Гостя видят одно.
"""
from typing import Any

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.db import get_session
from app.models import HouseholdState
from app.routers.menus import _demo_user

router = APIRouter(prefix="/state", tags=["state"])


@router.get("/{key}")
async def get_state(
    key: str,
    session: AsyncSession = Depends(get_session),
) -> dict[str, Any]:
    """Значение ключа или 404, если его ещё не писали."""
    user = await _demo_user(session)
    result = await session.execute(
        select(HouseholdState).where(
            HouseholdState.user_id == user.id, HouseholdState.key == key
        )
    )
    row = result.scalar_one_or_none()
    if row is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="No state")
    return {"value": row.value, "updatedAt": row.updated_at.isoformat()}


@router.put("/{key}")
async def put_state(
    key: str,
    body: dict[str, Any],
    session: AsyncSession = Depends(get_session),
) -> dict[str, str]:
    """Записывает значение ключа целиком (последняя запись побеждает)."""
    if "value" not in body:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail="Body must contain 'value'",
        )
    user = await _demo_user(session)
    result = await session.execute(
        select(HouseholdState).where(
            HouseholdState.user_id == user.id, HouseholdState.key == key
        )
    )
    row = result.scalar_one_or_none()
    if row is None:
        row = HouseholdState(user_id=user.id, key=key, value=body["value"])
        session.add(row)
    else:
        row.value = body["value"]
    await session.flush()
    return {"status": "ok"}
