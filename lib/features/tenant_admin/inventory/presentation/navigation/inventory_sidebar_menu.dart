import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/access/tenant_admin_access_codes.dart';
import '../../../presentation/providers/tenant_admin_access_provider.dart';
import 'inventory_sidebar_parent_item.dart';

final inventorySidebarExpandedProvider = StateProvider<bool>((ref) => false);

class InventorySidebarMenu extends ConsumerWidget {
  const InventorySidebarMenu({
    super.key,
    required this.currentPath,
    this.collapsed = false,
    this.compact = false,
    this.onNavigate,
  });

  final String currentPath;
  final bool collapsed;
  final bool compact;
  final VoidCallback? onNavigate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accessState = ref.watch(tenantAdminAccessCheckerProvider);
    final expanded = ref.watch(inventorySidebarExpandedProvider);

    return accessState.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (accessChecker) {
        final canViewDashboard = accessChecker.can(TenantAdminPermissionCodes.tenantStockDashboardView);
        final canViewCurrentStock = accessChecker.can(TenantAdminPermissionCodes.tenantStockView);

        final hasVisibleChildren = canViewDashboard || canViewCurrentStock;

        if (!hasVisibleChildren) {
          return const SizedBox.shrink();
        }

        final parentSelected = currentPath.startsWith('/tenant-admin/stock');

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            InventorySidebarParentItem(
              label: 'Inventory',
              icon: Icons.inventory_2_outlined,
              selected: parentSelected,
              expanded: expanded,
              collapsed: collapsed,
              compact: compact,
              onToggle: () {
                if (!collapsed && !expanded) {
                  ref.read(inventorySidebarExpandedProvider.notifier).state = true;
                }
                if (canViewDashboard) {
                  context.go('/tenant-admin/stock/dashboard');
                } else if (canViewCurrentStock) {
                  context.go('/tenant-admin/stock/current');
                }
                onNavigate?.call();
              },
            ),
          ],
        );
      },
    );
  }
}
