import 'package:flutter/foundation.dart';
import 'package:modular_chef/services/local_store.dart';
import 'role.dart';

/// Хранит текущую роль и уведомляет слушателей при смене.
/// Идемпотентен: setRole(той же роли) не дёргает listeners.
/// Роль запоминается: Гость не должен каждый раз переключаться из Шефа.
class RoleProvider extends ChangeNotifier {
  RoleProvider({LocalStore? store}) : _store = store;

  static const _storeKey = 'user_role';

  final LocalStore? _store;
  UserRole _role = UserRole.chef;

  UserRole get role => _role;

  Future<void> loadFromStore() async {
    final json = await _store?.readJson(_storeKey);
    final saved = json?['role'] as String?;
    if (saved == null) return;
    final next = UserRole.values.firstWhere(
      (r) => r.name == saved,
      orElse: () => UserRole.chef,
    );
    if (next == _role) return;
    _role = next;
    notifyListeners();
  }

  void setRole(UserRole next) {
    if (next == _role) return;
    _role = next;
    _store?.writeJson(_storeKey, {'role': next.name});
    notifyListeners();
  }

  void toggle() {
    setRole(_role == UserRole.chef ? UserRole.guest : UserRole.chef);
  }
}
