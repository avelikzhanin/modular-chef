# Modular Chef

Мил-преп с двумя ролями (Шеф/Гость).
Спека: `D:\Desktop\bloom_ai_app\docs\superpowers\specs\2026-05-27-modular-chef-design.md`.

## Stage 1a (готово)

- Тема **Clinical Ethereal** (мягкий пистачо + пудровая база, Inter, no-line, xl радиусы)
- `RoleProvider` + `RoleSwitcher` (`Icons.swap_horiz` в AppBar)
- Bottom nav: Шеф (5 табов), Гость (3 таба) — через `go_router`
- 8 placeholder экранов (реальное содержимое — Этапы 1b/1c)

## Как запустить

В PowerShell:

```powershell
$env:Path += ';C:\Program Files\Flutter SDK\flutter\bin'
flutter pub get
flutter run -d windows   # или -d chrome / -d <emulator-id>
```

## Тесты

```powershell
flutter test
```

## Структура

```
lib/
  main.dart           # entry
  app.dart            # MaterialApp.router + theme + provider
  theme/              # AppColors, AppTypography, AppTheme
  shell/              # role, role_provider, role_switcher, chef_shell, guest_shell
  routing/            # routes constants + GoRouter builder
  screens/chef/       # placeholder экраны Шефа
  screens/guest/      # placeholder экраны Гостя
test/                 # mirror lib/
```
