# Modular Chef — Stage 1a Scaffold Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Создать новый Flutter-проект `modular_chef` с темой Clinical Ethereal, двумя ролями (Шеф/Гость), нижней навигацией под каждую роль и переключателем ролей в шапке — готовый каркас, в который на этапах 1b/1c встанут реальные экраны.

**Architecture:** Single Flutter app. Тема — фабрика `ThemeData` на основе `ColorScheme.fromSeed` + ручные оверрайды цветов/тонов/шрифтов из стайл-гайда Clinical Ethereal. Навигация — `go_router` с двумя параллельными `StatefulShellRoute.indexedStack` ветками (одна на Шефа, одна на Гостя). Активная роль хранится в `RoleProvider` (`ChangeNotifier`); смена роли вызывает редирект на корневой маршрут соответствующей ветки.

**Tech Stack:** Flutter 3.41 / Dart 3.11, `go_router ^14`, `provider ^6`, `google_fonts ^6`, `cached_network_image ^3`, `flutter_svg ^2`. Тестирование — `flutter_test` (unit + widget).

**Контекст по окружению:**
- Flutter SDK: `C:\Program Files\Flutter SDK\flutter\bin\flutter.bat` (НЕ в системном PATH).
- Целевой каталог проекта: `D:\Desktop\modular_chef` (НЕ существует — создаём).
- Платформа: Windows 11, PowerShell. Все команды — PowerShell-совместимые.
- Спека: `D:\Desktop\bloom_ai_app\docs\superpowers\specs\2026-05-27-modular-chef-design.md`.
- Дизайн-референсы (HTML/PNG от Stitch): `D:\Desktop\bloom_ai_app\design_input\`.

**Открытое решение, принятое в этом плане:** переключатель ролей живёт в `AppBar` справа — `IconButton(Icons.swap_horiz)` с tooltip «Стать Гостем / Стать Шефом». Один тап = мгновенная смена роли + редирект на корневой таб новой роли.

---

## File Structure (создаются в этом плане)

```
D:\Desktop\modular_chef\
├── pubspec.yaml                  # зависимости + assets
├── .gitignore                    # из flutter create
├── README.md                     # инструкция запуска (Task 12)
├── lib\
│   ├── main.dart                 # runApp + Provider scope
│   ├── app.dart                  # MaterialApp.router + theme
│   ├── theme\
│   │   ├── app_colors.dart       # палитра Clinical Ethereal
│   │   ├── app_typography.dart   # Inter через google_fonts
│   │   └── app_theme.dart        # ThemeData фабрика
│   ├── shell\
│   │   ├── role.dart             # enum UserRole {chef, guest}
│   │   ├── role_provider.dart    # ChangeNotifier
│   │   ├── role_switcher.dart    # AppBar IconButton + AppBar фабрика
│   │   ├── chef_shell.dart       # NavigationBar 5 табов
│   │   └── guest_shell.dart      # NavigationBar 3 таба
│   ├── routing\
│   │   ├── routes.dart           # константы путей
│   │   └── app_router.dart       # GoRouter с двумя ветками
│   └── screens\
│       ├── chef\
│       │   ├── menu_screen.dart
│       │   ├── shopping_screen.dart
│       │   ├── prep_screen.dart
│       │   ├── storage_screen.dart
│       │   └── profile_screen.dart
│       └── guest\
│           ├── today_screen.dart
│           ├── week_screen.dart
│           └── inventory_screen.dart
└── test\
    ├── shell\
    │   ├── role_provider_test.dart
    │   ├── chef_shell_test.dart
    │   └── guest_shell_test.dart
    ├── theme\
    │   └── app_theme_test.dart
    └── routing\
        └── app_router_test.dart
```

---

## Task 1: Bootstrap Flutter project + git

**Files:**
- Create: `D:\Desktop\modular_chef\` (через `flutter create`)

- [ ] **Step 1: Verify Flutter is callable**

Run (PowerShell):

```powershell
$env:Path += ';C:\Program Files\Flutter SDK\flutter\bin'
flutter --version
```

Expected: prints `Flutter 3.41.5 ... Dart 3.11.3`. **Запомните этот `$env:Path` патч — используйте его в каждом новом PowerShell-окне до завершения Stage 1a.**

- [ ] **Step 2: Verify target dir does not exist**

```powershell
if (Test-Path 'D:\Desktop\modular_chef') { Write-Output 'EXISTS' } else { Write-Output 'OK-MISSING' }
```

Expected: `OK-MISSING`. Если `EXISTS` — остановиться и спросить пользователя.

- [ ] **Step 3: Create project**

```powershell
Set-Location 'D:\Desktop'
flutter create --org com.modularchef --project-name modular_chef --platforms=windows,android,ios,web modular_chef
```

Expected: `All done!` и появляется папка `modular_chef`.

- [ ] **Step 4: Init git, ignore build artefacts, first commit**

```powershell
Set-Location 'D:\Desktop\modular_chef'
git init -b main
git add .
git commit -m "chore: flutter create scaffold"
```

Expected: первый коммит с дефолтным каркасом. `.gitignore` от Flutter уже исключает `build/`, `.dart_tool/`, `.flutter-plugins*`.

- [ ] **Step 5: Smoke-build**

```powershell
flutter pub get
flutter analyze
```

Expected: `No issues found!`. Если есть варнинги — игнорировать; ошибки — остановиться.

---

## Task 2: Add dependencies

**Files:**
- Modify: `D:\Desktop\modular_chef\pubspec.yaml`

- [ ] **Step 1: Replace pubspec.yaml**

Полностью заменить содержимое `pubspec.yaml` на:

```yaml
name: modular_chef
description: Modular Chef — мил-преп с двумя ролями (Шеф и Гость).
publish_to: 'none'
version: 0.1.0+1

environment:
  sdk: '>=3.5.0 <4.0.0'

dependencies:
  flutter:
    sdk: flutter
  cupertino_icons: ^1.0.6

  # Navigation
  go_router: ^14.0.0

  # State management
  provider: ^6.1.0

  # Typography (Inter via Google Fonts)
  google_fonts: ^6.1.0

  # Images
  cached_network_image: ^3.3.1

  # SVG icons
  flutter_svg: ^2.0.9

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^4.0.0

flutter:
  uses-material-design: true
  assets:
    - assets/data/
    - assets/images/
