import 'package:flutter/material.dart';

import '../../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';
import '../../../application/state/pos_home_dashboard_state.dart';
import 'cashier_profile_card.dart';
import 'dashboard_action_builder.dart';
import 'dashboard_action_grid.dart';
import 'session_summary_panel.dart';

export 'dashboard_action_card.dart' show PosHomeActionTile;
export 'session_summary_panel.dart' show PosHomeSummarySection;

class PosHomeDashboard extends StatelessWidget {
  const PosHomeDashboard({
    super.key,
    required this.dashboard,
    this.status,
    this.onSummaryRetry,
  });

  final PosHomeDashboardState dashboard;
  final Widget? status;
  final VoidCallback? onSummaryRetry;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < TenantAdminBreakpoints.tablet;
        final pagePadding = compact
            ? TenantAdminInsets.pageForWidth(constraints.maxWidth)
            : const EdgeInsets.fromLTRB(24, 16, 24, 12);
        final body = compact
            ? ListView(
                padding: pagePadding,
                children: _sections(context, compact: true),
              )
            : Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1920),
                  child: Padding(
                    padding: pagePadding,
                    child: Column(
                      children: _sections(context, compact: false),
                    ),
                  ),
                ),
              );
        return ColoredBox(
          color: TenantAdminColors.posHomeDarkBackground,
          child: body,
        );
      },
    );
  }

  List<Widget> _sections(BuildContext context, {required bool compact}) {
    final actions = buildPosHomeActionCards(
      context: context,
      dashboard: dashboard,
    );
    return [
      if (status != null) ...[
        const SizedBox(height: TenantAdminSpacing.sm),
        status!,
      ],
      const SizedBox(height: TenantAdminSpacing.md),
      if (compact) ...[
        CashierProfileCard(dashboard: dashboard),
        const SizedBox(height: TenantAdminSpacing.lg),
        DashboardActionGrid(cards: actions, compact: true),
      ] else
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                width:
                    (MediaQuery.sizeOf(context).width * 0.215).clamp(248, 350),
                child: CashierProfileCard(dashboard: dashboard),
              ),
              const SizedBox(width: TenantAdminSpacing.lg),
              Expanded(
                child: DashboardActionGrid(cards: actions, compact: false),
              ),
            ],
          ),
        ),
      const SizedBox(height: TenantAdminSpacing.md),
      PosHomeSummarySection(
        summary: dashboard.summary,
        onRetry: onSummaryRetry,
      ),
    ];
  }
}
