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
    initialLocation:
        role.role == UserRole.chef ? Routes.chefRoot : Routes.guestRoot,
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
