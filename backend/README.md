# Modular Chef — Backend

FastAPI + PostgreSQL backend for the Modular Chef app.

## Stack

- **Python 3.11+**
- **FastAPI** + **uvicorn**
- **SQLAlchemy 2.0** (async) + **asyncpg**
- **Alembic** migrations
- **Claude API** (Anthropic SDK)
- **PostgreSQL 16**

## Перед началом — инструменты

На машине нужны **Python 3.11+** и **Docker Desktop** (для локального Postgres).
Если не установлены:

```powershell
# Python (через winget — самый простой путь на Windows)
winget install --id Python.Python.3.12 -e

# Docker Desktop
winget install --id Docker.DockerDesktop -e
# После установки залогиниться/перезагрузиться, чтобы команда `docker` появилась в PATH
```

Альтернативно: скачать с https://www.python.org/downloads/ и https://www.docker.com/products/docker-desktop/.

## Local setup

### 1. Postgres (Docker)

```powershell
cd D:\Desktop\modular_chef\backend
docker compose up -d
```

Поднимает Postgres 16 на `localhost:5432` (db: `modular_chef`, user/pass: `chef/chef`).

### 2. Python окружение

```powershell
cd D:\Desktop\modular_chef\backend
python -m venv .venv
.venv\Scripts\Activate.ps1
pip install -r requirements-dev.txt
```

### 3. Конфиг

```powershell
Copy-Item .env.example .env
# Открой .env, при необходимости добавь ANTHROPIC_API_KEY (для Stage 5)
```

### 4. Миграции

```powershell
alembic upgrade head
```

Создаёт все 6 таблиц.

### 5. Сидинг каталога

```powershell
python -m app.seed.seed_modules
```

Импортирует ~42 модуля из `../assets/data/modules.json` в таблицу `modules` (upsert по id, идемпотентно).

### 6. Запуск

```powershell
uvicorn app.main:app --reload
```

Открой `http://localhost:8000/health` — должен ответить `{"status":"ok"}`.
Документация Swagger: `http://localhost:8000/docs`.

## Тесты

```powershell
pytest
```

Тесты используют **SQLite-in-memory** — Postgres для них не нужен, всё работает в чистом venv.

## Структура

```
backend/
├── pyproject.toml
├── requirements*.txt
├── alembic.ini
├── docker-compose.yml
├── .env.example
├── app/
│   ├── config.py            # Settings
│   ├── db.py                # async engine + session
│   ├── main.py              # FastAPI (Stage 5 наполнит)
│   ├── models/              # SQLAlchemy: 6 таблиц
│   └── seed/
│       └── seed_modules.py  # JSON → modules
├── migrations/
│   └── versions/
│       └── 001_initial_schema.py
└── tests/
    ├── conftest.py
    ├── test_models.py       # CRUD smoke
    └── test_seed.py
```

## Что дальше — Stage 5

- Endpoints: `POST /menus/generate` (вызов Claude через `assets/prompts/menu_generator.md`), `GET /menus/active`, `POST /menus/:id/approve`, CRUD для `user_dishes` и `storage_items`
- Replace Flutter `StubMenuGenerator` → `HttpMenuGenerator` (вызывает `POST /menus/generate`)
- Deploy на Railway: `railway up` + Postgres плагин + переменные `DATABASE_URL` (авто) и `ANTHROPIC_API_KEY` (вручную)
