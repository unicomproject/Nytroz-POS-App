import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nytroz_pos/core/access/pos_access_codes.dart';
import 'package:nytroz_pos/features/tenant_admin/presentation/theme/tenant_admin_theme.dart';
import 'package:nytroz_pos/features/auth/presentation/providers/session_provider.dart';
import 'package:nytroz_pos/features/pos_shell/presentation/providers/pos_home_dashboard_provider.dart';

class PosTopBarNotificationButton extends ConsumerWidget {
  const PosTopBarNotificationButton({super.key, this.dark = false});

  final bool dark;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(authSessionProvider);
    if (session?.hasPermission(PosPermissionCodes.viewNotifications) != true) {
      return const SizedBox.shrink();
    }

    final dashboard = ref.watch(posHomeDashboardProvider).asData?.value;
    final count = dashboard?.notificationCount ?? 0;

    return Tooltip(
      message: 'Notifications',
      child: SizedBox.square(
        dimension: 44,
        child: Material(
          color: dark
              ? TenantAdminColors.posHomeDarkSurface
              : TenantAdminColors.background,
          borderRadius: BorderRadius.circular(22),
          child: InkWell(
            onTap: () {},
            borderRadius: BorderRadius.circular(22),
            child: Center(
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(
                    Icons.notifications_none_rounded,
                    color: dark
                        ? TenantAdminColors.surface
                        : TenantAdminColors.bodyText,
                    size: 24,
                  ),
                  if (count > 0)
                    Positioned(
                      right: -3,
                      top: -3,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                          color: Color(0xFFFF2D1A),
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          '$count',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
