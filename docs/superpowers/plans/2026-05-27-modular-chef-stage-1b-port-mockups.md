# Modular Chef — Stage 1b: Port Stitch Mockups (Inline Execution)

## Context

Stage 1a завершён: каркас Flutter-проекта `D:\Desktop\modular_chef` с темой Clinical Ethereal, ролями и навигацией. Сейчас в шести табах/push-экранах живут placeholder'ы с текстом «Stage 1b: порт …». Stage 1b заменяет их реальными UI, переведёнными напрямую из готовых HTML-макетов Stitch.

Источник макетов (HTML + PNG): `D:\Desktop\bloom_ai_app\design_input\`.

## Approach

Inline-исполнение в этой же сессии. Все 6 экранов = вертикальный scroll-list секций, без сложного state. Мок-данные **inline в файлах экранов** (Stage 2 потом вытащит их в JSON-каталоги). Сетевые фото — через `cached_network_image` с URL'ами из HTML. Никаких тестов: визуальная проверка через web-сборку.

Стилистический slack: glassmorphism / backdrop-blur из Stitch упрощаем до полупрозрачных контейнеров без блюра — на web blur медленный и не критичен для скаффолда.

## Файлы

### Переписываем placeholder'ы
| Экран | Файл | Источник |
|-------|------|----------|
| Список покупок (Chef) | `lib/screens/chef/shopping_screen.dart` | `chef/serene_5` |
| Сегодня (Guest) | `lib/screens/guest/today_screen.dart` | `guest/v4_4` |
| Моя неделя (Guest) | `lib/screens/guest/week_screen.dart` | `guest/v4_2` |
| Запасы (Guest) | `lib/screens/guest/inventory_screen.dart` | `guest/v4_3` |

### Новые push-экраны
| Экран | Файл | Источник | Маршрут |
|-------|------|----------|---------|
| Мои блюда (Chef library) | `lib/screens/chef/my_dishes_screen.dart` | `chef/serene_4` | `/chef/my-dishes` (push из Профиля) |
| Собрать блюдо (Guest) | `lib/screens/guest/assemble_dish_screen.dart` | `guest/v4_1` | `/guest/assemble` (push из Сегодня/Запасы) |

### Расширения routing
- `lib/routing/routes.dart` — добавить `chefMyDishes`, `guestAssembleDish`.
- `lib/routing/app_router.dart` — добавить два `GoRoute` (один в каждой ветке, вне `ShellRoute` чтобы был fullscreen без bottom nav). Использовать `parentNavigatorKey` для выхода из shell.

### Триггеры push-навигации
- `lib/screens/chef/profile_screen.dart` — добавить кнопку «Мои блюда» → `context.push('/chef/my-dishes')`.
- `lib/screens/guest/today_screen.dart` — кнопка «Хочу что-то другое» в конце списка → `context.push('/guest/assemble')` (вместо просто визуальной).
- `lib/screens/guest/inventory_screen.dart` — кнопка «Собрать» во floating bar → `context.push('/guest/assemble')`.

## Acceptance

1. `flutter analyze` — `No issues found!`
2. `flutter test` — все существующие тесты (33) остаются зелёными.
3. `flutter build web --debug` — собирается без ошибок.
4. Визуально (`flutter run -d edge`):
   - 4 переписанных экрана выглядят похоже на PNG из `design_input/`
   - Кнопка «Хочу что-то другое» на Today ведёт на AssembleDish (full-screen, back-button есть)
   - Кнопка «Собрать» в Inventory ведёт туда же
   - Профиль Шефа → «Мои блюда» открывает library full-screen с back
   - Переключение ролей (`Icons.swap_horiz`) продолжает работать

## Out of scope

- Реальные модели данных и JSON-каталоги (Stage 2)
- Подключение к Claude API / FastAPI (Stages 3+5)
- 4 недостающих экрана (Stage 1c): TwoWeekMenu, BuildMenu rework, StorageMap concrete, PrepDay step 1
- Юнит-/виджет-тесты на каждый новый экран (визуальные экраны без логики — тесты дадут низкое ROI; вернёмся к ним когда появится state из Stage 2)
