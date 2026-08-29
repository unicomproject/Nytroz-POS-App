import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../../core/access/pos_permission_access.dart';
import '../../../../../auth/presentation/providers/session_provider.dart';
import '../../../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';

class PosCashierBottomNavigation extends ConsumerWidget {
  const PosCashierBottomNavigation({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentPath = GoRouterState.of(context).uri.path;
    final session = ref.watch(authSessionProvider);
    final permissions = session?.permissionCodes.toSet() ?? const <String>{};
    final destinations = <_CashierDestination>[
      _CashierDestination(
        label: 'Home',
        icon: Icons.home_outlined,
        selectedIcon: Icons.home_rounded,
        route: '/pos/home',
        enabled: PosPermissionAccess.canViewHome(permissions),
      ),
      _CashierDestination(
        label: 'New Sale',
        icon: Icons.shopping_cart_outlined,
        selectedIcon: Icons.shopping_cart_rounded,
        route: '/pos/new-sale',
        enabled: PosPermissionAccess.canAccessNewSale(permissions),
      ),
      _CashierDestination(
        label: 'Orders',
        icon: Icons.receipt_long_outlined,
        selectedIcon: Icons.receipt_long_rounded,
        route: '/pos/orders',
        enabled: permissions.contains('receipts.view'),
      ),
      _CashierDestination(
        label: 'Customers',
        icon: Icons.people_outline_rounded,
        selectedIcon: Icons.people_rounded,
        route: '/pos/customers',
        enabled: PosPermissionAccess.canViewCustomers(permissions),
      ),
      const _CashierDestination(
        label: 'Settings',
        icon: Icons.settings_outlined,
        selectedIcon: Icons.settings_rounded,
        route: '/pos/settings',
        enabled: true,
      ),
    ];

    return Material(
      color: TenantAdminColors.posHomeDarkBackground,
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 68,
          child: Row(
            children: [
              for (final destination in destinations)
                Expanded(
                  child: _DestinationButton(
                    destination: destination,
                    selected: destination.matches(currentPath),
                    onTap: () => _handleTap(context, destination),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleTap(
    BuildContext context,
    _CashierDestination destination,
  ) {
    if (destination.enabled && destination.route != null) {
      context.go(destination.route!);
    }
  }
}

class _DestinationButton extends StatelessWidget {
  const _DestinationButton({
    required this.destination,
    required this.selected,
    required this.onTap,
  });

  final _CashierDestination destination;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = destination.enabled;
    final color = selected
        ? TenantAdminColors.posHomeAccentOrange
        : enabled
            ? TenantAdminColors.surface
            : TenantAdminColors.offline;

    return Semantics(
      button: true,
      enabled: enabled,
      selected: selected,
      label: destination.label,
      child: InkWell(
        onTap: enabled ? onTap : null,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 4,
                vertical: 6,
              ),
              child: Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        selected ? destination.selectedIcon : destination.icon,
                        size: 24,
                        color: color,
                      ),
                      const SizedBox(width: 7),
                      Text(
                        destination.label,
                        maxLines: 1,
                        softWrap: false,
                        style: TextStyle(
                          color: color,
                          fontSize: 14,
                          fontWeight:
                              selected ? FontWeight.w900 : FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (selected)
              const Positioned(
                left: 28,
                right: 28,
                bottom: 0,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: TenantAdminColors.posHomeAccentOrange,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(3),
                    ),
                  ),
                  child: SizedBox(height: 5),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _CashierDestination {
  const _CashierDestination({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    this.route,
    this.enabled = false,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final String? route;
  final bool enabled;

  bool matches(String currentPath) {
    final destinationRoute = route;
    if (destinationRoute == null) {
      return false;
    }
    return currentPath == destinationRoute ||
        currentPath.startsWith('$destinationRoute/');
  }
}
