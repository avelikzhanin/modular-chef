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
