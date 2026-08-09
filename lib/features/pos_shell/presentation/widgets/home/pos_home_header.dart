import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/access/pos_access_codes.dart';
import '../../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';
import '../../../application/state/pos_home_dashboard_state.dart';
import 'pos_home_greeting.dart';
import 'pos_home_header_context.dart';

export 'pos_home_date_time_chip.dart' show PosHomeDateTimeChip;
export 'pos_home_greeting.dart' show PosHomeGreeting;
export 'pos_home_header_context.dart'
    show PosHomeHeaderContext, shouldShowTillChip;
export 'pos_home_notification_button.dart' show PosHomeNotificationButton;

class PosHomeHeader extends ConsumerWidget {
  const PosHomeHeader({
    super.key,
    required this.dashboard,
  });

  final PosHomeDashboardState dashboard;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final perms = dashboard.grantedPermissionKeys ?? const {};
    final userDisplayName = dashboard.fallbackUserDisplayName;
    final canViewNotifications =
        perms.contains(PosPermissionCodes.viewNotifications);
    final canViewTillSession =
        perms.contains(PosPermissionCodes.viewTillSession);
    final now = DateTime.now();

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact =
            constraints.maxWidth < TenantAdminBreakpoints.smallTablet;
        final greeting = PosHomeGreeting(
          userDisplayName: userDisplayName,
          statusMessage: dashboard.isTillOpen
              ? dashboard.statusMessage
              : (dashboard.tillDisplayLabel.isNotEmpty
                  ? '${dashboard.tillDisplayLabel} is not open.'
                  : dashboard.statusMessage),
        );
        final contextItems = PosHomeHeaderContext(
          now: now,
          dashboard: dashboard,
          showNotification: canViewNotifications,
          showTillStatus: canViewTillSession,
          notificationCount: dashboard.notificationCount,
        );

        if (isCompact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              greeting,
              const SizedBox(height: TenantAdminSpacing.lg),
              contextItems,
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: greeting),
            const SizedBox(width: TenantAdminSpacing.xl),
            Flexible(
              child: Align(
                alignment: Alignment.topRight,
                child: contextItems,
              ),
            ),
          ],
        );
      },
    );
  }
}
