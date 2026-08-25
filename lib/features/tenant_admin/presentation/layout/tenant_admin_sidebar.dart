import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../auth/presentation/providers/session_provider.dart';
import '../../domain/entities/tenant_admin_context.dart';
import '../../domain/entities/tenant_admin_menu_item.dart';
import '../../domain/services/tenant_admin_access_checker.dart';
import '../../inventory/presentation/navigation/inventory_sidebar_menu.dart';
import '../../products/presentation/navigation/products_sidebar_menu.dart';
import '../theme/tenant_admin_theme.dart';
import 'tenant_admin_sidebar_items.dart';

final tenantAdminSidebarCollapsedProvider = StateProvider<bool>((ref) => false);

/// Shared white/light Tenant Admin sidebar.
class TenantAdminSidebar extends ConsumerWidget {
  const TenantAdminSidebar({
    super.key,
    required this.items,
    required this.currentPath,
    this.tenantContext,
    this.accessChecker,
    this.selectedSidebarKey,
    this.compact = false,
  });

  final List<TenantAdminMenuItem> items;
  final String currentPath;
  final TenantAdminContext? tenantContext;
  final TenantAdminAccessChecker? accessChecker;
  final String? selectedSidebarKey;
  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final collapsed = ref.watch(tenantAdminSidebarCollapsedProvider);
    final width = collapsed
        ? TenantAdminSidebarTokens.compactWidth
        : (compact
            ? TenantAdminSidebarTokens.tabletWidth
            : TenantAdminSidebarTokens.width);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeInOut,
      width: width,
      decoration: const BoxDecoration(
        color: TenantAdminSidebarTokens.background,
        border: Border(
          right: BorderSide(color: TenantAdminSidebarTokens.border),
        ),
      ),
      child: SafeArea(
        top: false,
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(
                  collapsed ? 0 : 18, 18, collapsed ? 0 : 12, 8),
              child: Row(
                mainAxisAlignment: collapsed
                    ? MainAxisAlignment.center
                    : MainAxisAlignment.start,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: TenantAdminSidebarTokens.activeBackground,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.storefront_rounded,
                      color: TenantAdminSidebarTokens.activeForeground,
                      size: 20,
                    ),
                  ),
                  if (!collapsed) ...[
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Tenant Admin',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: TenantAdminSidebarTokens.foreground,
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            'Navigation',
                            style: TextStyle(
                              color: TenantAdminSidebarTokens.mutedForeground,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Align(
                alignment: collapsed ? Alignment.center : Alignment.centerRight,
                child: IconButton(
                  tooltip: collapsed ? 'Expand sidebar' : 'Collapse sidebar',
                  onPressed: () {
                    ref
                        .read(tenantAdminSidebarCollapsedProvider.notifier)
                        .state = !collapsed;
                  },
                  icon: Icon(
                    collapsed ? Icons.last_page : Icons.first_page,
                    color: const Color(0xFFB8C4D8),
                    size: 18,
                  ),
                ),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(0, 4, 0, 14),
                children: [
                  for (final item in items)
                    if (item.key == 'products')
                      ProductsSidebarMenu(
                        currentPath: currentPath,
                        collapsed: collapsed,
                        compact: compact || collapsed,
                      )
                    else if (item.key == 'inventory')
                      InventorySidebarMenu(
                        currentPath: currentPath,
                        collapsed: collapsed,
                        compact: compact || collapsed,
                        onNavigate: () {
                          // Optional callback if needed
                        },
                      )
                    else
                      TenantAdminSidebarItem(
                        icon: tenantAdminSidebarIconFor(item.iconKey),
                        label: item.label,
                        selected: _isSelected(item),
                        enabled: true,
                        visuallyDisabled: !item.isRouteAvailable,
                        collapsed: collapsed,
                        compact: compact || collapsed,
                        onTap: () => _onItemTap(context, item),
                      ),
                ],
              ),
            ),
            if (!collapsed)
              _SidebarFooter(
                tenantContext: tenantContext,
                accessChecker: accessChecker,
                onSignOut: () => _signOut(ref, context),
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

  void _onItemTap(BuildContext context, TenantAdminMenuItem item) {
    if (!item.isRouteAvailable || item.route.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(item.unavailableMessage)),
      );
      return;
    }
    context.go(item.route);
  }

  Future<void> _signOut(WidgetRef ref, BuildContext context) async {
    await ref.read(authSessionProvider.notifier).clear();
    if (context.mounted) {
      context.go('/tenant-login');
    }
  }
}

class _SidebarFooter extends StatelessWidget {
  const _SidebarFooter({
    required this.onSignOut,
    this.tenantContext,
    this.accessChecker,
  });

  final TenantAdminContext? tenantContext;
  final TenantAdminAccessChecker? accessChecker;
  final VoidCallback onSignOut;

  bool get _showTenantInfo {
    if (tenantContext == null || accessChecker == null) {
      return false;
    }

    return accessChecker!.canViewTenantContext() ||
        accessChecker!.canViewSubscription();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 14),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: TenantAdminColors.background,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: TenantAdminSidebarTokens.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_showTenantInfo) ...[
              if (accessChecker!.canViewTenantContext()) ...[
                Text(
                  tenantContext!.tenantName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: TenantAdminSidebarTokens.foreground,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  tenantContext!.userDisplayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: TenantAdminSidebarTokens.mutedForeground,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ],
            InkWell(
              onTap: onSignOut,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: TenantAdminColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: TenantAdminSidebarTokens.border),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.logout,
                      color: TenantAdminSidebarTokens.mutedForeground,
                      size: 18,
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Sign out',
                        style: TextStyle(
                          color: TenantAdminColors.bodyText,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

IconData tenantAdminSidebarIconFor(String iconKey) {
  switch (iconKey) {
    case 'dashboard':
      return Icons.dashboard_outlined;
    case 'store':
      return Icons.storefront_outlined;
    case 'till':
      return Icons.point_of_sale_outlined;
    case 'users':
      return Icons.people_outline;
    case 'online-store':
      return Icons.language_outlined;
    case 'shield':
      return Icons.security_outlined;
    case 'hardware':
      return Icons.devices_other_outlined;
    case 'products':
      return Icons.inventory_2_outlined;
    case 'inventory':
      return Icons.warehouse_outlined;
    case 'reports':
      return Icons.bar_chart_outlined;
    case 'settings':
      return Icons.settings_outlined;
    default:
      return Icons.circle_outlined;
  }
}
