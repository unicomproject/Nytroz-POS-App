import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/access/permission_gate.dart';
import '../../../../../core/access/pos_access_codes.dart';
import '../../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';
import 'pos_top_bar_notification_button.dart';

class PosMobileTopBar extends ConsumerWidget implements PreferredSizeWidget {
  const PosMobileTopBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppBar(
      automaticallyImplyLeading: false,
      backgroundColor: TenantAdminColors.navy,
      foregroundColor: Colors.white,
      elevation: 0,
      titleSpacing: TenantAdminSpacing.lg,
      title: PermissionGate(
        permission: PosPermissionCodes.shellTopbarBrand,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/images/logo.png',
              width: 24,
              height: 24,
              fit: BoxFit.contain,
            ),
            const SizedBox(width: TenantAdminSpacing.sm),
            Text(
              'OneVerz POS',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ],
        ),
      ),
      actions: [
        const PosTopBarNotificationButton(dark: true),
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