```

- [ ] **Step 2: Create empty asset dirs (чтобы pub не ругался)**

```powershell
New-Item -ItemType Directory -Path 'D:\Desktop\modular_chef\assets\data' -Force | Out-Null
New-Item -ItemType Directory -Path 'D:\Desktop\modular_chef\assets\images' -Force | Out-Null
New-Item -ItemType File -Path 'D:\Desktop\modular_chef\assets\data\.gitkeep' -Force | Out-Null
New-Item -ItemType File -Path 'D:\Desktop\modular_chef\assets\images\.gitkeep' -Force | Out-Null
```

- [ ] **Step 3: Resolve and verify**

```powershell
flutter pub get
flutter analyze
```

Expected: `Got dependencies!` + `No issues found!`.

- [ ] **Step 4: Commit**

```powershell
git add pubspec.yaml pubspec.lock assets
git commit -m "feat: add core dependencies (go_router, provider, google_fonts)"
```

---

## Task 3: Color palette (Clinical Ethereal)

**Files:**
- Create: `D:\Desktop\modular_chef\lib\theme\app_colors.dart`

- [ ] **Step 1: Write the failing test**

Create `D:\Desktop\modular_chef\test\theme\app_theme_test.dart` (мы будем дополнять этот файл; сейчас — секция про цвета):

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:modular_chef/theme/app_colors.dart';

void main() {
  group('AppColors', () {
    test('primary is the muted pistachio from spec', () {
      expect(AppColors.primary, const Color(0xFF49655A));
    });

    test('primary container is the soft pistachio', () {
      expect(AppColors.primaryContainer, const Color(0xFFCBE9DC));
    });

    test('surface base is the cool off-white', () {
      expect(AppColors.surface, const Color(0xFFF8F9FB));
    });

    test('surface lowest is pure white for floating cards', () {
      expect(AppColors.surfaceContainerLowest, const Color(0xFFFFFFFF));
    });

    test('secondary container is the powdery terracotta', () {
      expect(AppColors.secondaryContainer, const Color(0xFFF0DEDE));
    });

    test('tertiary container is the soft pink', () {
      expect(AppColors.tertiaryContainer, const Color(0xFFFDE5EC));
    });

    test('on-surface variant is the warm body grey', () {
      expect(AppColors.onSurfaceVariant, const Color(0xFF596064));
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

```powershell
flutter test test\theme\app_theme_test.dart
```

Expected: FAIL — `Target of URI doesn't exist: 'package:modular_chef/theme/app_colors.dart'`.

- [ ] **Step 3: Create AppColors**

Create `D:\Desktop\modular_chef\lib\theme\app_colors.dart`:

```dart
import 'package:flutter/material.dart';

/// Палитра дизайн-системы Clinical Ethereal.
/// Источник: design_input/.../serene_purity/DESIGN.md
abstract final class AppColors {
  // Surfaces — три тональных слоя (база, фон секций, плавающие карточки)
  static const Color surface = Color(0xFFF8F9FB);
  static const Color surfaceContainerLow = Color(0xFFF0F4F7);
  static const Color surfaceContainer = Color(0xFFEAEEF2);
  static const Color surfaceContainerHigh = Color(0xFFE3E8EC);
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);

  // Primary — мягкий пистачо
  static const Color primary = Color(0xFF49655A);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color primaryContainer = Color(0xFFCBE9DC);
  static const Color onPrimaryContainer = Color(0xFF3C574D);

  // Secondary — пудровая терракота
  static const Color secondary = Color(0xFF8A5D5D);
  static const Color onSecondary = Color(0xFFFFFFFF);
  static const Color secondaryContainer = Color(0xFFF0DEDE);
  static const Color onSecondaryContainer = Color(0xFF553535);

  // Tertiary — софт-розовый для chips
  static const Color tertiary = Color(0xFFA34F6B);
  static const Color onTertiary = Color(0xFFFFFFFF);
  static const Color tertiaryContainer = Color(0xFFFDE5EC);
  static const Color onTertiaryContainer = Color(0xFF5A2C3C);

  // Текст
  static const Color onSurface = Color(0xFF2C3337);
  static const Color onSurfaceVariant = Color(0xFF596064);

  // Outline — используется только в "ghost" виде (15% opacity)
  static const Color outlineVariant = Color(0xFFC4CACD);

  // Sanctuary shadow — тинтованный, никогда не pure black
  static const Color shadowTint = Color(0x0A2C3337); // ≈ rgba(44,51,55,0.04)
}
```

- [ ] **Step 4: Run test to verify it passes**

```powershell
flutter test test\theme\app_theme_test.dart
```

Expected: PASS — 7 tests passed.

- [ ] **Step 5: Commit**

```powershell
git add lib\theme\app_colors.dart test\theme\app_theme_test.dart
git commit -m "feat(theme): add Clinical Ethereal color palette"
```

---

## Task 4: Typography (Inter via Google Fonts)

**Files:**
- Create: `D:\Desktop\modular_chef\lib\theme\app_typography.dart`
- Modify: `D:\Desktop\modular_chef\test\theme\app_theme_test.dart`

- [ ] **Step 1: Add typography tests**

Дополнить `test\theme\app_theme_test.dart` — добавить новый `group` после существующего:

```dart
import 'package:modular_chef/theme/app_typography.dart';

// ... existing AppColors group ...

  group('AppTypography', () {
    test('display large uses tight letter-spacing per spec (-0.02em)', () {
      // -0.02em при fontSize 57 ≈ -1.14 logical px
      final style = AppTypography.textTheme.displayLarge!;
      expect(style.letterSpacing, closeTo(-1.14, 0.05));
    });

    test('body large color is the warm body grey', () {
      expect(
        AppTypography.textTheme.bodyLarge!.color,
        const Color(0xFF596064),
      );
    });

    test('label medium is uppercase tracking +0.05em', () {
      final style = AppTypography.textTheme.labelMedium!;
      // +0.05em при fontSize 12 = 0.6
      expect(style.letterSpacing, closeTo(0.6, 0.05));
    });
  });
```

- [ ] **Step 2: Run tests to verify failures**

```powershell
flutter test test\theme\app_theme_test.dart
```

Expected: FAIL — `Target of URI doesn't exist: 'package:modular_chef/theme/app_typography.dart'`.

- [ ] **Step 3: Create AppTypography**

