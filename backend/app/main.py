"""FastAPI приложение: роутеры + CORS + Claude client startup."""
import logging
from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.claude_client import ClaudeClient
from app.config import settings
from app.routers import catalog, menus

logger = logging.getLogger(__name__)


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Создаём ClaudeClient на старте (если ключ есть)."""
    logging.basicConfig(level=settings.log_level)
    if settings.anthropic_api_key:
        app.state.claude_client = ClaudeClient()
        logger.info("Claude client ready (model=%s)", settings.claude_model)
    else:
        app.state.claude_client = None
        logger.warning(
            "ANTHROPIC_API_KEY не задан — /menus/generate вернёт 503."
        )
    yield
    app.state.claude_client = None


app = FastAPI(
    title="Modular Chef API",
    version="0.1.0",
    description="Backend для мил-преп приложения с двумя ролями (Шеф/Гость).",
    lifespan=lifespan,
)

# CORS — Flutter web и mobile клиенты ходят с разных origin'ов.
# Production: можно сузить до конкретных доменов.
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
