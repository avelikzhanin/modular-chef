FROM python:3.12-slim AS base

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1

WORKDIR /app

# Системные зависимости для asyncpg
RUN apt-get update && apt-get install -y --no-install-recommends \
    libpq-dev gcc \
    && rm -rf /var/lib/apt/lists/*

# CACHEBUST — меняйте значение чтобы принудительно пересобрать pip слой.
# Railway BuildKit иногда не детектит изменения в requirements.txt по контенту.
ARG CACHEBUST=2026-05-28-3

COPY backend/requirements.txt ./
RUN pip install --upgrade pip && \
    pip install --upgrade --force-reinstall --no-cache-dir -r requirements.txt

# Копируем бэк и assets
COPY backend/ ./backend/
COPY assets/ ./assets/

WORKDIR /app/backend

# Non-root user
RUN useradd --create-home --shell /bin/bash chef && \
    chown -R chef:chef /app
USER chef

ENV PORT=8000
EXPOSE 8000

CMD ["sh", "-c", "alembic upgrade head && python -m app.seed.seed_modules && uvicorn app.main:app --host 0.0.0.0 --port ${PORT}"]