Create `D:\Desktop\modular_chef\lib\theme\app_typography.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Типографика Clinical Ethereal: Inter из Google Fonts.
/// Display — tight letter-spacing (-0.02em), body — warm body grey.
abstract final class AppTypography {
  static TextTheme get textTheme {
    final base = GoogleFonts.interTextTheme();

    TextStyle? display(TextStyle? src) =>
        src?.copyWith(letterSpacing: src.fontSize! * -0.02);

    TextStyle? body(TextStyle? src) =>
        src?.copyWith(color: AppColors.onSurfaceVariant);

    TextStyle? label(TextStyle? src) =>
        src?.copyWith(letterSpacing: src.fontSize! * 0.05);

    return base.copyWith(
      displayLarge: display(base.displayLarge),
      displayMedium: display(base.displayMedium),
      displaySmall: display(base.displaySmall),
      headlineLarge: base.headlineLarge?.copyWith(color: AppColors.onSurface),
      headlineMedium: base.headlineMedium?.copyWith(color: AppColors.onSurface),
      headlineSmall: base.headlineSmall?.copyWith(color: AppColors.onSurface),
      titleLarge: base.titleLarge?.copyWith(color: AppColors.onSurface),
      titleMedium: base.titleMedium?.copyWith(color: AppColors.onSurface),
      titleSmall: base.titleSmall?.copyWith(color: AppColors.onSurface),
      bodyLarge: body(base.bodyLarge),
      bodyMedium: body(base.bodyMedium),
      bodySmall: body(base.bodySmall),
      labelLarge: label(base.labelLarge),
      labelMedium: label(base.labelMedium),
      labelSmall: label(base.labelSmall),
    );
  }
}
```

- [ ] **Step 4: Run tests to verify they pass**

```powershell
flutter test test\theme\app_theme_test.dart
```

Expected: PASS — все 10 тестов (7 цветов + 3 шрифты).

- [ ] **Step 5: Commit**

```powershell
git add lib\theme\app_typography.dart test\theme\app_theme_test.dart
git commit -m "feat(theme): add Inter typography with display/body/label rules"
```

---

## Task 5: ThemeData builder

**Files:**
- Create: `D:\Desktop\modular_chef\lib\theme\app_theme.dart`
- Modify: `D:\Desktop\modular_chef\test\theme\app_theme_test.dart`

- [ ] **Step 1: Add theme tests**

Дополнить `test\theme\app_theme_test.dart`:

```dart
import 'package:modular_chef/theme/app_theme.dart';

// ... at end of main(), add new group ...

  group('AppTheme.light', () {
    final theme = AppTheme.light();

    test('uses Material 3', () {
      expect(theme.useMaterial3, isTrue);
    });

    test('color scheme wires primary from AppColors', () {
      expect(theme.colorScheme.primary, AppColors.primary);
      expect(theme.colorScheme.primaryContainer, AppColors.primaryContainer);
      expect(theme.colorScheme.surface, AppColors.surface);
    });

    test('scaffold background is the surface base', () {
      expect(theme.scaffoldBackgroundColor, AppColors.surface);
    });

    test('card has xl radius (24) and white background, no shadow color', () {
      final card = theme.cardTheme;
      expect(card.color, AppColors.surfaceContainerLowest);
      final shape = card.shape as RoundedRectangleBorder;
      expect((shape.borderRadius as BorderRadius).topLeft.x, 24);
      expect(card.elevation, 0);
    });

    test('navigation bar has no indicator border / divider', () {
      final nav = theme.navigationBarTheme;
      expect(nav.backgroundColor, AppColors.surfaceContainerLowest);
      expect(nav.indicatorColor, AppColors.primaryContainer);
      // No top divider — Material 3 default has one; we override to none.
      expect(nav.surfaceTintColor, Colors.transparent);
    });

    test('app bar is flat — no elevation, no surface tint', () {
      final bar = theme.appBarTheme;
      expect(bar.elevation, 0);
      expect(bar.scrolledUnderElevation, 0);
      expect(bar.backgroundColor, AppColors.surface);
      expect(bar.surfaceTintColor, Colors.transparent);
    });
  });
```

- [ ] **Step 2: Run tests to verify failures**

```powershell
flutter test test\theme\app_theme_test.dart
```

Expected: FAIL — `Target of URI doesn't exist: 'package:modular_chef/theme/app_theme.dart'`.

- [ ] **Step 3: Create AppTheme**

Create `D:\Desktop\modular_chef\lib\theme\app_theme.dart`:

```dart
import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_typography.dart';

/// Фабрика ThemeData по спецификации Clinical Ethereal.
/// Правила: no 1px borders, скруглённые карточки, "Sanctuary shadow" (тинтованный).
abstract final class AppTheme {
  static ThemeData light() {
    const scheme = ColorScheme(
      brightness: Brightness.light,
      primary: AppColors.primary,
      onPrimary: AppColors.onPrimary,
      primaryContainer: AppColors.primaryContainer,
      onPrimaryContainer: AppColors.onPrimaryContainer,
      secondary: AppColors.secondary,
      onSecondary: AppColors.onSecondary,
      secondaryContainer: AppColors.secondaryContainer,
      onSecondaryContainer: AppColors.onSecondaryContainer,
      tertiary: AppColors.tertiary,
      onTertiary: AppColors.onTertiary,
      tertiaryContainer: AppColors.tertiaryContainer,
      onTertiaryContainer: AppColors.onTertiaryContainer,
      error: Color(0xFFB3261E),
      onError: Color(0xFFFFFFFF),
      surface: AppColors.surface,
      onSurface: AppColors.onSurface,
      onSurfaceVariant: AppColors.onSurfaceVariant,
      outlineVariant: AppColors.outlineVariant,
      shadow: AppColors.shadowTint,
    );

    final textTheme = AppTypography.textTheme;

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.surface,
      textTheme: textTheme,
      primaryTextTheme: textTheme,
      appBarTheme: const AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        foregroundColor: AppColors.onSurface,
        centerTitle: false,
      ),
      cardTheme: const CardTheme(
        color: AppColors.surfaceContainerLowest,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(24)),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.surfaceContainerLowest,
        surfaceTintColor: Colors.transparent,
        indicatorColor: AppColors.primaryContainer,
        elevation: 0,
        height: 72,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return textTheme.labelSmall!.copyWith(
            color: selected ? AppColors.onPrimaryContainer : AppColors.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected ? AppColors.onPrimaryContainer : AppColors.onSurfaceVariant,
            size: 24,
          );
        }),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surfaceContainerLow,
        selectedColor: AppColors.primaryContainer,
        labelStyle: textTheme.labelMedium,
        shape: const StadiumBorder(),
        side: BorderSide.none,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryContainer,
          foregroundColor: AppColors.onPrimaryContainer,
          elevation: 0,
          textStyle: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
          shape: const StadiumBorder(),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: Colors.transparent,
        thickness: 0,
        space: 0,
      ),
    );
  }
}
```

