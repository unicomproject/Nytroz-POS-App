import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';
import 'pos_shell_nav_item.dart';

class PosSidebar extends StatelessWidget {
  const PosSidebar({super.key});

  @override
  Widget build(BuildContext context) {
    final currentPath = GoRouterState.of(context).uri.path;

    return Container(
      width: 112,
      color: TenantAdminColors.navy,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 14, 10, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _BrandHeader(),
              const SizedBox(height: TenantAdminSpacing.lg),
              ..._items.map((item) {
                return PosShellNavItem(
                  icon: item.icon,
                  label: item.label,
                  selected: item.routePath == currentPath,
                  isEnabled: item.isEnabled,
                  onTap: () => _handleItemTap(context, item),
                );
              }),
              const Spacer(),
              const _UserPlaceholder(),
            ],
          ),
        ),
      ),
    );
  }

  void _handleItemTap(BuildContext context, _PosSidebarItem item) {
    if (item.isEnabled && item.routePath != null) {
      context.go(item.routePath!);
      return;
    }

    final message = item.unavailableMessage;
    if (message == null) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

class _PosSidebarItem {
  const _PosSidebarItem({
    required this.label,
    required this.icon,
    required this.isEnabled,
    this.routePath,
    this.unavailableMessage,
  });

  final String label;
  final IconData icon;
  final String? routePath;
  final bool isEnabled;
  final String? unavailableMessage;
}

const _items = [
  _PosSidebarItem(
    label: 'Home',
    icon: Icons.home_rounded,
    routePath: '/pos/home',
    isEnabled: true,
  ),
  _PosSidebarItem(
    label: 'New Sale',
    icon: Icons.add_shopping_cart_rounded,
    isEnabled: false,
    unavailableMessage: 'New Sale screen is not available yet.',
  ),
  _PosSidebarItem(
    label: 'Orders',
    icon: Icons.receipt_long_outlined,
    isEnabled: false,
    unavailableMessage: 'Orders screen is not available yet.',
  ),
  _PosSidebarItem(
    label: 'Customers',
    icon: Icons.people_outline_rounded,
    isEnabled: false,
    unavailableMessage: 'Customers screen is not available yet.',
  ),
  _PosSidebarItem(
    label: 'Return & Refund',
    icon: Icons.assignment_return_outlined,
    isEnabled: false,
    unavailableMessage: 'Return & Refund screen is not available yet.',
  ),
  _PosSidebarItem(
    label: 'Cash Drawer',
    icon: Icons.point_of_sale_outlined,
    isEnabled: false,
    unavailableMessage: 'Cash Drawer screen is not available yet.',
  ),
  _PosSidebarItem(
    label: 'More',
    icon: Icons.more_horiz_rounded,
    isEnabled: false,
    unavailableMessage: 'More options are not available yet.',
  ),
];

class _BrandHeader extends StatelessWidget {
  const _BrandHeader();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        _LogoPlaceholder(),
        SizedBox(height: TenantAdminSpacing.sm),
        Text(
          'SCS-TIX',
          maxLines: 1,
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.4,
          ),
        ),
      ],
    );
  }
}

class _LogoPlaceholder extends StatelessWidget {
  const _LogoPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: TenantAdminColors.info,
        borderRadius: BorderRadius.circular(TenantAdminRadius.lg),
      ),
      child: const Icon(
        Icons.local_activity_outlined,
        color: Colors.white,
        size: 24,
      ),
    );
  }
}

class _UserPlaceholder extends StatelessWidget {
  const _UserPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const Tooltip(
      message: 'User profile',
      child: SizedBox(
        height: 58,
        child: Stack(
          alignment: Alignment.center,
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: TenantAdminColors.navySoft,
              child: Icon(Icons.person_outline, color: Colors.white),
            ),
            Positioned(
              right: 16,
              bottom: 7,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: TenantAdminColors.success,
                  shape: BoxShape.circle,
                  border: Border.fromBorderSide(
                    BorderSide(color: TenantAdminColors.navy, width: 2),
                  ),
                ),
                child: SizedBox(width: 12, height: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
