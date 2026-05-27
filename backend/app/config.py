"""Конфиг приложения — переменные окружения и константы."""
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    """Single source of truth для всех env-зависимых параметров."""

    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        extra="ignore",
    )

    database_url: str = "postgresql+asyncpg://chef:chef@localhost:5432/modular_chef"
    anthropic_api_key: str = ""
    claude_model: str = "claude-sonnet-4-6"
    log_level: str = "INFO"


settings = Settings()
