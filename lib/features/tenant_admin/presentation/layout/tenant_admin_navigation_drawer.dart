import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../auth/presentation/providers/session_provider.dart';
import '../../domain/entities/tenant_admin_context.dart';
import '../../domain/entities/tenant_admin_menu_item.dart';
import '../../domain/services/tenant_admin_access_checker.dart';
import '../../products/presentation/navigation/products_sidebar_menu.dart';
import '../theme/tenant_admin_theme.dart';
import 'tenant_admin_sidebar.dart';
import 'tenant_admin_sidebar_items.dart';

/// Mobile drawer that mirrors the white sidebar menu order.
class TenantAdminNavigationDrawer extends ConsumerWidget {
  const TenantAdminNavigationDrawer({
    super.key,
    required this.items,
    required this.currentPath,
    this.tenantContext,
    this.accessChecker,
    this.selectedSidebarKey,
  });

  final List<TenantAdminMenuItem> items;
  final String currentPath;
  final TenantAdminContext? tenantContext;
  final TenantAdminAccessChecker? accessChecker;
  final String? selectedSidebarKey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Drawer(
      backgroundColor: TenantAdminSidebarTokens.background,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 18, 18, 12),
              child: Text(
                'Tenant Admin',
                style: TextStyle(
                  color: TenantAdminSidebarTokens.foreground,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(12, 2, 12, 14),
                children: [
                  for (final item in items)
                    if (item.key == 'products')
                      ProductsSidebarMenu(
                        currentPath: currentPath,
                        compact: true,
                        onNavigate: () => Navigator.of(context).pop(),
                      )
                    else
                      TenantAdminSidebarItem(
                        icon: tenantAdminSidebarIconFor(item.iconKey),
                        label: item.label,
                        selected: _isSelected(item),
                        enabled: true,
                        visuallyDisabled: !item.isRouteAvailable,
                        compact: true,
                        onTap: () {
                          if (!item.isRouteAvailable || item.route.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(item.unavailableMessage)),
                            );
                            return;
                          }
                          Navigator.of(context).pop();
                          context.go(item.route);
                        },
                      ),
                ],
              ),
            ),
            _DrawerFooter(
              tenantContext: tenantContext,
              accessChecker: accessChecker,
              onSignOut: () async {
                await ref.read(authSessionProvider.notifier).clear();
                if (context.mounted) {
                  Navigator.of(context).pop();
                  context.go('/tenant-login');
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  bool _isSelected(TenantAdminMenuItem item) {
    if (selectedSidebarKey != null && selectedSidebarKey == item.key) {
      return true;
    }
    if (!item.isRouteAvailable || item.route.isEmpty) {
      return false;
    }
    if (item.key == 'inventory') {
      return currentPath == '/tenant-admin/stock' ||
          currentPath.startsWith('/tenant-admin/stock/');
    }
    return currentPath == item.route ||
        currentPath.startsWith('${item.route}/');
  }
}

/// Alias for catalogue naming.
typedef TenantAdminSidebarMobileDrawer = TenantAdminNavigationDrawer;

class _DrawerFooter extends StatelessWidget {
  const _DrawerFooter({
    required this.onSignOut,
    this.tenantContext,
    this.accessChecker,
  });

  final TenantAdminContext? tenantContext;
  final TenantAdminAccessChecker? accessChecker;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (tenantContext != null) ...[
            Text(
              tenantContext!.tenantName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: TenantAdminSidebarTokens.foreground,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
          ],
          OutlinedButton.icon(
            onPressed: onSignOut,
            icon: const Icon(Icons.logout),
            label: const Text('Sign out'),
          ),
        ],
      ),
    );
  }
}
