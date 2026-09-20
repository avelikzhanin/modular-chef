# Modular Chef — Stage 5.5: дизайн-система «Лён и глина» (Inline)

## Context

v2-спека одобрена. Выбрана палитра «Лён и глина» (§5A спеки). Stage 5.5 заменяет тему Clinical Ethereal на новую — централизованно через `AppColors` / `AppTypography` / `AppTheme`, поэтому все экраны перекрашиваются разом. Фото блюд — позже (нет кредитов image-gen), для темы они не нужны.

## Scope (что доступно без картинок)

| Файл | Изменение |
|------|-----------|
| `lib/theme/app_colors.dart` | Новая палитра: льняной фон `#EDE6DA`, глина `#AE6A4D`, эспрессо `#2E2620`, тёплые нейтрали. Имена токенов не меняем (экраны компилируются без правок). |
| `lib/theme/app_typography.dart` | Fraunces (display+headline) + Inter (остальное). Метод `applyClinicalRules` → `applyTypeRules` (чистый трансформ, без шрифта — для тестов). Шрифты применяются только в `textTheme` getter. |
| `lib/theme/app_theme.dart` | Кнопки: `StadiumBorder` → `RoundedRectangleBorder(14)` (не пилюли). FilledButtonTheme добавить. Карточки 24px, тёплые тени, nav — обновить под новые токены. Комментарии Clinical Ethereal → «Лён и глина». |
| `test/theme/app_theme_test.dart` | Новые ожидаемые hex + переименование метода. |
| Экраны (`lib/screens/**`) | Sweep: `StadiumBorder()` на кнопках → `RoundedRectangleBorder(BorderRadius.circular(14))`. Маленькие теги (`BorderRadius.circular(999)`) НЕ трогаем — pill для них ок. |

Шрифты Fraunces/Inter тянутся `google_fonts` по имени — изменений в pubspec не нужно.

## Out of scope (позже)
- Фото блюд (нужны кредиты) — Stage 8+
- Сегмент-переключатель ролей — Stage 6
- Пер-экранная полировка цветов кнопок — по мере касания экранов

## Acceptance
1. `flutter analyze` — clean
2. `flutter test` — все зелёные (тесты темы обновлены под новые значения)
3. `flutter build apk --debug` — собирается
4. Визуально: тёплый льняной фон, глиняные акценты, serif-заголовки (Fraunces), сдержанные кнопки вместо зелёных пилюль — приложение выглядит как «Лён и глина», не как старый зелёный Clinical Ethereal.
