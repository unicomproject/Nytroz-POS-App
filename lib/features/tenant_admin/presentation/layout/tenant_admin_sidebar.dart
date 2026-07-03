import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../auth/presentation/providers/session_provider.dart';
import '../../domain/entities/tenant_admin_context.dart';
import '../../domain/entities/tenant_admin_menu_item.dart';
import '../../domain/services/tenant_admin_access_checker.dart';

class TenantAdminSidebar extends ConsumerStatefulWidget {
  const TenantAdminSidebar({
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
  ConsumerState<TenantAdminSidebar> createState() => _TenantAdminSidebarState();
}

class _TenantAdminSidebarState extends ConsumerState<TenantAdminSidebar> {
  // Store expanded state of submenus. Initially, expand active submenus based on route.
  final Map<String, bool> _expandedMenus = {
    'products': true,
    'stock': true,
  };

  @override
  void initState() {
    super.initState();
    // Auto expand based on current path
    if (widget.currentPath.contains('/products')) {
      _expandedMenus['products'] = true;
    }
    if (widget.currentPath.contains('/stock')) {
      _expandedMenus['stock'] = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Custom submenus config
    final Map<String, List<Map<String, String>>> subMenus = {
      'products': [
        {'label': 'Product List', 'route': '/tenant-admin/products'},
        {'label': 'Add Product', 'route': '/tenant-admin/products/add'},
        {'label': 'Categories', 'route': '/tenant-admin/products/categories'},
        {'label': 'Brands', 'route': '/tenant-admin/products/brands'},
      ],
      'stock': [
        {'label': 'Stock In', 'route': '/tenant-admin/stock/in'},
        {'label': 'Current Stock', 'route': '/tenant-admin/stock/current'},
        {'label': 'Stock Out', 'route': '/tenant-admin/stock/out'},
        {'label': 'Transfers', 'route': '/tenant-admin/stock/transfers'},
      ],
    };

    return Container(
      width: 240,
      decoration: const BoxDecoration(
        color: Color(0xFF0B192C), // Sleek Dark Premium Navy matching the screenshot
        border: Border(
          right: BorderSide(
            color: Color(0xFF1E293B),
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Logo Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2563EB), // Vibrant Blue Logo Background
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF2563EB).withOpacity(0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: const Text(
                      'N',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Nytroz POS',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            // Menu Items List
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                children: [
                  for (final item in widget.items) ...[
                    if (subMenus.containsKey(item.key)) ...[
                      // Expandable main item
                      _buildExpandableGroup(
                        item: item,
                        subItems: _visibleSubMenuItems(
                          subMenus[item.key]!,
                          widget.accessChecker,
                        ),
                      ),
                    ] else ...[
                      // Regular item
                      _SidebarNavItem(
                        icon: _iconFor(item.iconKey),
                        label: item.label == 'Stock' ? 'Inventory' : item.label,
                        selected: widget.currentPath == item.route ||
                            (widget.currentPath.startsWith('${item.route}/') &&
                                !widget.currentPath.contains('/products') &&
                                !widget.currentPath.contains('/stock')),
                        onTap: () => context.go(item.route),
                      ),
                    ],
                  ],
                  // Extra placeholder items to match the screenshot if not present
                  if (!widget.items.any((item) => item.key == 'purchases'))
                    _SidebarNavItem(
                      icon: Icons.shopping_basket_outlined,
                      label: 'Purchases',
                      selected: false,
                      onTap: () {},
                    ),
                  if (!widget.items.any((item) => item.key == 'sales'))
                    _SidebarNavItem(
                      icon: Icons.point_of_sale_outlined,
                      label: 'Sales',
                      selected: false,
                      onTap: () {},
                    ),
                  if (!widget.items.any((item) => item.key == 'integrations'))
                    _SidebarNavItem(
                      icon: Icons.integration_instructions_outlined,
                      label: 'Integrations',
                      selected: false,
                      onTap: () {},
                    ),
                ],
              ),
            ),
            // User Session / Sign Out Footer
            _SidebarFooter(
              tenantContext: widget.tenantContext,
              accessChecker: widget.accessChecker,
              onSignOut: () => _signOut(ref, context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpandableGroup({
    required TenantAdminMenuItem item,
    required List<Map<String, String>> subItems,
  }) {
    final isExpanded = _expandedMenus[item.key] ?? false;
    final hasActiveChild = subItems.any((sub) => widget.currentPath == sub['route']);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Main Group Header Item
        _SidebarNavItem(
          icon: _iconFor(item.iconKey),
          label: item.label == 'Stock' ? 'Inventory' : item.label,
          selected: false, // Don't highlight main parent if children exist
          hasDropdown: true,
          isDropdownExpanded: isExpanded,
          onTap: () {
            setState(() {
              _expandedMenus[item.key] = !isExpanded;
            });
          },
        ),
        // Submenu child items
        if (isExpanded)
          Padding(
            padding: const EdgeInsets.only(left: 24, bottom: 4),
            child: Column(
              children: subItems.map((sub) {
                final isChildSelected = widget.currentPath == sub['route'];
                return _SidebarSubNavItem(
                  label: sub['label']!,
                  selected: isChildSelected,
                  onTap: () {
                    final route = sub['route']!;
                    if (_isImplementedSubRoute(route)) {
                      context.go(route);
                    } else {
                      context.go('/tenant-admin/products');
                    }
                  },
                );
              }).toList(),
            ),
          ),
      ],
    );
  }

  List<Map<String, String>> _visibleSubMenuItems(
    List<Map<String, String>> subItems,
    TenantAdminAccessChecker? accessChecker,
  ) {
    if (accessChecker == null) {
      return subItems;
    }

    return subItems
        .where((sub) => _canShowSubMenuRoute(accessChecker, sub['route']!))
        .toList(growable: false);
  }

  bool _canShowSubMenuRoute(
    TenantAdminAccessChecker accessChecker,
    String route,
  ) {
    switch (route) {
      case '/tenant-admin/stock/in':
        return accessChecker.canAccessAddStockPage();
      case '/tenant-admin/stock/current':
        return accessChecker.canAccessCurrentStockPage();
      case '/tenant-admin/products':
        return accessChecker.canAccessProductModule();
      case '/tenant-admin/products/add':
        return accessChecker.canCreateProduct();
      default:
        return _isImplementedSubRoute(route);
    }
  }

  bool _isImplementedSubRoute(String route) {
    return route == '/tenant-admin/products' ||
        route == '/tenant-admin/products/add' ||
        route == '/tenant-admin/stock/in' ||
        route == '/tenant-admin/stock/current';
  }

  Future<void> _signOut(WidgetRef ref, BuildContext context) async {
    await ref.read(authSessionProvider.notifier).clear();
    if (context.mounted) {
      context.go('/tenant-login');
    }
  }
}

class _SidebarNavItem extends StatelessWidget {
  const _SidebarNavItem({
    required this.icon,
    required this.label,
    required this.selected,
    this.hasDropdown = false,
    this.isDropdownExpanded = false,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final bool hasDropdown;
  final bool isDropdownExpanded;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: selected
                  ? const Color(0xFF1E293B) // Slate background when selected
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: selected
                      ? Colors.white
                      : const Color(0xFF94A3B8), // Cool slate-400
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: selected ? Colors.white : const Color(0xFFE2E8F0),
                      fontSize: 13,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                    ),
                  ),
                ),
                if (hasDropdown)
                  Icon(
                    isDropdownExpanded
                        ? Icons.keyboard_arrow_down_rounded
                        : Icons.keyboard_arrow_right_rounded,
                    size: 16,
                    color: const Color(0xFF64748B),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SidebarSubNavItem extends StatelessWidget {
  const _SidebarSubNavItem({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: selected
                  ? const Color(0xFF1E293B).withOpacity(0.6)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: selected ? Colors.white : const Color(0xFF94A3B8),
                      fontSize: 12,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
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

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B).withOpacity(0.4),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF1E293B)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (tenantContext != null) ...[
              Text(
                tenantContext!.tenantName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                tenantContext!.userDisplayName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: 8),
            ],
            InkWell(
              onTap: onSignOut,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.logout, color: Colors.white70, size: 16),
                    SizedBox(width: 8),
                    Text(
                      'Sign out',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
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

IconData _iconFor(String iconKey) {
  switch (iconKey) {
    case 'dashboard':
      return Icons.dashboard_outlined;
    case 'store':
      return Icons.storefront_outlined;
    case 'till':
      return Icons.point_of_sale_outlined;
    case 'users':
      return Icons.people_outline;
    case 'shield':
      return Icons.verified_user_outlined;
    case 'products':
      return Icons.inventory_2_outlined;
    case 'inventory':
    case 'stock':
      return Icons.storage_outlined;
    case 'reports':
      return Icons.bar_chart_outlined;
    case 'billing':
      return Icons.receipt_long_outlined;
    case 'settings':
      return Icons.settings_outlined;
    case 'activity':
      return Icons.history_outlined;
    case 'help':
    case 'support':
      return Icons.help_outline;
    default:
      return Icons.fiber_manual_record;
  }
}
