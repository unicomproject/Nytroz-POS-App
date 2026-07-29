import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../auth/presentation/providers/session_provider.dart';
import '../../domain/entities/tenant_admin_context.dart';
import '../../domain/entities/tenant_admin_menu_item.dart';
import '../../domain/services/tenant_admin_access_checker.dart';
import '../../products/presentation/navigation/products_sidebar_menu.dart';

class TenantAdminNavigationDrawer extends ConsumerWidget {
  const TenantAdminNavigationDrawer({
    super.key,
    required this.items,
    required this.currentPath,
    this.tenantContext,
    this.accessChecker,
  });

  final List<TenantAdminMenuItem> items;
  final String currentPath;
  final TenantAdminContext? tenantContext;
  final TenantAdminAccessChecker? accessChecker;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Drawer(
      backgroundColor: const Color(0xFF06162D),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 18, 18, 12),
              child: Text(
                'Nytroz POS',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(14, 2, 14, 14),
                children: [
                  for (final item in items)
                    if (item.key == 'products')
                      ProductsSidebarMenu(
                        currentPath: currentPath,
                        compact: true,
                        onNavigate: () => Navigator.of(context).pop(),
                      )
                    else
                      _DrawerNavItem(
                        icon: _iconFor(item.iconKey),
                        label: item.label,
                        selected: currentPath == item.route ||
                            currentPath.startsWith('${item.route}/'),
                        onTap: () {
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
}

class _DrawerNavItem extends StatelessWidget {
  const _DrawerNavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: Icon(
          icon,
          color: selected ? Colors.white : const Color(0xFFB8C4D8),
        ),
        title: Text(
          label,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: selected ? Colors.white : const Color(0xFFD8E0EE),
            fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
        selected: selected,
        selectedTileColor: const Color(0xFF3F2BFF),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        onTap: onTap,
      ),
    );
  }
}

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
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              tenantContext!.userDisplayName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Color(0xFFB8C4D8), fontSize: 12),
            ),
            const SizedBox(height: 12),
          ],
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.white70),
            title: const Text(
              'Sign out',
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
            ),
            onTap: onSignOut,
          ),
        ],
      ),
    );
  }
}

IconData _iconFor(String iconKey) {
  switch (iconKey) {
    case 'dashboard':
      return Icons.dashboard;
    case 'store':
      return Icons.store;
    case 'till':
      return Icons.payment;
    case 'users':
      return Icons.people;
    case 'shield':
      return Icons.security;
    case 'products':
      return Icons.inventory_2_outlined;
    case 'inventory':
      return Icons.storage;
    case 'reports':
      return Icons.insert_chart;
    case 'billing':
      return Icons.receipt;
    case 'settings':
      return Icons.settings;
    case 'activity':
      return Icons.history;
    default:
      return Icons.fiber_manual_record;
  }
}
