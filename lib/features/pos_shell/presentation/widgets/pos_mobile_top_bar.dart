import 'package:flutter/material.dart';

import '../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';

class PosMobileTopBar extends StatelessWidget implements PreferredSizeWidget {
  const PosMobileTopBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      automaticallyImplyLeading: false,
      backgroundColor: TenantAdminColors.navy,
      foregroundColor: Colors.white,
      elevation: 0,
      titleSpacing: TenantAdminSpacing.lg,
      title: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.local_activity_outlined, size: 24),
          SizedBox(width: TenantAdminSpacing.sm),
          Text(
            'SCS-TIX',
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          onPressed: () {},
          tooltip: 'Notifications',
          icon: const _NotificationIcon(),
          constraints: const BoxConstraints(minWidth: 56, minHeight: 56),
        ),
        IconButton(
          onPressed: () {},
          tooltip: 'Menu',
          icon: const Icon(Icons.menu_rounded),
          iconSize: 30,
          constraints: const BoxConstraints(minWidth: 56, minHeight: 56),
        ),
        const SizedBox(width: TenantAdminSpacing.xs),
      ],
    );
  }
}

class _NotificationIcon extends StatelessWidget {
  const _NotificationIcon();

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        const Icon(Icons.notifications_none_rounded, size: 27),
        Positioned(
          top: -2,
          right: -2,
          child: Container(
            width: 9,
            height: 9,
            decoration: const BoxDecoration(
              color: TenantAdminColors.danger,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ],
    );
  }
}
