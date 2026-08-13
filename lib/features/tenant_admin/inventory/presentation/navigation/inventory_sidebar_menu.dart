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
        final canViewDashboard = accessChecker
            .can(TenantAdminPermissionCodes.tenantStockDashboardView);
        final canViewCurrentStock =
            accessChecker.can(TenantAdminPermissionCodes.tenantStockView);

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
                  ref.read(inventorySidebarExpandedProvider.notifier).state =
                      true;
                } else if (!collapsed && expanded) {
                  ref.read(inventorySidebarExpandedProvider.notifier).state =
                      false;
                }
              },
            ),
            if (!collapsed)
              AnimatedSize(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeInOut,
                alignment: Alignment.topCenter,
                child: expanded
                    ? Column(
                        children: [
                          if (canViewDashboard)
                            _InventorySidebarChild(
                              label: 'Dashboard',
                              route: '/tenant-admin/stock/dashboard',
                              currentPath: currentPath,
                              compact: compact,
                              onNavigate: onNavigate,
                            ),
                          if (canViewCurrentStock)
                            _InventorySidebarChild(
                              label: 'Current Stock',
                              route: '/tenant-admin/stock/current',
                              currentPath: currentPath,
                              compact: compact,
                              onNavigate: onNavigate,
                            ),
                          // Placeholder for Stock Adjustment
                          _InventorySidebarChild(
                            label: 'Stock Adjustment',
                            route: '/tenant-admin/stock/adjust',
                            currentPath: currentPath,
                            compact: compact,
                            onNavigate: onNavigate,
                            enabled: false,
                          ),
                          if (accessChecker.canAccessOpeningStockPage())
                            _InventorySidebarChild(
                              label: 'Opening Stock',
                              route: '/tenant-admin/stock/opening',
                              currentPath: currentPath,
                              compact: compact,
                              onNavigate: onNavigate,
                            ),
                          // Placeholder for Stock Transfer
                          _InventorySidebarChild(
                            label: 'Stock Transfer',
                            route: '/tenant-admin/stock/transfer',
                            currentPath: currentPath,
                            compact: compact,
                            onNavigate: onNavigate,
                            enabled: false,
                          ),
                        ],
                      )
                    : const SizedBox.shrink(),
              ),
          ],
        );
      },
    );
  }
}

class _InventorySidebarChild extends StatelessWidget {
  const _InventorySidebarChild({
    required this.label,
    required this.route,
    required this.currentPath,
    required this.compact,
    this.onNavigate,
    this.enabled = true,
  });

  final String label;
  final String route;
  final String currentPath;
  final bool compact;
  final VoidCallback? onNavigate;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    // Determine active state manually since this is a local helper
    final isActive = currentPath == route || currentPath.startsWith('$route/');

    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: enabled
              ? () {
                  context.go(route);
                  onNavigate?.call();
                }
              : null,
          child: Container(
            margin: const EdgeInsets.only(right: 16),
            padding: EdgeInsets.only(
              left: compact ? 34 : 42,
              right: 12,
              top: compact ? 8 : 10,
              bottom: compact ? 8 : 10,
            ),
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isActive
                        ? const Color(0xFF2563EB) // Primary color approximation
                        : const Color(0xFF64748B), // Muted color
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: isActive
                          ? const Color(0xFF1E293B)
                          : const Color(0xFF64748B),
                      fontSize: compact ? 12 : 12.5,
                      fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ),
                if (!enabled)
                  const Icon(
                    Icons.lock_outline,
                    size: 12,
                    color: Color(0xFF94A3B8),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
