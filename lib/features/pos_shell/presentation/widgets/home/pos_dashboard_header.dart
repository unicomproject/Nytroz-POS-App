import 'package:flutter/material.dart';

import '../../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';
import '../../../application/state/pos_home_dashboard_state.dart';
import 'pos_branding.dart';
import 'pos_operational_context_card.dart';
import 'pos_session_status_chip.dart';

class PosDashboardHeader extends StatelessWidget {
  const PosDashboardHeader({super.key, required this.dashboard});

  final PosHomeDashboardState dashboard;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final brandingAndStatus = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            PosBranding(dashboard: dashboard),
            const SizedBox(width: TenantAdminSpacing.xl),
            PosSessionStatusChip(dashboard: dashboard),
          ],
        );
        final operationalContext = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 280,
              child: PosOperationalContextCard(
                icon: Icons.location_on_outlined,
                label: 'Outlet',
                value: dashboard.outletName,
              ),
            ),
            const SizedBox(width: TenantAdminSpacing.lg),
            SizedBox(
              width: 280,
              child: PosOperationalContextCard(
                icon: Icons.point_of_sale_outlined,
                label: 'Till',
                value: dashboard.tillLabel,
              ),
            ),
            const SizedBox(width: TenantAdminSpacing.lg),
            if (dashboard.notificationCount >= 0)
              Badge.count(
                count: dashboard.notificationCount,
                isLabelVisible: dashboard.notificationCount > 0,
                child: const SizedBox.square(
                  dimension: 56,
                  child: Icon(
                    Icons.notifications_none_rounded,
                    color: TenantAdminColors.surface,
                    size: 28,
                  ),
                ),
              ),
          ],
        );

        if (constraints.maxWidth < 1180) {
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                brandingAndStatus,
                const SizedBox(width: TenantAdminSpacing.xxl),
                operationalContext,
              ],
            ),
          );
        }
        return Row(
          children: [
            brandingAndStatus,
            const Spacer(),
            operationalContext,
          ],
        );
      },
    );
  }
}
