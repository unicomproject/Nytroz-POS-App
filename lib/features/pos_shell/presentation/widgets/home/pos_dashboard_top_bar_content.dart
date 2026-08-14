import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nytroz_pos/features/tenant_admin/presentation/theme/tenant_admin_theme.dart';
import 'package:nytroz_pos/features/pos_shell/presentation/providers/pos_home_dashboard_provider.dart';
import 'pos_operational_context_card.dart';
import 'pos_session_status_chip.dart';

class PosDashboardTopBarContent extends ConsumerWidget {
  const PosDashboardTopBarContent({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardAsync = ref.watch(posHomeDashboardProvider);

    final dashboard = dashboardAsync.maybeWhen(
      data: (data) => data,
      orElse: () => buildPosHomeShellDashboard(
        ref,
        homeError: dashboardAsync.error,
      ),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final statusChip = PosSessionStatusChip(dashboard: dashboard);
        final operationalContext = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth:
                    constraints.maxWidth < TenantAdminBreakpoints.smallTablet
                        ? 180
                        : 240,
              ),
              child: PosOperationalContextCard(
                icon: Icons.location_on_outlined,
                label: 'Outlet',
                value: dashboard.outletName,
              ),
            ),
            const SizedBox(width: TenantAdminSpacing.lg),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth:
                    constraints.maxWidth < TenantAdminBreakpoints.smallTablet
                        ? 180
                        : 240,
              ),
              child: PosOperationalContextCard(
                icon: Icons.point_of_sale_outlined,
                label: 'Till',
                value: dashboard.tillLabel,
              ),
            ),
          ],
        );

        if (constraints.maxWidth < TenantAdminBreakpoints.tablet) {
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                statusChip,
                const SizedBox(width: TenantAdminSpacing.xl),
                operationalContext,
              ],
            ),
          );
        }

        return Row(
          children: [
            statusChip,
            const Spacer(),
            operationalContext,
          ],
        );
      },
    );
  }
}
