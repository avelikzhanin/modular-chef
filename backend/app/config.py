"""Конфиг приложения — переменные окружения и константы."""
from pydantic import field_validator
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    """Single source of truth для всех env-зависимых параметров."""

    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        extra="ignore",
    )

    database_url: str = "postgresql+asyncpg://chef:chef@localhost:5432/modular_chef"
    openai_api_key: str = ""
    openai_model: str = "gpt-4o-mini"
    log_level: str = "INFO"

    @field_validator("database_url")
    @classmethod
    def _ensure_asyncpg_driver(cls, v: str) -> str:
        """Railway даёт DATABASE_URL вида `postgresql://...` (без явного драйвера).
        SQLAlchemy 2.0 async engine требует `postgresql+asyncpg://...`.
        Если префикс нестандартный — нормализуем.
        """
        if v.startswith("postgres://"):
            return v.replace("postgres://", "postgresql+asyncpg://", 1)
        if v.startswith("postgresql://") and "+asyncpg" not in v.split("://", 1)[0]:
            return v.replace("postgresql://", "postgresql+asyncpg://", 1)
        return v


settings = Settings()