- [ ] **Step 4: Run tests to verify they pass**

```powershell
flutter test test\theme\app_theme_test.dart
```

Expected: PASS — all theme tests green.

- [ ] **Step 5: Commit**

```powershell
git add lib\theme\app_theme.dart test\theme\app_theme_test.dart
git commit -m "feat(theme): assemble ThemeData with no-line rule and xl radii"
```

---

## Task 6: Role enum + RoleProvider

**Files:**
- Create: `D:\Desktop\modular_chef\lib\shell\role.dart`
- Create: `D:\Desktop\modular_chef\lib\shell\role_provider.dart`
- Create: `D:\Desktop\modular_chef\test\shell\role_provider_test.dart`

- [ ] **Step 1: Write the failing test**

Create `D:\Desktop\modular_chef\test\shell\role_provider_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:modular_chef/shell/role.dart';
import 'package:modular_chef/shell/role_provider.dart';

void main() {
  group('RoleProvider', () {
    test('defaults to UserRole.chef', () {
      final provider = RoleProvider();
      expect(provider.role, UserRole.chef);
    });

    test('toggle switches chef → guest', () {
      final provider = RoleProvider();
      provider.toggle();
      expect(provider.role, UserRole.guest);
    });

    test('toggle switches guest → chef', () {
      final provider = RoleProvider()..toggle();
      provider.toggle();
      expect(provider.role, UserRole.chef);
    });

    test('toggle notifies listeners exactly once per call', () {
      final provider = RoleProvider();
      var count = 0;
      provider.addListener(() => count++);
      provider.toggle();
      provider.toggle();
      expect(count, 2);
    });

    test('setRole(same) does NOT notify (idempotent)', () {
      final provider = RoleProvider();
      var count = 0;
      provider.addListener(() => count++);
      provider.setRole(UserRole.chef); // already chef
      expect(count, 0);
    });

    test('setRole(different) notifies', () {
      final provider = RoleProvider();
      var count = 0;
      provider.addListener(() => count++);
      provider.setRole(UserRole.guest);
      expect(count, 1);
      expect(provider.role, UserRole.guest);
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

```powershell
flutter test test\shell\role_provider_test.dart
```

Expected: FAIL — `Target of URI doesn't exist`.

- [ ] **Step 3: Create role enum**

Create `D:\Desktop\modular_chef\lib\shell\role.dart`:

```dart
/// Активная роль пользователя в Modular Chef.
/// Шеф планирует и готовит впрок, Гость — выбирает из готовых заготовок.
enum UserRole { chef, guest }
```

- [ ] **Step 4: Create RoleProvider**

Create `D:\Desktop\modular_chef\lib\shell\role_provider.dart`:

```dart
import 'package:flutter/foundation.dart';
import 'role.dart';

/// Хранит текущую роль и уведомляет слушателей при смене.
/// Идемпотентен: setRole(той же роли) не дёргает listeners.
class RoleProvider extends ChangeNotifier {
  UserRole _role = UserRole.chef;

  UserRole get role => _role;

  void setRole(UserRole next) {
    if (next == _role) return;
    _role = next;
    notifyListeners();
  }

  void toggle() {
    setRole(_role == UserRole.chef ? UserRole.guest : UserRole.chef);
  }
}
```

- [ ] **Step 5: Run test to verify it passes**

```powershell
flutter test test\shell\role_provider_test.dart
```

Expected: PASS — 6 tests passed.

- [ ] **Step 6: Commit**

```powershell
git add lib\shell\role.dart lib\shell\role_provider.dart test\shell\role_provider_test.dart
git commit -m "feat(shell): add UserRole enum and RoleProvider"
```

---

## Task 7: Placeholder screens (8 штук)

**Files:**
- Create 5 chef screens: `lib\screens\chef\{menu,shopping,prep,storage,profile}_screen.dart`
- Create 3 guest screens: `lib\screens\guest\{today,week,inventory}_screen.dart`

> Все 8 placeholder экранов реализуются как минимальный `Scaffold` с заголовком и пометкой `TODO Stage 1b/1c`. Они существуют только чтобы дать роутеру что показать. Реальное содержимое придёт в Этапах 1b/1c.

- [ ] **Step 1: Create chef/menu_screen.dart**

```dart
import 'package:flutter/material.dart';

class MenuScreen extends StatelessWidget {
  const MenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Меню')),
      body: const Center(child: Text('Stage 1b/1c: «Собери своё меню» + «Меню на 2 недели»')),
    );
  }
}
```

- [ ] **Step 2: Create chef/shopping_screen.dart**

```dart
import 'package:flutter/material.dart';

class ShoppingScreen extends StatelessWidget {
  const ShoppingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Покупки')),
      body: const Center(child: Text('Stage 1b: порт chef/serene_5')),
    );
  }
}
```

- [ ] **Step 3: Create chef/prep_screen.dart**

```dart
import 'package:flutter/material.dart';

class PrepScreen extends StatelessWidget {
  const PrepScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Подготовка')),
      body: const Center(child: Text('Stage 1c: «День заготовки» (шаг 1 + шаг 2)')),
    );
  }
}
```

- [ ] **Step 4: Create chef/storage_screen.dart**

```dart
import 'package:flutter/material.dart';

class StorageScreen extends StatelessWidget {
  const StorageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Хранение')),
      body: const Center(child: Text('Stage 1c: «Карта хранения» с конкретными позициями')),
    );
  }
}
```

- [ ] **Step 5: Create chef/profile_screen.dart**

```dart
import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Профиль')),
      body: const Center(child: Text('Stage 2+: настройки, «Мои блюда»')),
    );
  }
}
```

- [ ] **Step 6: Create guest/today_screen.dart**

```dart
import 'package:flutter/material.dart';

class TodayScreen extends StatelessWidget {
  const TodayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Сегодня')),
      body: const Center(child: Text('Stage 1b: порт guest/v4_4')),
    );
  }
}
```

- [ ] **Step 7: Create guest/week_screen.dart**

