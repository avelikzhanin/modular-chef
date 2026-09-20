# Modular Chef — Stage 1c: 4 Missing Screens (Inline Execution)

## Context

Stage 1a (скаффолд + тема + навигация) и Stage 1b (6 готовых макетов Stitch) сделаны. Сейчас в табах Шефа живут:
- **Меню** — `serene_1` placeholder с пометкой Stage 1b/1c (нужно переделать с горизонтальным скроллом + новый под-экран «Меню на 2 недели»)
- **Подготовка** — placeholder; в Stitch есть `serene_2` шаг 2 (термообработка), но **нет шага 1** (выбор способа на белок)
- **Хранение** — placeholder; в Stitch есть `serene_3` с абстрактными зонами, нужно переделать в конкретные позиции с днями

Также критически отсутствует экран «Меню на 2 недели» (14 дней × 3 приёма) — без него флоу Шефа разорван.

## Approach

Inline-исполнение, тем же циклом. Каждый экран = вертикальный scroll с inline мок-данными (Stage 2 потом вытащит в JSON). Никаких новых зависимостей.

## Файлы

### Переписываем placeholder'ы
| Экран | Файл | Источник |
|-------|------|----------|
| Собери своё меню (Chef) | `lib/screens/chef/menu_screen.dart` | `chef/serene_1` + горизонтальные карточки + `+ Своё` + кнопка «Собрать меню» |
| День заготовки (Chef) | `lib/screens/chef/prep_screen.dart` | `chef/serene_2` + новый Step 1 (выбор способа на белок) — единый stateful с переключением шагов |
| Карта хранения (Chef) | `lib/screens/chef/storage_screen.dart` | `chef/serene_3` + конкретные позиции (курица п.1–3 → пн-ср, лосось → вакуум до чт) |

### Новый push-экран
| Экран | Файл | Маршрут |
|-------|------|---------|
| Меню на 2 недели (Chef) | `lib/screens/chef/two_week_menu_screen.dart` | `/chef/two-week-menu` (push из MenuScreen после «Собрать меню») |

### Routing
- `lib/routing/routes.dart` — добавить `chefTwoWeekMenu`
- `lib/routing/app_router.dart` — добавить `GoRoute` через `parentNavigatorKey: _rootNavigatorKey`

## Acceptance

1. `flutter analyze` — `No issues found!` (после `dart fix --apply` для prefer_const)
2. `flutter test` — все существующие 33 теста зелёные
3. `flutter build web --debug` — собирается без ошибок
4. Визуально:
   - **MenuScreen**: 5 секций (Белки/Гарниры/Супы/Завтраки/Мои блюда), в каждой horizontal scroll с 6+ карточек + плитка `+ Своё`, чекмарки на выбранных. Внизу sticky CTA «Собрать меню».
   - **TwoWeekMenuScreen**: тогл «Неделя 1 / Неделя 2», 7 дней × 3 приёма каждый, бейдж «15 блюд из 6 модулей», на каждом блюде swipe→replace (минимально — long-press menu), снизу CTA «Утвердить».
   - **StorageScreen**: 3 зоны (Холодильник 🟩 / Морозилка 🟦 / Вакуум 🟣), в каждой конкретные строки типа «Курица порции 1–3 → пн-ср» с пояснениями.
   - **PrepDayScreen**: Step 1 (чипы способа для каждого белка) → «Продолжить» → Step 2 (таймлайн процессов, как в serene_2). Шаги переключаются внутри одного экрана.

## Out of scope

- Реальная логика генерации меню (Stage 3) — пока статичный мок 14 дней
- Drag-n-drop swipe-to-replace — заменим на простое tap-to-replace в long-press menu (минимальный viable interaction)
- Сохранение выбора (что выбрано в Step 1 PrepDay) — локальный state, без persistence
- Тесты на новые экраны — визуальные экраны без логики

## Phone delivery (после)

После Stage 1c — два варианта посмотреть на телефоне:
1. **Web через локальную сеть**: `flutter run -d edge --web-port 8080 --web-hostname 0.0.0.0` → открыть `http://<ip-компа>:8080` в браузере телефона на одном wifi
2. **Android APK**: `flutter build apk --debug` (если установлен Android toolchain) → перенести `build/app/outputs/flutter-apk/app-debug.apk` на телефон и установить
