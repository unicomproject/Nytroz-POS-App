import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/access/pos_permission_access.dart';
import '../../../auth/presentation/providers/session_provider.dart';
import '../theme/tenant_admin_theme.dart';

/// Path prefixes considered part of the Tenant Admin settings/catalog area.
/// The footer's Settings tab is shown as active whenever [currentPath]
/// starts with `/tenant-admin/` and matches one of these segments.
const List<String> tenantAdminSettingsAreaSegments = [
  'settings',
  'categories',
  'stock',
  'staff',
  'variant-templates',
  'import',
];

/// Whether [path] belongs to the Tenant Admin settings/catalog area.
/// Used to mark the footer Settings tab as active.
bool isTenantAdminSettingsAreaPath(String path) {
  const prefix = '/tenant-admin/';
  if (!path.startsWith(prefix)) {
    return false;
  }

  final remainder = path.substring(prefix.length);
  return tenantAdminSettingsAreaSegments.any(
    (segment) => remainder == segment || remainder.startsWith('$segment/'),
  );
}

/// Fixed black bottom navigation shown on Tenant Admin settings/catalog
/// routes. Visually matches [PosCashierBottomNavigation]: black background,
/// orange selected state, white inactive icons, bottom indicator bar.
class TenantAdminFooterNavigation extends ConsumerWidget {
  const TenantAdminFooterNavigation({super.key, required this.currentPath});

  final String currentPath;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(authSessionProvider);
    final permissions = session?.permissionCodes.toSet() ?? const <String>{};

    final destinations = <_FooterDestination>[
      _FooterDestination(
        label: 'Home',
        icon: Icons.home_outlined,
        selectedIcon: Icons.home_rounded,
        route: '/pos/home',
        enabled: PosPermissionAccess.canViewHome(permissions),
      ),
      _FooterDestination(
        label: 'New Sale',
        icon: Icons.shopping_cart_outlined,
        selectedIcon: Icons.shopping_cart_rounded,
        route: '/pos/new-sale',
        enabled: PosPermissionAccess.canAccessNewSale(permissions),
      ),
      const _FooterDestination(
        label: 'Orders',
        icon: Icons.receipt_long_outlined,
        selectedIcon: Icons.receipt_long_rounded,
        unavailableMessage: 'Orders screen is not available yet.',
      ),
      _FooterDestination(
        label: 'Customers',
        icon: Icons.people_outline_rounded,
        selectedIcon: Icons.people_rounded,
        route: '/pos/customers',
        enabled: PosPermissionAccess.canViewCustomers(permissions),
      ),
      const _FooterDestination(
        label: 'Settings',
        icon: Icons.settings_outlined,
        selectedIcon: Icons.settings_rounded,
        route: '/tenant-admin/settings',
        enabled: true,
        isSettings: true,
      ),
    ];

    return Material(
      color: TenantAdminColors.posHomeDarkBackground,
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: TenantAdminFooterNav.height,
          child: Row(
            children: [
              for (final destination in destinations)
                Expanded(
                  child: _FooterDestinationButton(
                    destination: destination,
                    selected: destination.isSettings
                        ? isTenantAdminSettingsAreaPath(currentPath)
                        : destination.matches(currentPath),
                    onTap: () => _handleTap(context, destination),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleTap(BuildContext context, _FooterDestination destination) {
    if (destination.isSettings) {
      if (!isTenantAdminSettingsAreaPath(currentPath)) {
        context.go('/tenant-admin/settings');
      }
      return;
    }

    if (destination.enabled && destination.route != null) {
      context.go(destination.route!);
      return;
    }

    final message = destination.unavailableMessage;
    if (message != null) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(message)));
    }
  }
}

class _FooterDestinationButton extends StatelessWidget {
  const _FooterDestinationButton({
    required this.destination,
    required this.selected,
    required this.onTap,
  });

  final _FooterDestination destination;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final enabled =
        destination.enabled || destination.unavailableMessage != null;
    final color = selected
        ? TenantAdminColors.posHomeOrangeStart
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
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    selected ? destination.selectedIcon : destination.icon,
                    size: 20,
                    color: color,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    destination.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          fontSize: 10,
                          color: color,
                          fontWeight:
                              selected ? FontWeight.w800 : FontWeight.w600,
                        ),
                  ),
                ],
              ),
            ),
            if (selected)
              const Positioned(
                left: 22,
                right: 22,
                bottom: 0,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: TenantAdminColors.posHomeOrangeStart,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(3),
                    ),
                  ),
                  child: SizedBox(height: 4),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _FooterDestination {
  const _FooterDestination({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    this.route,
    this.enabled = false,
    this.unavailableMessage,
    this.isSettings = false,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final String? route;
  final bool enabled;
  final String? unavailableMessage;
  final bool isSettings;

  bool matches(String currentPath) {
    final destinationRoute = route;
    if (destinationRoute == null) {
      return false;
    }
    return currentPath == destinationRoute ||
        currentPath.startsWith('$destinationRoute/');
  }
}
