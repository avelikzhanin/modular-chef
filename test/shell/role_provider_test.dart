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
