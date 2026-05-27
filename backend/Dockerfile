FROM python:3.12-slim AS base

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1

WORKDIR /app

# Установка системных зависимостей для asyncpg (libpq)
RUN apt-get update && apt-get install -y --no-install-recommends \
    libpq-dev gcc \
    && rm -rf /var/lib/apt/lists/*

# Сначала только requirements — кэш слоя при изменении кода
COPY backend/requirements.txt ./
RUN pip install -r requirements.txt

# Копируем сам бэк
COPY backend/ ./backend/
# И assets/prompts — нужен ClaudeClient'у (читает promp template из ../assets/prompts/)
COPY assets/ ./assets/

WORKDIR /app/backend

# Non-root user — Railway-best-practice
RUN useradd --create-home --shell /bin/bash chef && \
    chown -R chef:chef /app
USER chef

# Railway передаёт $PORT через env. Default 8000 для локального теста.
ENV PORT=8000
EXPOSE 8000

# Перед стартом — миграции. Falsly, если БД ещё не готова — пробует пока есть retries.
CMD ["sh", "-c", "alembic upgrade head && python -m app.seed.seed_modules && uvicorn app.main:app --host 0.0.0.0 --port ${PORT}"]
