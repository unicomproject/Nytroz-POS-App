import 'package:flutter/material.dart';

import '../../../../../core/access/effective_permission_set.dart';
import '../../../../../core/access/pos_access_codes.dart';
import '../../../../../core/access/pos_permission_access.dart';

/// Stable cashier bottom-nav destination identity (not a static index).
enum PosCashierNavDestinationId {
  home,
  newSale,
  orders,
  customers,
  settings,
}

/// Destination definition before permission filtering.
class PosCashierNavDestination {
  const PosCashierNavDestination({
    required this.id,
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.route,
    required this.isPermitted,
  });

  final PosCashierNavDestinationId id;
  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final String route;
  final bool Function(EffectivePermissionSet permissions) isPermitted;

  bool matches(String currentPath) {
    return currentPath == route || currentPath.startsWith('$route/');
  }
}

/// Shared destination catalog. Phone / tablet / desktop consume the same
/// filtered set — layout may differ; permission semantics must not.
List<PosCashierNavDestination> posCashierNavAllDestinations() {
  return [
    PosCashierNavDestination(
      id: PosCashierNavDestinationId.home,
      label: 'Home',
      icon: Icons.home_outlined,
      selectedIcon: Icons.home_rounded,
      route: '/pos/home',
      isPermitted: (set) =>
          PosPermissionAccess.canViewHome(set.codes.toSet()),
    ),
    PosCashierNavDestination(
      id: PosCashierNavDestinationId.newSale,
      label: 'New Sale',
      icon: Icons.shopping_cart_outlined,
      selectedIcon: Icons.shopping_cart_rounded,
      route: '/pos/new-sale',
      isPermitted: (set) =>
          PosPermissionAccess.canAccessNewSale(set.codes.toSet()),
    ),
    PosCashierNavDestination(
      id: PosCashierNavDestinationId.orders,
      label: 'Orders',
      icon: Icons.receipt_long_outlined,
      selectedIcon: Icons.receipt_long_rounded,
      route: '/pos/orders',
      isPermitted: (set) => PosPermissionAccess.hasAny(
        set.codes.toSet(),
        PosPermissionAccess.receiptViewAccessCodes,
      ),
    ),
    PosCashierNavDestination(
      id: PosCashierNavDestinationId.customers,
      label: 'Customers',
      icon: Icons.people_outline_rounded,
      selectedIcon: Icons.people_rounded,
      route: '/pos/customers',
      isPermitted: (set) =>
          PosPermissionAccess.canViewCustomers(set.codes.toSet()),
    ),
    PosCashierNavDestination(
      id: PosCashierNavDestinationId.settings,
      label: 'Settings',
      icon: Icons.settings_outlined,
      selectedIcon: Icons.settings_rounded,
      route: '/pos/settings',
      isPermitted: (set) =>
          set.hasPermission(PosPermissionCodes.shellNavigationSettings),
    ),
  ];
}

/// Filter destinations by exact effective membership. Denied items omitted.
List<PosCashierNavDestination> filterPosCashierNavDestinations(
  EffectivePermissionSet permissions,
) {
  return posCashierNavAllDestinations()
      .where((destination) => destination.isPermitted(permissions))
      .toList(growable: false);
}

/// Whether the bottom-nav container may render (container + ≥1 destination).
bool shouldShowPosCashierBottomNav(EffectivePermissionSet permissions) {
  if (!permissions.hasPermission(PosPermissionCodes.shellBottomNavContainer)) {
    return false;
  }
  return filterPosCashierNavDestinations(permissions).isNotEmpty;
}
