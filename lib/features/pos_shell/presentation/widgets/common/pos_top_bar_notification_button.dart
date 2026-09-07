import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nytroz_pos/core/access/permission_access_providers.dart';
import 'package:nytroz_pos/features/tenant_admin/presentation/theme/tenant_admin_theme.dart';
import 'package:nytroz_pos/features/pos_shell/presentation/providers/pos_notifications_provider.dart';
import 'pos_notifications_dialog.dart';
import 'pos_shell_top_bar_visibility.dart';

class PosTopBarNotificationButton extends ConsumerWidget {
  const PosTopBarNotificationButton({super.key, this.dark = false});

  final bool dark;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final permissions = ref.watch(effectivePermissionSetProvider);
    if (!PosShellTopBarVisibility.canShowNotificationBell(permissions)) {
      return const SizedBox.shrink();
    }

    final canOpenPanel =
        PosShellTopBarVisibility.canShowNotificationPanel(permissions);
    final canShowUnread =
        PosShellTopBarVisibility.canShowUnreadCount(permissions);
    final count = ref.watch(posNotificationsProvider).asData?.value.unreadCount ?? 0;
    final showBadge = canShowUnread && count > 0;

    return Padding(
      padding: const EdgeInsets.only(left: TenantAdminSpacing.sm),
      child: Tooltip(
        message: 'Notifications',
        child: SizedBox.square(
          dimension: 44,
          child: Material(
            color: dark
                ? TenantAdminColors.posHomeDarkSurface
                : TenantAdminColors.background,
            borderRadius: BorderRadius.circular(22),
            child: InkWell(
              onTap: canOpenPanel
                  ? () => showPosNotificationsDialog(context)
                  : null,
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
                    if (showBadge)
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
      ),
    );
  }
}
