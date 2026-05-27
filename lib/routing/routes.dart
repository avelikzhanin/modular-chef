/// Канонические пути всех маршрутов приложения.
/// Используются как в GoRouter, так и в `context.go(Routes.x)`.
abstract final class Routes {
  // Chef branch
  static const chefMenu = '/chef/menu';
  static const chefShopping = '/chef/shopping';
  static const chefPrep = '/chef/prep';
  static const chefStorage = '/chef/storage';
  static const chefProfile = '/chef/profile';

  /// Push-экран Шефа: библиотека «Мои блюда» (открывается из Профиля).
  static const chefMyDishes = '/chef/my-dishes';

  // Guest branch
  static const guestToday = '/guest/today';
  static const guestWeek = '/guest/week';
  static const guestInventory = '/guest/inventory';

  /// Push-экран Гостя: «Собрать блюдо» (открывается из Сегодня / Запасы).
  static const guestAssembleDish = '/guest/assemble';

  /// Default landing для каждой роли.
  static const chefRoot = chefMenu;
  static const guestRoot = guestToday;
}
