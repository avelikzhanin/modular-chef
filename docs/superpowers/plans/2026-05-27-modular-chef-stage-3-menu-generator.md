# Modular Chef — Stage 3: Menu Generator (Inline Execution)

## Context

Stage 2 дал JSON-каталоги и `CatalogService`. Stage 3 строит pipeline генерации меню: промпт для Claude API + модель WeeklyMenu + сборщик промпта + генератор + state-провайдер активного меню + подключение к `TwoWeekMenuScreen`.

## Решение по API-ключу

Claude API key **не вшиваем в APK**. Stage 3 даёт два слоя:
- **Промпт-template** (`assets/prompts/menu_generator.md`) — текстовый ресурс, который в Stage 5 потребляет FastAPI-бэкенд (где живёт настоящий вызов Anthropic SDK + ключ из `ANTHROPIC_API_KEY` env).
- **`MenuGenerator` (абстрактный)** + **`StubMenuGenerator`** (детерминированная реализация прямо на клиенте, без сети). На MVP-фазе клиент использует stub → меню «генерируется» мгновенно и работает оффлайн. Stage 5 добавит `HttpMenuGenerator`, который POST'ит запрос на бэк и возвращает уже сгенерированный JSON.

Этот подход:
- API-ключ никогда не оказывается на клиенте
- Контракт WeeklyMenu один и тот же на клиенте и сервере (отдадим `weekly_menu.dart` в общий пакет, либо дублируем в Python)
- Можно тестировать UI на телефоне без сети

## Approach

Inline-исполнение тем же циклом. После — пересборка APK.

## Files

| Создаём | Назначение |
|---------|-----------|
| `assets/prompts/menu_generator.md` | Полный Claude-промпт: контракт входа (JSON каталога+пиков), контракт выхода (JSON WeeklyMenu), правила (нет повторов 2 дня подряд, чередование вкусовых профилей, свежие овощи в начале недели) |
| `lib/models/weekly_menu.dart` | `WeeklyMenu`, `DayPlan`, `MealSlot` (breakfast/lunch/dinner), `PlannedMeal` с `fromJson`/`toJson` |
| `lib/services/prompt_builder.dart` | Чистая функция: `String build(GenerationRequest req, List<Module>, List<Pairing>, List<WeekTemplate>)` — подставляет в template |
| `lib/services/menu_generator.dart` | `abstract class MenuGenerator { Future<WeeklyMenu> generate(GenerationRequest); }` + `class StubMenuGenerator implements MenuGenerator` — детерминированный round-robin по пикам, использует pairings из каталога |
| `lib/services/active_menu.dart` | `ActiveMenu extends ChangeNotifier` — хранит текущее сгенерированное меню (`WeeklyMenu?`), статус (idle/generating/ready/error) |
| `test/models/weekly_menu_test.dart` | Round-trip JSON ↔ модели |
| `test/services/prompt_builder_test.dart` | Заметные части промпта в выходе (упоминание выбранных белков, JSON schema instruction) |
| `test/services/stub_menu_generator_test.dart` | 14 дней × 3 приёма, нет повторов 2 дня подряд в одном слоте, использует только пики |

| Модифицируем | Изменение |
|--------------|-----------|
| `lib/app.dart` | Добавить `MenuGenerator` (instance StubMenuGenerator) и `ActiveMenu` через MultiProvider |
| `lib/screens/chef/menu_screen.dart` | На «Собрать меню»: показать loader → `generator.generate(req)` → `activeMenu.set(result)` → `context.push(Routes.chefTwoWeekMenu)` |
| `lib/screens/chef/two_week_menu_screen.dart` | Читает `WeeklyMenu` из `ActiveMenu` вместо хардкода; на «Утвердить» — `SnackBar` (поведение прежнее) |

## Acceptance

1. `flutter analyze` — `No issues found!`
2. `flutter test` — все ранее зелёные (47) + новые (~12)
3. `flutter build apk --debug` — собирается
4. На телефоне:
   - В Меню выбрать ингредиенты → «Собрать меню» → 200-300 мс loader → откроется TwoWeekMenu с **именно теми** белками/гарнирами, что выбраны, по 7 дней × 3 приёма × 2 недели
   - Сменить пики → пересобрать меню → данные изменятся
   - Tap по блюду → bottom-sheet с альтернативами (как в Stage 1c) → выбрать → блюдо меняется
   - «Утвердить» → SnackBar

## Out of scope

- Реальный вызов Claude API из приложения — Stage 5 (через FastAPI)
- Подключение Today / Week / Shopping / Storage / PrepDay к ActiveMenu — Stage 4+ (после того как БД даст persistence сгенерированного меню)
- Settings-экран для ввода API key вручную (на клиенте) — нет в плане, ключ остаётся серверным
