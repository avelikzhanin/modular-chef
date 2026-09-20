# Modular Chef — Stage 4: PostgreSQL schema (Inline Execution)

## Context

До этого момента всё жило на клиенте (Flutter + локальный `CatalogService`). Stage 4 закладывает **бэкенд-проект** с полным набором персистентных таблиц и инструментами для локальной разработки. После Stage 4 бэкенд можно поднять локально через `docker compose up`, прогнать Alembic-миграции, засидить каталог из JSON.

Stage 4 — **архитектура и оснастка**. Stage 5 поверх этого пишет реальные FastAPI-эндпоинты + деплоит на Railway + подключает HTTP-генератор меню к клиенту.

## Where it lives

Бэкенд живёт **внутри того же репозитория** `D:\Desktop\modular_chef\backend\` (рядом с `lib/`, `assets/`). Один git-репо проще для координации schema-changes ↔ client-changes.

## Stack

- **Python 3.11+**
- **FastAPI** + **uvicorn** (Stage 5 наполнит роутами)
- **SQLAlchemy 2.0** (async) + **asyncpg** (Postgres driver)
- **Alembic** (миграции)
- **pydantic-settings** (env config)
- **python-dotenv** (локальный .env)
- **pytest** + **pytest-asyncio** + **aiosqlite** (тесты через SQLite-in-memory — не требуют Postgres в CI)

## Schema

6 таблиц, дизайн оптимизирован под нашу спеку:

| Таблица | Назначение | Ключевые поля |
|---------|-----------|---------------|
| `users` | Юзеры | `id UUID PK`, `email UNIQUE`, `display_name`, `created_at` |
| `modules` | Каталог (seeded из `modules.json`) | `id TEXT PK`, `name`, `category`, `tags JSONB`, `methods JSONB`, `storage_zone/days/tip`, `calories/prep_minutes` |
| `weekly_menus` | Сгенерированные меню юзеров | `id UUID PK`, `user_id FK`, `starts_on DATE`, `menu_json JSONB` (полный `WeeklyMenu`), `is_active BOOL` |
| `shopping_lists` | Списки покупок по неделям | `id UUID PK`, `menu_id FK`, `week_index INT`, `items_json JSONB` |
| `user_dishes` | Кастомные «Мои блюда» юзера | `id UUID PK`, `user_id FK`, `name`, `emoji`, `recipe_text`, `storage_zone/days` |
| `storage_items` | Фактическое содержимое холодильника | `id UUID PK`, `user_id FK`, `module_id` (опц.), `module_name`, `zone`, `portion_count`, `expires_at` |

Все JSON-поля — `JSONB` на Postgres, `JSON-as-text` на SQLite (через `sqlalchemy.JSON` type).

## Files

| Файл | Назначение |
|------|-----------|
| `backend/pyproject.toml` | Метаданные пакета |
| `backend/requirements.txt` | Runtime deps (pinned) |
| `backend/requirements-dev.txt` | Dev deps (pytest, ruff) |
| `backend/alembic.ini` | Alembic config |
| `backend/docker-compose.yml` | Postgres 16 для локальной разработки |
| `backend/.env.example` | Шаблон env: `DATABASE_URL`, `ANTHROPIC_API_KEY` |
| `backend/.gitignore` | Игнор `.venv/`, `.env`, `__pycache__/` |
| `backend/README.md` | Setup + run + миграции + seed |
| `backend/app/__init__.py` | Package marker |
| `backend/app/config.py` | `Settings` через pydantic-settings |
| `backend/app/db.py` | Async engine + sessionmaker + `get_session` dep |
| `backend/app/models/__init__.py` | Re-exports |
| `backend/app/models/base.py` | `Base = declarative_base()` |
| `backend/app/models/user.py` | `User` |
| `backend/app/models/module.py` | `Module` |
| `backend/app/models/weekly_menu.py` | `WeeklyMenu` |
| `backend/app/models/shopping_list.py` | `ShoppingList` |
| `backend/app/models/user_dish.py` | `UserDish` |
| `backend/app/models/storage_item.py` | `StorageItem` |
| `backend/app/seed/__init__.py` | Package marker |
| `backend/app/seed/seed_modules.py` | Грузит `../assets/data/modules.json` в `modules` (upsert по PK) |
| `backend/app/main.py` | FastAPI приложение с `/health` (Stage 5 добавит роуты) |
| `backend/migrations/env.py` | Alembic env с async metadata |
| `backend/migrations/script.py.mako` | Alembic template |
| `backend/migrations/versions/001_initial_schema.py` | Создание всех 6 таблиц |
| `backend/tests/__init__.py` | Package marker |
| `backend/tests/conftest.py` | SQLite-in-memory fixtures + auto-create tables |
| `backend/tests/test_models.py` | CRUD smoke на каждую таблицу |
| `backend/tests/test_seed.py` | Seed грузит ≥30 модулей, идемпотентен |

## Acceptance

1. **`pip install -r requirements.txt -r requirements-dev.txt`** — устанавливается без конфликтов.
2. **`pytest`** в `backend/` — все тесты зелёные (используют SQLite-in-memory, Postgres не нужен).
3. **`docker compose up -d`** в `backend/` — поднимает Postgres 16 на `localhost:5432`.
4. **`alembic upgrade head`** — создаёт все 6 таблиц в Postgres.
5. **`python -m app.seed.seed_modules`** — импортирует ≥30 модулей из `assets/data/modules.json`.
6. **`uvicorn app.main:app --reload`** — поднимает FastAPI на `localhost:8000`, `/health` отвечает `{"status":"ok"}`.
7. Flutter-клиент в этом stage **не меняется** — APK от Stage 3 актуален.

## Out of scope

- Реальные эндпоинты (генерация меню, CRUD списков) — Stage 5
- Authentication (JWT, refresh, OAuth) — заложено `users.email`, но логин пока не имплементирован
- Деплой на Railway — Stage 5 (там нужен Railway account + `ANTHROPIC_API_KEY`)
- Интеграция Flutter ↔ FastAPI — Stage 5
- Production-grade миграции (zero-downtime, индексы под нагрузкой) — за пределами MVP
