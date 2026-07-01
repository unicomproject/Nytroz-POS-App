import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/access/pos_access_codes.dart';
import '../../../../auth/presentation/providers/session_provider.dart';
import '../../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';

class PosMobileTopBar extends ConsumerWidget implements PreferredSizeWidget {
  const PosMobileTopBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // and till session chip (till.session.view) when mobile shell top bar supports them.
    final session = ref.watch(authSessionProvider);
    final canViewNotifications =
        session?.hasPermission(PosPermissionCodes.viewNotifications) == true;

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
            'NytrozPOS',
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
      actions: [
        if (canViewNotifications)
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