```dart
import 'package:flutter/material.dart';

class WeekScreen extends StatelessWidget {
  const WeekScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Моя неделя')),
      body: const Center(child: Text('Stage 1b: порт guest/v4_2')),
    );
  }
}
```

- [ ] **Step 8: Create guest/inventory_screen.dart**

```dart
import 'package:flutter/material.dart';

class InventoryScreen extends StatelessWidget {
  const InventoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Запасы')),
      body: const Center(child: Text('Stage 1b: порт guest/v4_3')),
    );
  }
}
```

- [ ] **Step 9: Sanity analyze**

```powershell
flutter analyze
```

Expected: `No issues found!`.

- [ ] **Step 10: Commit**

```powershell
git add lib\screens
git commit -m "feat(screens): add 8 placeholder screens for Stage 1a navigation"
```

---

## Task 8: Routes constants

**Files:**
- Create: `D:\Desktop\modular_chef\lib\routing\routes.dart`

- [ ] **Step 1: Create routes constants**

Create `D:\Desktop\modular_chef\lib\routing\routes.dart`:

```dart
/// Канонические пути всех маршрутов приложения.
/// Используются как в GoRouter, так и в `context.go(Routes.x)`.
abstract final class Routes {
  // Chef branch
  static const chefMenu = '/chef/menu';
  static const chefShopping = '/chef/shopping';
  static const chefPrep = '/chef/prep';
  static const chefStorage = '/chef/storage';
  static const chefProfile = '/chef/profile';

  // Guest branch
  static const guestToday = '/guest/today';
  static const guestWeek = '/guest/week';
  static const guestInventory = '/guest/inventory';

  /// Default landing для каждой роли.
  static const chefRoot = chefMenu;
  static const guestRoot = guestToday;
}
```

- [ ] **Step 2: Commit**

```powershell
git add lib\routing\routes.dart
git commit -m "feat(routing): add route path constants"
```

---

## Task 9: RoleSwitcher AppBar action

**Files:**
- Create: `D:\Desktop\modular_chef\lib\shell\role_switcher.dart`

> Это переиспользуемый виджет: `IconButton`, который видит активную роль через `Provider` и переключает её. Используется в `actions:` AppBar обоих shell.

- [ ] **Step 1: Create RoleSwitcher**

Create `D:\Desktop\modular_chef\lib\shell\role_switcher.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'role.dart';
import 'role_provider.dart';

/// Кнопка в AppBar для переключения между Шефом и Гостем.
/// Текст подсказки и SnackBar после тапа объясняют, в какую роль перешли.
class RoleSwitcher extends StatelessWidget {
  const RoleSwitcher({super.key});

  @override
  Widget build(BuildContext context) {
    final role = context.watch<RoleProvider>().role;
    final isChef = role == UserRole.chef;
    final tooltip = isChef ? 'Стать Гостем' : 'Стать Шефом';

    return IconButton(
      icon: const Icon(Icons.swap_horiz),
      tooltip: tooltip,
      onPressed: () {
        context.read<RoleProvider>().toggle();
        final next = isChef ? 'Гость' : 'Шеф';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Роль: $next'),
            duration: const Duration(seconds: 1),
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
    );
  }
}
```

- [ ] **Step 2: Commit**

```powershell
git add lib\shell\role_switcher.dart
git commit -m "feat(shell): add RoleSwitcher AppBar IconButton"
```

---

## Task 10: ChefShell (5-tab navigation)

**Files:**
- Create: `D:\Desktop\modular_chef\lib\shell\chef_shell.dart`
- Create: `D:\Desktop\modular_chef\test\shell\chef_shell_test.dart`

- [ ] **Step 1: Write the failing widget test**

Create `D:\Desktop\modular_chef\test\shell\chef_shell_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:modular_chef/shell/chef_shell.dart';
import 'package:modular_chef/shell/role_provider.dart';

Widget _harness(Widget child) {
  return ChangeNotifierProvider(
    create: (_) => RoleProvider(),
    child: MaterialApp(home: child),
  );
}

void main() {
  group('ChefShell', () {
    testWidgets('renders NavigationBar with 5 destinations', (tester) async {
      await tester.pumpWidget(_harness(
        ChefShell(
          currentIndex: 0,
          onDestinationSelected: (_) {},
          child: const Placeholder(),
        ),
      ));

      expect(find.byType(NavigationBar), findsOneWidget);
      expect(find.byType(NavigationDestination), findsNWidgets(5));
    });

    testWidgets('labels match chef tab plan', (tester) async {
      await tester.pumpWidget(_harness(
        ChefShell(
          currentIndex: 0,
          onDestinationSelected: (_) {},
          child: const Placeholder(),
        ),
      ));

      for (final label in const ['Меню', 'Покупки', 'Подготовка', 'Хранение', 'Профиль']) {
        expect(find.text(label), findsOneWidget, reason: 'missing tab "$label"');
      }
    });

    testWidgets('tapping destination calls onDestinationSelected with index',
        (tester) async {
      int? tapped;
      await tester.pumpWidget(_harness(
        ChefShell(
          currentIndex: 0,
          onDestinationSelected: (i) => tapped = i,
          child: const Placeholder(),
        ),
      ));

      await tester.tap(find.text('Покупки'));
      expect(tapped, 1);
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

```powershell
flutter test test\shell\chef_shell_test.dart
```

Expected: FAIL — `Target of URI doesn't exist: 'package:modular_chef/shell/chef_shell.dart'`.

- [ ] **Step 3: Create ChefShell**

Create `D:\Desktop\modular_chef\lib\shell\chef_shell.dart`:

