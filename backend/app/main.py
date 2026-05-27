"""FastAPI приложение: роутеры + CORS + LLM client startup."""
import logging
from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.config import settings
from app.llm_client import LlmClient
from app.routers import catalog, menus

logger = logging.getLogger(__name__)


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Создаём LlmClient на старте (если ключ есть).

    Любая ошибка инициализации LLM-клиента (например, версионный конфликт
    openai/httpx) не должна валить весь startup — иначе healthcheck падает
    и Railway не может определить service как готовый. Логируем и оставляем
    `llm_client=None`; роут `/menus/generate` сам вернёт 503.
    """
    logging.basicConfig(level=settings.log_level)
    app.state.llm_client = None
    if settings.openai_api_key:
        try:
            app.state.llm_client = LlmClient()
            logger.info("LLM client ready (model=%s)", settings.openai_model)
        except Exception as e:  # noqa: BLE001
            logger.exception("Failed to init LLM client: %s", e)
    else:
        logger.warning(
            "OPENAI_API_KEY не задан — /menus/generate вернёт 503."
        )
    yield
    app.state.llm_client = None


app = FastAPI(
    title="Modular Chef API",
    version="0.1.0",
    description="Backend для мил-преп приложения с двумя ролями (Шеф/Гость).",
    lifespan=lifespan,
)

# CORS — Flutter web и mobile клиенты ходят с разных origin'ов.
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(menus.router)
app.include_router(catalog.router)


@app.get("/health")
async def health() -> dict[str, str]:
    """Лёгкий probe для Railway healthcheck."""
    return {"status": "ok"}
