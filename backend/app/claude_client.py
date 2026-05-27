"""Async-клиент Claude API: грузит промпт-шаблон, отправляет каталог + запрос,
возвращает строго `WeeklyMenuSchema`. Один файл — один объект.

Источник промпта: ``../assets/prompts/menu_generator.md`` (тот же, что для Stage 3).
"""
from __future__ import annotations

import json
import logging
import re
from pathlib import Path

from anthropic import AsyncAnthropic
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.config import settings
from app.models import Module
from app.schemas import GenerationRequestSchema, WeeklyMenuSchema

logger = logging.getLogger(__name__)


def _prompt_path() -> Path:
    """assets/prompts/menu_generator.md в корне репозитория."""
    here = Path(__file__).resolve()
    project_root = here.parents[2]  # backend/app/claude_client.py → modular_chef/
    return project_root / "assets" / "prompts" / "menu_generator.md"


def _strip_json_wrapper(text: str) -> str:
    """Claude иногда оборачивает ответ в ```json … ``` даже когда просили не делать.
    Снимаем обёртку и обрезаем до первой `{` и последней `}`."""
    fence = re.search(r"```(?:json)?\s*(.+?)\s*```", text, flags=re.DOTALL)
    candidate = fence.group(1) if fence else text
    first = candidate.find("{")
    last = candidate.rfind("}")
    if first == -1 or last == -1:
        return candidate
    return candidate[first : last + 1]


def parse_claude_response(raw: str) -> WeeklyMenuSchema:
    """Pure-функция парсинга. Тестируется напрямую без сетевых вызовов."""
    cleaned = _strip_json_wrapper(raw)
    data = json.loads(cleaned)
    return WeeklyMenuSchema.model_validate(data)


class ClaudeClient:
    """Async обёртка над Anthropic SDK с промпт-template'ом и парсингом."""

    def __init__(
        self,
        api_key: str | None = None,
        model: str | None = None,
        prompt_path: Path | None = None,
    ) -> None:
        key = api_key or settings.anthropic_api_key
        if not key:
            raise RuntimeError(
                "ANTHROPIC_API_KEY не задан. Проставьте env-переменную."
            )
        self._client = AsyncAnthropic(api_key=key)
        self._model = model or settings.claude_model
        self._prompt_path = prompt_path or _prompt_path()
        self._template: str | None = None  # lazy

    async def _template_text(self) -> str:
        if self._template is None:
            self._template = self._prompt_path.read_text(encoding="utf-8")
        return self._template

    async def _build_payload(
        self,
        request: GenerationRequestSchema,
        session: AsyncSession,
    ) -> dict:
        """Готовит JSON, который пойдёт в промпт: запрос + каталог из БД."""
        modules_result = await session.execute(select(Module))
        modules = modules_result.scalars().all()
        return {
            **request.model_dump(),
            "catalog": {
                "modules": [
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
                ],
                # pairings/templates Stage 5 берёт пустыми — Claude справляется
                # с моделями без них; добавим когда понадобится более узкий
                # руководствуемый стиль.
                "pairings": [],
                "templates": [],
            },
        }

    async def generate(
        self,
        request: GenerationRequestSchema,
        session: AsyncSession,
    ) -> WeeklyMenuSchema:
        """Главный метод: запрос → промпт → Claude → распарсенный WeeklyMenu."""
        template = await self._template_text()
        payload = await self._build_payload(request, session)
        full_prompt = (
            f"{template}\n\n## Текущий запрос\n\n```json\n"
            f"{json.dumps(payload, ensure_ascii=False, indent=2)}\n```\n"
        )

        logger.info(
            "Calling Claude model=%s with %d modules in catalog",
            self._model,
            len(payload["catalog"]["modules"]),
        )

        message = await self._client.messages.create(
            model=self._model,
            max_tokens=8000,
            messages=[{"role": "user", "content": full_prompt}],
        )

        # Anthropic SDK 0.42: message.content — список TextBlock'ов
        parts = [
            block.text for block in message.content if getattr(block, "type", "") == "text"
        ]
        raw_text = "".join(parts).strip()
        logger.debug("Claude returned %d chars", len(raw_text))

        return parse_claude_response(raw_text)
