# Modular Chef — Backend

FastAPI + PostgreSQL backend for the Modular Chef app.

## Stack

- **Python 3.11+**
- **FastAPI** + **uvicorn**
- **SQLAlchemy 2.0** (async) + **asyncpg**
- **Alembic** migrations
- **OpenAI** (chat.completions + JSON mode)
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
# Открой .env, добавь OPENAI_API_KEY (для Stage 5 — иначе /menus/generate отдаст 503)
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

## Stage 5 — что готово

- `POST /menus/generate` — принимает выбор пользователя, вызывает OpenAI (JSON mode), возвращает `WeeklyMenu`
- `GET /catalog/modules` — выдаёт каталог (для refresh клиента без пересборки APK)
- `GET /health` — healthcheck для Railway
- `Dockerfile` + `railway.toml` — деплой одной командой `railway up`
- Flutter `HttpMenuGenerator` (`lib/services/http_menu_generator.dart`) активируется через `--dart-define=API_BASE_URL=https://...`

### Deploy на Railway

```powershell
cd D:\Desktop\modular_chef\backend
railway link                                        # привязать к проекту в web UI
railway add --plugin postgresql                     # авто-проставит DATABASE_URL
railway variables --set OPENAI_API_KEY=sk-...       # ключ остаётся только на Railway
railway up                                          # сборка Docker + миграции + seed + uvicorn
railway domain                                      # выдаст https://...railway.app
```

Затем пересобрать APK с прод-эндпоинтом:

```powershell
cd D:\Desktop\modular_chef
flutter build apk --debug --dart-define=API_BASE_URL=https://...railway.app
```
