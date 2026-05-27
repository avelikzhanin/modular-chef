"""POST /menus/generate — генерация меню через Claude."""
import logging

from fastapi import APIRouter, Depends, HTTPException, Request, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.claude_client import ClaudeClient
from app.db import get_session
from app.schemas import GenerationRequestSchema, WeeklyMenuSchema

logger = logging.getLogger(__name__)
router = APIRouter(prefix="/menus", tags=["menus"])


def get_claude_client(request: Request) -> ClaudeClient:
    """Берём общий ClaudeClient из app.state — он создаётся при старте main.py.
    Это позволяет переопределить клиент в тестах через dependency_overrides.
    """
    client: ClaudeClient | None = getattr(request.app.state, "claude_client", None)
    if client is None:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="Claude client is not configured (ANTHROPIC_API_KEY missing).",
        )
    return client


@router.post("/generate", response_model=WeeklyMenuSchema)
async def generate_menu(
    request_body: GenerationRequestSchema,
    session: AsyncSession = Depends(get_session),
    client: ClaudeClient = Depends(get_claude_client),
) -> WeeklyMenuSchema:
    """Принимает выбор пользователя, возвращает 14-дневное меню от Claude.

    Stage 5 не сохраняет результат в БД — клиент пока держит меню в ActiveMenu.
    Future stage добавит persistence в `weekly_menus`.
    """
    try:
        return await client.generate(request_body, session)
    except Exception as e:  # noqa: BLE001
        logger.exception("Menu generation failed")
        raise HTTPException(
            status_code=status.HTTP_502_BAD_GATEWAY,
            detail=f"Claude API error: {e}",
        ) from e
