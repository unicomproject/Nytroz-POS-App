import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';
import '../providers/pos_home_dashboard_provider.dart';
import '../widgets/pos_home_bottom_grid.dart';
import '../widgets/pos_home_header.dart';
import '../widgets/pos_home_top_grid.dart';
import '../widgets/pos_shell_scaffold.dart';

class PosHomeScreen extends ConsumerWidget {
  const PosHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboard = ref.watch(posHomeDashboardProvider);
    final startSaleAction = dashboard.actions.firstWhere(
      (action) => action.key == 'start-new-sale',
    );
    final startSaleAccess = dashboard.accessFor(startSaleAction);
    final onlineOrdersAction = dashboard.actions.firstWhere(
      (action) => action.key == 'manage-online-orders',
    );
    final returnsAction = dashboard.actions.firstWhere(
      (action) => action.key == 'returns-refunds',
    );
    final customerAction = dashboard.actions.firstWhere(
      (action) => action.key == 'add-customer',
    );
    final parkedSalesAction = dashboard.actions.firstWhere(
      (action) => action.key == 'parked-sales',
    );
    final cashDrawerAction = dashboard.actions.firstWhere(
      (action) => action.key == 'cash-drawer',
    );

    return PosShellScaffold(
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            padding: TenantAdminInsets.pageForWidth(constraints.maxWidth),
            child: Align(
              alignment: Alignment.topCenter,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  PosHomeHeader(dashboard: dashboard),
                  const SizedBox(height: TenantAdminSpacing.xl),
                  PosHomeTopGrid(
                    startSaleAction: startSaleAction,
                    onlineOrdersAction: onlineOrdersAction,
                    startSaleTitle: 'Start a Sale',
                    startSaleDescription:
                        'Create a new transaction for any product, ticket, service or experience.',
                    startSaleButtonLabel: dashboard.startSaleButtonLabel,
                    isStartSaleEnabled: startSaleAccess.isEnabled,
                    startSaleDisabledMessage: startSaleAccess.disabledMessage,
                  ),
                  const SizedBox(height: TenantAdminSpacing.xl),
                  PosHomeBottomGrid(
                    returnsAction: returnsAction,
                    customerAction: customerAction,
                    parkedSalesAction: parkedSalesAction,
                    cashDrawerAction: cashDrawerAction,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
