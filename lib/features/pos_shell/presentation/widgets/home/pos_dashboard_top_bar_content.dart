import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nytroz_pos/core/access/permission_access_providers.dart';
import 'package:nytroz_pos/features/tenant_admin/presentation/theme/tenant_admin_theme.dart';
import 'package:nytroz_pos/features/pos_shell/presentation/providers/pos_home_dashboard_provider.dart';
import '../common/pos_shell_top_bar_visibility.dart';
import 'pos_operational_context_card.dart';
import 'pos_session_status_chip.dart';

class PosDashboardTopBarContent extends ConsumerWidget {
  const PosDashboardTopBarContent({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final permissions = ref.watch(effectivePermissionSetProvider);
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
        final maxCardWidth =
            constraints.maxWidth < TenantAdminBreakpoints.smallTablet
                ? 180.0
                : 240.0;

        final items = <Widget>[
          if (PosShellTopBarVisibility.canShowSessionStatus(permissions))
            PosSessionStatusChip(dashboard: dashboard),
          if (PosShellTopBarVisibility.canShowOutlet(permissions))
            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxCardWidth),
              child: PosOperationalContextCard(
                icon: Icons.location_on_outlined,
                label: 'Outlet',
                value: dashboard.outletName,
              ),
            ),
          if (PosShellTopBarVisibility.canShowTill(permissions))
            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxCardWidth),
              child: PosOperationalContextCard(
                icon: Icons.point_of_sale_outlined,
                label: 'Till',
                value: dashboard.tillLabel,
              ),
            ),
        ];

        if (items.isEmpty) {
          return const SizedBox.shrink();
        }

        Widget spacedRow(List<Widget> children) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < children.length; i++) ...[
                if (i > 0) const SizedBox(width: TenantAdminSpacing.lg),
                children[i],
              ],
            ],
          );
        }

        if (constraints.maxWidth < TenantAdminBreakpoints.tablet) {
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: spacedRow(items),
          );
        }

        final leading = PosShellTopBarVisibility.canShowSessionStatus(
                permissions)
            ? items.first
            : null;
        final trailing = items
            .where((w) => w != leading)
            .toList(growable: false);

        return Row(
          children: [
            if (leading != null) leading,
            const Spacer(),
            if (trailing.isNotEmpty) spacedRow(trailing),
          ],
        );
      },
    );
  }
}