```dart
import 'package:flutter/material.dart';

/// Скаффолд для роли Шефа: верхнее «оформление» в AppBar делает экран сам,
/// shell отвечает только за нижнюю навигацию и текущее тело.
class ChefShell extends StatelessWidget {
  const ChefShell({
    super.key,
    required this.currentIndex,
    required this.onDestinationSelected,
    required this.child,
  });

  final int currentIndex;
  final ValueChanged<int> onDestinationSelected;
  final Widget child;

  static const _destinations = <NavigationDestination>[
    NavigationDestination(
      icon: Icon(Icons.restaurant_menu_outlined),
      selectedIcon: Icon(Icons.restaurant_menu),
      label: 'Меню',
    ),
    NavigationDestination(
      icon: Icon(Icons.shopping_cart_outlined),
      selectedIcon: Icon(Icons.shopping_cart),
      label: 'Покупки',
    ),
    NavigationDestination(
      icon: Icon(Icons.soup_kitchen_outlined),
      selectedIcon: Icon(Icons.soup_kitchen),
      label: 'Подготовка',
    ),
    NavigationDestination(
      icon: Icon(Icons.inventory_2_outlined),
      selectedIcon: Icon(Icons.inventory_2),
      label: 'Хранение',
    ),
    NavigationDestination(
      icon: Icon(Icons.person_outline),
      selectedIcon: Icon(Icons.person),
      label: 'Профиль',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: onDestinationSelected,
        destinations: _destinations,
      ),
    );
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

```powershell
flutter test test\shell\chef_shell_test.dart
```

Expected: PASS — 3 tests.

- [ ] **Step 5: Commit**

```powershell
git add lib\shell\chef_shell.dart test\shell\chef_shell_test.dart
git commit -m "feat(shell): add ChefShell with 5-tab NavigationBar"
```

---

## Task 11: GuestShell (3-tab navigation)

**Files:**
- Create: `D:\Desktop\modular_chef\lib\shell\guest_shell.dart`
- Create: `D:\Desktop\modular_chef\test\shell\guest_shell_test.dart`

- [ ] **Step 1: Write the failing widget test**

Create `D:\Desktop\modular_chef\test\shell\guest_shell_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:modular_chef/shell/guest_shell.dart';
import 'package:modular_chef/shell/role_provider.dart';

Widget _harness(Widget child) {
  return ChangeNotifierProvider(
    create: (_) => RoleProvider(),
    child: MaterialApp(home: child),
  );
}

