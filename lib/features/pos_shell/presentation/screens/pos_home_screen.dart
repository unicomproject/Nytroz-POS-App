import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';
import '../../../tenant_admin/presentation/widgets/tenant_admin_states.dart';
import '../../application/state/pos_home_dashboard_state.dart';
import '../../data/datasources/pos_home_remote_datasource.dart';
import '../../domain/entities/pos_home_action.dart';
import '../providers/pos_home_dashboard_provider.dart';
import '../widgets/pos_home_bottom_grid.dart';
import '../widgets/pos_home_header.dart';
import '../widgets/pos_home_top_grid.dart';
import '../widgets/pos_shell_scaffold.dart';

class PosHomeScreen extends ConsumerWidget {
  const PosHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardAsync = ref.watch(posHomeDashboardProvider);

    return PosShellScaffold(
      child: dashboardAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => TenantAdminErrorState(
          title: 'POS home unavailable',
          message: error is PosHomeException
              ? error.message
              : 'POS home dashboard could not be loaded. Try again.',
          onRetry: () => ref.invalidate(posHomeDashboardProvider),
        ),
        data: (dashboard) => _PosHomeContent(dashboard: dashboard),
      ),
    );
  }
}

class _PosHomeContent extends StatelessWidget {
  const _PosHomeContent({required this.dashboard});

  final PosHomeDashboardState dashboard;

  @override
  Widget build(BuildContext context) {
    final startSaleAction = _action('start-new-sale');
    final onlineOrdersAction = _action('manage-online-orders');
    final returnsAction = _action('returns-refunds');
    final customerAction = _action('add-customer');
    final parkedSalesAction = _action('parked-sales');
    final cashDrawerAction = _action('cash-drawer');

    final startSaleAccess = dashboard.accessFor(startSaleAction);
    final onlineOrdersAccess = dashboard.accessFor(onlineOrdersAction);
    final returnsAccess = dashboard.accessFor(returnsAction);
    final customerAccess = dashboard.accessFor(customerAction);
    final parkedSalesAccess = dashboard.accessFor(parkedSalesAction);
    final cashDrawerAccess = dashboard.accessFor(cashDrawerAction);

    return LayoutBuilder(
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
                  showStartSale: startSaleAccess.isVisible,
                  showOnlineOrders: onlineOrdersAccess.isVisible,
                  isStartSaleEnabled: startSaleAccess.isEnabled,
                  startSaleDisabledMessage: startSaleAccess.disabledMessage,
                ),
                if (_hasVisibleBottomCards(
                  returnsAccess,
                  customerAccess,
                  parkedSalesAccess,
                  cashDrawerAccess,
                )) ...[
                  const SizedBox(height: TenantAdminSpacing.xl),
                  PosHomeBottomGrid(
                    returnsAction: returnsAction,
                    customerAction: customerAction,
                    parkedSalesAction: parkedSalesAction,
                    cashDrawerAction: cashDrawerAction,
                    showReturns: returnsAccess.isVisible,
                    showCustomer: customerAccess.isVisible,
                    showParkedSales: parkedSalesAccess.isVisible,
                    showCashDrawer: cashDrawerAccess.isVisible,
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  PosHomeAction _action(String key) {
    return dashboard.actions.firstWhere((action) => action.key == key);
  }

  bool _hasVisibleBottomCards(
    PosHomeActionAccess returnsAccess,
    PosHomeActionAccess customerAccess,
    PosHomeActionAccess parkedSalesAccess,
    PosHomeActionAccess cashDrawerAccess,
  ) {
    return returnsAccess.isVisible ||
        customerAccess.isVisible ||
        parkedSalesAccess.isVisible ||
        cashDrawerAccess.isVisible;
  }
}
