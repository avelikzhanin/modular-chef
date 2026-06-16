"""Меню: генерация (LLM) + сохранение/загрузка активного меню (БД)."""
import logging

from fastapi import APIRouter, Depends, HTTPException, Request, status
from sqlalchemy import select, update
from sqlalchemy.ext.asyncio import AsyncSession

from app.db import get_session
from app.llm_client import LlmClient
from app.models import User, WeeklyMenu
from app.schemas import GenerationRequestSchema, WeeklyMenuSchema

logger = logging.getLogger(__name__)
router = APIRouter(prefix="/menus", tags=["menus"])

# Пока без авторизации — один демо-пользователь. Auth добавим отдельным stage.
_DEMO_EMAIL = "demo@modularchef.local"


async def _demo_user(session: AsyncSession) -> User:
    """Возвращает (создаёт при необходимости) демо-пользователя."""
    result = await session.execute(select(User).where(User.email == _DEMO_EMAIL))
    user = result.scalar_one_or_none()
    if user is None:
        user = User(email=_DEMO_EMAIL, display_name="Demo")
        session.add(user)
        await session.flush()
    return user


def get_llm_client(request: Request) -> LlmClient:
    """Берём общий LlmClient из app.state — он создаётся при старте main.py.
    Это позволяет переопределить клиент в тестах через dependency_overrides.
    """
    client: LlmClient | None = getattr(request.app.state, "llm_client", None)
    if client is None:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="LLM client is not configured (OPENAI_API_KEY missing).",
        )
    return client


@router.post("/generate", response_model=WeeklyMenuSchema)
async def generate_menu(
    request_body: GenerationRequestSchema,
    session: AsyncSession = Depends(get_session),
    client: LlmClient = Depends(get_llm_client),
) -> WeeklyMenuSchema:
    """Принимает выбор пользователя, возвращает 14-дневное меню от LLM.

    Stage 5 не сохраняет результат в БД — клиент держит меню в ActiveMenu.
    Future stage добавит persistence в `weekly_menus`.
    """
    try:
        return await client.generate(request_body, session)
    except Exception as e:  # noqa: BLE001
        logger.exception("Menu generation failed")
        raise HTTPException(
            status_code=status.HTTP_502_BAD_GATEWAY,
            detail=f"LLM API error: {e}",
        ) from e


@router.post("/save")
async def save_menu(
    menu: WeeklyMenuSchema,
    session: AsyncSession = Depends(get_session),
) -> dict[str, str]:
    """Сохраняет меню как активное для демо-пользователя (деактивируя прежние)."""
    user = await _demo_user(session)
    await session.execute(
        update(WeeklyMenu)
        .where(WeeklyMenu.user_id == user.id, WeeklyMenu.is_active.is_(True))
        .values(is_active=False)
    )
    row = WeeklyMenu(
        user_id=user.id,
        menu_json=menu.model_dump(),
        is_active=True,
    )
    session.add(row)
    await session.flush()
    return {"id": str(row.id)}


@router.get("/active", response_model=WeeklyMenuSchema)
async def active_menu(
    session: AsyncSession = Depends(get_session),
) -> WeeklyMenuSchema:
    """Возвращает активное меню демо-пользователя или 404, если его нет."""
    user = await _demo_user(session)
    result = await session.execute(
        select(WeeklyMenu)
        .where(WeeklyMenu.user_id == user.id, WeeklyMenu.is_active.is_(True))
        .order_by(WeeklyMenu.generated_at.desc())
        .limit(1)
    )
    row = result.scalar_one_or_none()
    if row is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="No active menu")
    return WeeklyMenuSchema.model_validate(row.menu_json)