void main() {
  group('GuestShell', () {
    testWidgets('renders NavigationBar with 3 destinations', (tester) async {
      await tester.pumpWidget(_harness(
        GuestShell(
          currentIndex: 0,
          onDestinationSelected: (_) {},
          child: const Placeholder(),
        ),
      ));

      expect(find.byType(NavigationBar), findsOneWidget);
      expect(find.byType(NavigationDestination), findsNWidgets(3));
    });

    testWidgets('labels match guest tab plan', (tester) async {
      await tester.pumpWidget(_harness(
        GuestShell(
          currentIndex: 0,
          onDestinationSelected: (_) {},
          child: const Placeholder(),
        ),
      ));

      for (final label in const ['Сегодня', 'Неделя', 'Запасы']) {
        expect(find.text(label), findsOneWidget, reason: 'missing tab "$label"');
      }
    });

    testWidgets('tapping destination calls onDestinationSelected with index',
        (tester) async {
      int? tapped;
      await tester.pumpWidget(_harness(
        GuestShell(
          currentIndex: 0,
          onDestinationSelected: (i) => tapped = i,
          child: const Placeholder(),
        ),
      ));

      await tester.tap(find.text('Запасы'));
      expect(tapped, 2);
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

```powershell
flutter test test\shell\guest_shell_test.dart
```

Expected: FAIL — `Target of URI doesn't exist`.

- [ ] **Step 3: Create GuestShell**

Create `D:\Desktop\modular_chef\lib\shell\guest_shell.dart`:

```dart
import 'package:flutter/material.dart';

class GuestShell extends StatelessWidget {
  const GuestShell({
    super.key,
    required this.currentIndex,
    required this.onDestinationSelected,
    required this.child,
  });

  final int currentIndex;
  final ValueChanged<int> onDestinationSelected;
  final Widget child;

  static const _destinations = <NavigationDestination>[
    NavigationDestination(
      icon: Icon(Icons.today_outlined),
      selectedIcon: Icon(Icons.today),
      label: 'Сегодня',
    ),
    NavigationDestination(
      icon: Icon(Icons.calendar_month_outlined),
      selectedIcon: Icon(Icons.calendar_month),
      label: 'Неделя',
    ),
    NavigationDestination(
      icon: Icon(Icons.kitchen_outlined),
      selectedIcon: Icon(Icons.kitchen),
      label: 'Запасы',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: onDestinationSelected,
        destinations: _destinations,
      ),
    );
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

```powershell
flutter test test\shell\guest_shell_test.dart
```

Expected: PASS — 3 tests.

- [ ] **Step 5: Commit**

```powershell
git add lib\shell\guest_shell.dart test\shell\guest_shell_test.dart
git commit -m "feat(shell): add GuestShell with 3-tab NavigationBar"
```

---

## Task 12: GoRouter with role-based redirect

**Files:**
- Create: `D:\Desktop\modular_chef\lib\routing\app_router.dart`
- Create: `D:\Desktop\modular_chef\test\routing\app_router_test.dart`
- Modify: 8 placeholder screens (добавить `RoleSwitcher` в AppBar.actions) — реально это уже сделают `chef_shell`/`guest_shell` через обёртку? Нет, AppBar у каждого экрана свой; добавим switcher здесь.

> **Подход к router:** один `GoRouter` с двумя независимыми ветками `/chef/*` и `/guest/*`. Глобальный `redirect` смотрит на текущую `UserRole`: если пользователь в Гост-ветке, а роль = Шеф (или наоборот), редиректим на корневой таб правильной ветки. Каждая ветка использует свой shell через `ShellRoute`.

- [ ] **Step 1: Add RoleSwitcher to each placeholder screen's AppBar**

Для каждого из 8 placeholder screens (Task 7) заменить строку
```dart
appBar: AppBar(title: const Text('XXX')),
```
на
```dart
appBar: AppBar(
  title: const Text('XXX'),
  actions: const [RoleSwitcher(), SizedBox(width: 8)],
),
```
и добавить наверху файла:
```dart
import 'package:modular_chef/shell/role_switcher.dart';
```

Полные обновлённые файлы (для копи-пейста):

`lib\screens\chef\menu_screen.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:modular_chef/shell/role_switcher.dart';

class MenuScreen extends StatelessWidget {
  const MenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Меню'),
        actions: const [RoleSwitcher(), SizedBox(width: 8)],
      ),
      body: const Center(child: Text('Stage 1b/1c: «Собери своё меню» + «Меню на 2 недели»')),
    );
  }
}
```

`lib\screens\chef\shopping_screen.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:modular_chef/shell/role_switcher.dart';

class ShoppingScreen extends StatelessWidget {
  const ShoppingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Покупки'),
        actions: const [RoleSwitcher(), SizedBox(width: 8)],
      ),
      body: const Center(child: Text('Stage 1b: порт chef/serene_5')),
    );
  }
}
```

`lib\screens\chef\prep_screen.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:modular_chef/shell/role_switcher.dart';

class PrepScreen extends StatelessWidget {
  const PrepScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Подготовка'),
        actions: const [RoleSwitcher(), SizedBox(width: 8)],
      ),
      body: const Center(child: Text('Stage 1c: «День заготовки» (шаг 1 + шаг 2)')),
    );
  }
}
```

`lib\screens\chef\storage_screen.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:modular_chef/shell/role_switcher.dart';

class StorageScreen extends StatelessWidget {
  const StorageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Хранение'),
        actions: const [RoleSwitcher(), SizedBox(width: 8)],
      ),
      body: const Center(child: Text('Stage 1c: «Карта хранения» с конкретными позициями')),
    );
  }
}
```

`lib\screens\chef\profile_screen.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:modular_chef/shell/role_switcher.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Профиль'),
        actions: const [RoleSwitcher(), SizedBox(width: 8)],
      ),
      body: const Center(child: Text('Stage 2+: настройки, «Мои блюда»')),
    );
  }
}
```

`lib\screens\guest\today_screen.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:modular_chef/shell/role_switcher.dart';

class TodayScreen extends StatelessWidget {
  const TodayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Сегодня'),
        actions: const [RoleSwitcher(), SizedBox(width: 8)],
      ),
      body: const Center(child: Text('Stage 1b: порт guest/v4_4')),
    );
  }
}
```

`lib\screens\guest\week_screen.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:modular_chef/shell/role_switcher.dart';

class WeekScreen extends StatelessWidget {
  const WeekScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Моя неделя'),
        actions: const [RoleSwitcher(), SizedBox(width: 8)],
      ),
      body: const Center(child: Text('Stage 1b: порт guest/v4_2')),
    );
  }
}
```

`lib\screens\guest\inventory_screen.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:modular_chef/shell/role_switcher.dart';

class InventoryScreen extends StatelessWidget {
  const InventoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Запасы'),
        actions: const [RoleSwitcher(), SizedBox(width: 8)],
      ),
      body: const Center(child: Text('Stage 1b: порт guest/v4_3')),
    );
  }
}
```

- [ ] **Step 2: Write the failing router test**

Create `D:\Desktop\modular_chef\test\routing\app_router_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:modular_chef/routing/app_router.dart';
import 'package:modular_chef/routing/routes.dart';
import 'package:modular_chef/shell/role.dart';
import 'package:modular_chef/shell/role_provider.dart';
import 'package:modular_chef/theme/app_theme.dart';

Future<void> _pumpApp(WidgetTester tester, RoleProvider provider) async {
  final router = buildRouter(provider);
  await tester.pumpWidget(
    ChangeNotifierProvider.value(
      value: provider,
      child: MaterialApp.router(
        theme: AppTheme.light(),
        routerConfig: router,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('AppRouter', () {
    testWidgets('default role chef opens Меню tab', (tester) async {
      await _pumpApp(tester, RoleProvider());
      expect(find.text('Меню'), findsWidgets); // tab label + appbar title
      expect(find.text('Сегодня'), findsNothing);
    });

    testWidgets('starting as guest opens Сегодня tab', (tester) async {
      final provider = RoleProvider()..setRole(UserRole.guest);
      await _pumpApp(tester, provider);
      expect(find.text('Сегодня'), findsWidgets);
      expect(find.text('Меню'), findsNothing);
    });

    testWidgets('toggling role redirects to other branch root', (tester) async {
      final provider = RoleProvider();
      await _pumpApp(tester, provider);
      expect(find.text('Меню'), findsWidgets);

      provider.toggle(); // chef → guest
      await tester.pumpAndSettle();
      expect(find.text('Сегодня'), findsWidgets);
      expect(find.text('Меню'), findsNothing);
    });

    testWidgets('routes constants point to existing destinations',
        (tester) async {
      // sanity: убедиться что константы хотя бы существуют и не пустые
      expect(Routes.chefMenu, isNotEmpty);
      expect(Routes.guestToday, isNotEmpty);
      expect(Routes.chefRoot, Routes.chefMenu);
      expect(Routes.guestRoot, Routes.guestToday);
    });
  });
}
```

- [ ] **Step 3: Run test to verify it fails**

```powershell
flutter test test\routing\app_router_test.dart
```

Expected: FAIL — `Target of URI doesn't exist: 'package:modular_chef/routing/app_router.dart'`.

- [ ] **Step 4: Create AppRouter**

Create `D:\Desktop\modular_chef\lib\routing\app_router.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:modular_chef/screens/chef/menu_screen.dart';
import 'package:modular_chef/screens/chef/prep_screen.dart';
import 'package:modular_chef/screens/chef/profile_screen.dart';
import 'package:modular_chef/screens/chef/shopping_screen.dart';
import 'package:modular_chef/screens/chef/storage_screen.dart';
import 'package:modular_chef/screens/guest/inventory_screen.dart';
import 'package:modular_chef/screens/guest/today_screen.dart';
import 'package:modular_chef/screens/guest/week_screen.dart';
import 'package:modular_chef/shell/chef_shell.dart';
import 'package:modular_chef/shell/guest_shell.dart';
import 'package:modular_chef/shell/role.dart';
import 'package:modular_chef/shell/role_provider.dart';
import 'routes.dart';

/// Создаёт `GoRouter`, который:
///  - слушает `RoleProvider` (refreshListenable)
///  - редиректит между Chef-веткой и Guest-веткой при смене роли
///  - оборачивает каждую ветку в свой shell (5/3 табов)
GoRouter buildRouter(RoleProvider role) {
  return GoRouter(
    initialLocation: role.role == UserRole.chef ? Routes.chefRoot : Routes.guestRoot,
    refreshListenable: role,
    redirect: (context, state) {
      final path = state.matchedLocation;
      final inChefBranch = path.startsWith('/chef');
      final inGuestBranch = path.startsWith('/guest');
      if (role.role == UserRole.chef && inGuestBranch) {
        return Routes.chefRoot;
      }
      if (role.role == UserRole.guest && inChefBranch) {
        return Routes.guestRoot;
      }
      return null;
    },
    routes: [
      _chefBranch(),
      _guestBranch(),
    ],
  );
}

ShellRoute _chefBranch() {
  const order = [
    Routes.chefMenu,
    Routes.chefShopping,
    Routes.chefPrep,
    Routes.chefStorage,
    Routes.chefProfile,
  ];

  int indexOf(String location) {
    final i = order.indexWhere(location.startsWith);
    return i < 0 ? 0 : i;
  }

  return ShellRoute(
    builder: (context, state, child) {
      return ChefShell(
        currentIndex: indexOf(state.matchedLocation),
        onDestinationSelected: (i) => context.go(order[i]),
        child: child,
      );
    },
    routes: [
      GoRoute(path: Routes.chefMenu, builder: (_, __) => const MenuScreen()),
      GoRoute(path: Routes.chefShopping, builder: (_, __) => const ShoppingScreen()),
      GoRoute(path: Routes.chefPrep, builder: (_, __) => const PrepScreen()),
      GoRoute(path: Routes.chefStorage, builder: (_, __) => const StorageScreen()),
      GoRoute(path: Routes.chefProfile, builder: (_, __) => const ProfileScreen()),
    ],
  );
}

ShellRoute _guestBranch() {
  const order = [
    Routes.guestToday,
    Routes.guestWeek,
    Routes.guestInventory,
  ];

  int indexOf(String location) {
    final i = order.indexWhere(location.startsWith);
    return i < 0 ? 0 : i;
  }

  return ShellRoute(
    builder: (context, state, child) {
      return GuestShell(
        currentIndex: indexOf(state.matchedLocation),
        onDestinationSelected: (i) => context.go(order[i]),
        child: child,
      );
    },
    routes: [
      GoRoute(path: Routes.guestToday, builder: (_, __) => const TodayScreen()),
      GoRoute(path: Routes.guestWeek, builder: (_, __) => const WeekScreen()),
      GoRoute(path: Routes.guestInventory, builder: (_, __) => const InventoryScreen()),
    ],
  );
}
```

- [ ] **Step 5: Run test to verify it passes**

```powershell
flutter test test\routing\app_router_test.dart
```

Expected: PASS — 4 tests.

- [ ] **Step 6: Commit**

```powershell
git add lib\routing\app_router.dart lib\screens test\routing\app_router_test.dart
git commit -m "feat(routing): wire GoRouter with role-based branch redirect"
```

---

## Task 13: App + main + smoke run

**Files:**
- Create: `D:\Desktop\modular_chef\lib\app.dart`
- Modify (overwrite): `D:\Desktop\modular_chef\lib\main.dart`
- Modify: `D:\Desktop\modular_chef\test\widget_test.dart` (полностью переписать — дефолтный тест Flutter не подходит)
- Create: `D:\Desktop\modular_chef\README.md`

- [ ] **Step 1: Create app.dart**

Create `D:\Desktop\modular_chef\lib\app.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'routing/app_router.dart';
import 'shell/role_provider.dart';
import 'theme/app_theme.dart';

class ModularChefApp extends StatefulWidget {
  const ModularChefApp({super.key});

  @override
  State<ModularChefApp> createState() => _ModularChefAppState();
}

class _ModularChefAppState extends State<ModularChefApp> {
  late final RoleProvider _role = RoleProvider();
  late final _router = buildRouter(_role);

  @override
  void dispose() {
    _role.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<RoleProvider>.value(
      value: _role,
      child: MaterialApp.router(
        title: 'Modular Chef',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        routerConfig: _router,
      ),
    );
  }
}
```

- [ ] **Step 2: Overwrite main.dart**

Replace entire `D:\Desktop\modular_chef\lib\main.dart` content:

```dart
import 'package:flutter/material.dart';
import 'app.dart';

void main() {
  runApp(const ModularChefApp());
}
```

- [ ] **Step 3: Overwrite the default widget_test.dart**

Дефолтный `test\widget_test.dart` от `flutter create` тестит счётчик из старого шаблона — он сломается. Заменить его на минимальный smoke test:

Replace entire `D:\Desktop\modular_chef\test\widget_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:modular_chef/app.dart';

void main() {
  testWidgets('App boots and shows the chef menu tab', (tester) async {
    await tester.pumpWidget(const ModularChefApp());
    await tester.pumpAndSettle();
    expect(find.text('Меню'), findsWidgets);
  });
}
```

- [ ] **Step 4: Run full test suite**

```powershell
flutter test
```

Expected: все тесты зелёные (≈ 20+ тестов). Если падают — остановиться и чинить ДО следующего шага.

- [ ] **Step 5: Static analysis**

```powershell
flutter analyze
```

Expected: `No issues found!`.

- [ ] **Step 6: Smoke run on Windows desktop**

```powershell
flutter run -d windows
```

Expected:
- Приложение собирается и запускается
- Видна шапка «Меню» с иконкой `swap_horiz` справа
- Внизу 5 табов: Меню / Покупки / Подготовка / Хранение / Профиль
- Тап по `swap_horiz` → переход в роль Гостя: 3 таба Сегодня / Неделя / Запасы, в шапке «Сегодня»
- Тап ещё раз → возврат в Шефа
- Цвета: пудрово-розовый фон, мягкий зелёный для активного таба

Если запуск падает (на Windows нет VS2022 toolchain) — попробовать `flutter run -d chrome` или эмулятор Android. Закрыть приложение когда убедились что работает.

- [ ] **Step 7: Create README**

Create `D:\Desktop\modular_chef\README.md`:

````markdown
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
````

- [ ] **Step 8: Commit**

```powershell
git add lib\app.dart lib\main.dart test\widget_test.dart README.md
git commit -m "feat: wire ModularChefApp entry point + smoke test + README"
```

- [ ] **Step 9: Final verification**

```powershell
git log --oneline
flutter analyze
flutter test
```

Expected:
- ~13 коммитов в линейной истории
- `No issues found!`
- All tests green

---

## Done state

После этого плана у вас есть:
- ✅ Чистый Flutter-проект `D:\Desktop\modular_chef` с git
- ✅ Полная тема Clinical Ethereal, готовая принимать любые экраны
- ✅ Bottom nav под обе роли
- ✅ Переключатель ролей в AppBar
- ✅ 8 placeholder-экранов, готовых к замене на реальное содержимое в Этапах 1b/1c
- ✅ Юнит- и виджет-тесты на критичные компоненты (RoleProvider, shells, router)

**Следующий шаг:** Этап 1b — портирование 5 готовых HTML-макетов в Flutter (заменяет `*_screen.dart` placeholder'ы реальным содержимым).
