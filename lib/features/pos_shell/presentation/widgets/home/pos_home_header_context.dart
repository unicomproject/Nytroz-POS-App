import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/access/permission_access_providers.dart';
import '../../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';
import '../../../application/state/pos_home_dashboard_state.dart';
import '../../providers/pos_notifications_provider.dart';
import '../common/pos_notifications_dialog.dart';
import '../common/pos_shell_top_bar_visibility.dart';
import 'pos_home_date_time_chip.dart';
import 'pos_home_notification_button.dart';
import 'pos_status_chip.dart';

class PosHomeHeaderContext extends ConsumerWidget {
  const PosHomeHeaderContext({
    super.key,
    required this.now,
    required this.dashboard,
    required this.showTillStatus,
  });

  final DateTime now;
  final PosHomeDashboardState dashboard;
  final bool showTillStatus;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final permissions = ref.watch(effectivePermissionSetProvider);
    final showBell =
        PosShellTopBarVisibility.canShowNotificationBell(permissions);
    final canOpenPanel =
        PosShellTopBarVisibility.canShowNotificationPanel(permissions);
    final canShowUnread =
        PosShellTopBarVisibility.canShowUnreadCount(permissions);
    final notificationCount =
        ref.watch(posNotificationsProvider).asData?.value.unreadCount ?? 0;

    return Wrap(
      spacing: TenantAdminSpacing.sm,
      runSpacing: TenantAdminSpacing.sm,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        if (showBell)
          PosHomeNotificationButton(
            onPressed: canOpenPanel
                ? () => showPosNotificationsDialog(context)
                : null,
            notificationCount: canShowUnread ? notificationCount : 0,
            showUnreadBadge: canShowUnread,
          ),
        if (showTillStatus && shouldShowTillChip(dashboard))
          PosStatusChip(
            displayLabel: dashboard.tillDisplayLabel,
            tillLabel: dashboard.tillLabel,
            statusLabel: dashboard.tillStatusLabel,
            isOpen: dashboard.isTillOpen,
          ),
        PosHomeDateTimeChip(
          serverNowUtc: dashboard.serverNowUtc,
          serverTimeReceivedAt: dashboard.serverTimeReceivedAt,
          outletTimezone: dashboard.outletTimezone,
          fallbackNow: now,
        ),
      ],
    );
  }
}

bool shouldShowTillChip(PosHomeDashboardState dashboard) {
  if (dashboard.hasOpenTillSession == true || dashboard.isTillOpen) {
    return true;
  }

  return dashboard.tillDisplayLabel.trim().isNotEmpty;
}
