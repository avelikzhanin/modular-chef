# Modular Chef — Stage 5: FastAPI endpoints + Railway deploy (Inline)

## Context

Stage 4 заложил БД-фундамент: модели, миграции, seed. Stage 5 наполняет бэкенд **реальной логикой**, деплоит на Railway, заменяет клиентский `StubMenuGenerator` на `HttpMenuGenerator`, который ходит на прод.

## Архитектура

```
Flutter (APK)
  └─ HttpMenuGenerator (через dio)
       └─ HTTPS POST → Railway app
            └─ FastAPI endpoint
                 └─ OpenAI SDK (chat.completions, JSON mode) ←─ OPENAI_API_KEY (env)
                 └─ asyncpg → Postgres (Railway plugin)
```

API key хранится **только на Railway env**, никогда не уезжает в APK.

## Backend endpoints (Stage 5)

| Endpoint | Назначение | Status |
|----------|-----------|--------|
| `GET /health` | Healthcheck для Railway | ✅ (готов в Stage 4) |
| `POST /menus/generate` | Принимает `GenerationRequest` (JSON), зовёт Claude через промпт, возвращает `WeeklyMenu` | новое |
| `GET /catalog/modules` | Возвращает модули (клиенту опц. для refresh) | новое |

Авторизация — на этом этапе **без auth**, в эндпоинт передаётся `user_id` (опц.) для будущего сохранения меню. Auth — отдельный stage потом.

## Файлы — Backend

| Создаём | Назначение |
|---------|-----------|
| `backend/Dockerfile` | Multi-stage Python 3.12 slim, не root, `uvicorn` на `$PORT` |
| `backend/railway.toml` | Railway build/start конфиг |
| `backend/app/llm_client.py` | Async обёртка: читает промпт + payload, вызывает OpenAI (JSON mode), парсит JSON |
| `backend/app/schemas/__init__.py` | Pydantic в одном файле |
| `backend/app/schemas/menu.py` | `GenerationRequestSchema`, `PlannedMealSchema`, `DayPlanSchema`, `MenuWeekSchema`, `WeeklyMenuSchema`, `MenuSummarySchema` — зеркало Dart-моделей |
| `backend/app/routers/__init__.py` | Package marker |
| `backend/app/routers/menus.py` | `POST /menus/generate` |
| `backend/app/routers/catalog.py` | `GET /catalog/modules` |
| `backend/tests/test_llm_client.py` | Парсинг ответа LLM (фикстура JSON, без реального вызова) |
| `backend/tests/test_routers.py` | TestClient + DI override для `LlmClient` (mock) |

| Модифицируем | Изменение |
|--------------|-----------|
| `backend/app/main.py` | Подключить роутеры `menus` и `catalog`, CORS middleware |
| `backend/requirements.txt` | (уже есть `anthropic==0.42.0`) |

## Файлы — Flutter client

| Создаём | Назначение |
|---------|-----------|
| `lib/services/http_menu_generator.dart` | `HttpMenuGenerator implements MenuGenerator` — POST через `dio`, парсит `WeeklyMenu.fromJson` |
| `lib/config/api_config.dart` | `String apiBaseUrl` через `String.fromEnvironment('API_BASE_URL', defaultValue: '...')` |
| `test/services/http_menu_generator_test.dart` | DioAdapter mock — проверяет request body и response parsing |

| Модифицируем | Изменение |
|--------------|-----------|
| `pubspec.yaml` | Добавить `dio: ^5.7.0` |
| `lib/app.dart` | По умолчанию использовать `HttpMenuGenerator`, fallback на `StubMenuGenerator` если `apiBaseUrl.isEmpty` |

## Deploy steps (после готовности кода)

1. **Railway project + Postgres плагин**
   ```powershell
   cd D:\Desktop\modular_chef\backend
   railway add --plugin postgresql  # авто-проставит DATABASE_URL
   ```

2. **OPENAI_API_KEY**
   ```powershell
   railway variables --set OPENAI_API_KEY=sk-ant-...
   ```
   (вы вводите вручную; ключ в логи не уходит)

3. **Деплой**
   ```powershell
   railway up
   ```
   Railway собирает Dockerfile, запускает миграции (через `railway run alembic upgrade head`), затем `uvicorn`.

4. **Получить URL и пересобрать APK**
   ```powershell
   railway domain  # выдаст https://modular-chef-production.up.railway.app
   cd D:\Desktop\modular_chef
   flutter build apk --debug --dart-define=API_BASE_URL=https://modular-chef-production.up.railway.app
   ```

## Acceptance

1. `pytest` в `backend/` — ≥18 зелёных (новые: claude client + endpoint smoke)
2. `flutter analyze` — clean; `flutter test` — все зелёные
3. Railway deploy успешен; `curl https://<url>/health` → `{"status":"ok"}`
4. На телефоне с APK (`API_BASE_URL=https://...`) → выбрать пики → «Собрать меню» → реальное меню от Claude через 3-10 секунд
5. Если API_BASE_URL пустой (`flutter build apk --debug` без `--dart-define`) → старый stub fallback продолжает работать

## Out of scope

- Auth (JWT, OAuth, refresh) — отдельный future stage
- Сохранение сгенерированного меню в БД per-user — следующий stage (для этого уже есть таблица `weekly_menus`)
- Real-time WebSocket — не нужно
- Rate limiting / Anthropic budget guard — будет если апа станет популярной
