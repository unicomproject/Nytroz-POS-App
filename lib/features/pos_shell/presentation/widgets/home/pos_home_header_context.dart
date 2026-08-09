import 'package:flutter/material.dart';

import '../../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';
import '../../../application/state/pos_home_dashboard_state.dart';
import 'pos_home_date_time_chip.dart';
import 'pos_home_notification_button.dart';
import 'pos_status_chip.dart';

class PosHomeHeaderContext extends StatelessWidget {
  const PosHomeHeaderContext({
    super.key,
    required this.now,
    required this.dashboard,
    required this.showNotification,
    required this.showTillStatus,
    required this.notificationCount,
  });

  final DateTime now;
  final PosHomeDashboardState dashboard;
  final bool showNotification;
  final bool showTillStatus;
  final int notificationCount;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: TenantAdminSpacing.sm,
      runSpacing: TenantAdminSpacing.sm,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        if (showNotification)
          PosHomeNotificationButton(
            // Presentation-only until a notification module exists.
            onPressed: () {},
            notificationCount: notificationCount,
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
