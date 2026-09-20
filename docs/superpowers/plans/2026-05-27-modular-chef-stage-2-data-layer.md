# Modular Chef — Stage 2: Data Layer (Inline Execution)

## Context

Stages 1a/1b/1c построили UI с inline-мок-данными в каждом экране. Stage 2 заменяет эту разрозненную статику на единые JSON-каталоги в `assets/data/`, типизированные модели в `lib/models/`, и `CatalogService` (ChangeNotifier через provider), который загружает каталоги из `rootBundle` при старте приложения. Это фундамент для Stage 3 (промпт Claude API): генератор меню принимает на вход именно эти JSON-каталоги.

## Approach

Inline-исполнение тем же циклом. После Stage 2 пересобираем APK для проверки на телефоне.

## Scope

**4 JSON-каталога в `assets/data/`:**
- `modules.json` — ~40 модулей (белки/гарниры/супы/завтраки/овощи/соусы). Спек просил 100–150; для MVP кладём 40 качественно сделанных, расширим в Stage 3+.
- `pairings.json` — ~25 троек белок+гарнир+соус с вкусовыми тегами.
- `week_templates.json` — 4 шаблона недель (средиземноморская / азиатская / русская классика / микс).
- `storage_rules.json` — правила хранения по zone+days+tip для ключевых модулей.

**4 модели в `lib/models/`** (по одному файлу на модель, immutable, `fromJson` factory):
- `module.dart` — `Module` + enum `ModuleCategory`
- `storage.dart` — enum `StorageZone` + helper labels
- `pairing.dart` — `Pairing`
- `week_template.dart` — `WeekTemplate`
- `storage_rule.dart` — `StorageRule`

**Сервис `lib/services/catalog_service.dart`** — `ChangeNotifier`:
- `Future<void> load()` — параллельная загрузка 4 JSON через `rootBundle`
- Хелперы: `modulesByCategory(...)`, `moduleById(...)`, `storageRulesForModule(...)`, `templates()`
- Состояние: `isLoaded`, `loadError`

**Wire-up в `lib/app.dart`** — провайдер `CatalogService` загружается на старте; `MaterialApp.router` остаётся как есть.

**Подключение к двум экранам:**
- `MenuScreen` (BuildMenu) — секции «Белки/Гарниры/Супы/Завтраки» теперь из каталога. Если каталог не загружен — `CircularProgressIndicator`.
- `InventoryScreen` (Guest) — модули из каталога вместо хардкода. Здесь же показываем `count` (мок на этом этапе — рандом 2–4 от длины hash имени).

**Остальные экраны** (Today / Week / Shopping / TwoWeekMenu / Storage / PrepDay / MyDishes / AssembleDish) остаются на inline-мок до Stage 3 — там Claude generator вернёт `WeeklyMenu` JSON, и эти экраны получат реальные данные единым махом.

## Tests

- `test/services/catalog_service_test.dart` — реальная загрузка всех 4 JSON через `TestWidgetsFlutterBinding`, проверки counts и lookups (proteins ≥ 5, byId работает, storageRulesForModule).
- `test/models/module_test.dart` — round-trip JSON ↔ Module для одного сэмпла каждой категории.

Никаких widget-тестов на новые UI-консумеры (визуальная проверка через APK).

## Acceptance

1. `flutter analyze` — `No issues found!`
2. `flutter test` — все ранее зелёные тесты + новые (33 + ~10).
3. `flutter build apk --debug` — собирается.
4. Визуально на телефоне:
   - **MenuScreen** показывает белки/гарниры/супы/завтраки из каталога (~6+ карточек в первых секциях)
   - **InventoryScreen** показывает модули из каталога с count-бейджами

## Files

| Создаём | Назначение |
|---------|-----------|
| `assets/data/modules.json` | Каталог модулей |
| `assets/data/pairings.json` | Матрица сочетаемости |
| `assets/data/week_templates.json` | Вкусовые шаблоны недель |
| `assets/data/storage_rules.json` | Правила хранения |
| `lib/models/module.dart` | `Module` + `ModuleCategory` |
| `lib/models/storage.dart` | `StorageZone` enum + labels |
| `lib/models/pairing.dart` | `Pairing` |
| `lib/models/week_template.dart` | `WeekTemplate` |
| `lib/models/storage_rule.dart` | `StorageRule` |
| `lib/services/catalog_service.dart` | `ChangeNotifier` загрузчик |
| `test/services/catalog_service_test.dart` | Sanity на загрузку |
| `test/models/module_test.dart` | Round-trip JSON ↔ Module |

| Модифицируем | Изменение |
|--------------|-----------|
| `lib/app.dart` | Регистрируем `CatalogService` через `MultiProvider`, грузим на старте |
| `lib/screens/chef/menu_screen.dart` | Секции из `CatalogService.modulesByCategory(...)`, loader при `!isLoaded` |
| `lib/screens/guest/inventory_screen.dart` | Модули из каталога; групповая структура по `ModuleCategory` |

## Out of scope

- Полноразмерный каталог 100–150 модулей — Stage 3+ (по мере появления реальных рецептов)
- Сохранение пользовательских custom-модулей в storage — будет в Stage 4 (БД)
- Подключение остальных 8 экранов к реальным данным — Stage 3 (когда Claude генератор вернёт WeeklyMenu)
