import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
        final isTabletLayout =
            constraints.maxWidth >= TenantAdminBreakpoints.mobile;
        final hasBottomCards = _hasVisibleBottomCards(
          returnsAccess,
          customerAccess,
          parkedSalesAccess,
          cashDrawerAccess,
        );

        final content = _DashboardSections(
          dashboard: dashboard,
          startSaleAction: startSaleAction,
          onlineOrdersAction: onlineOrdersAction,
          returnsAction: returnsAction,
          customerAction: customerAction,
          parkedSalesAction: parkedSalesAction,
          cashDrawerAction: cashDrawerAction,
          showStartSale: startSaleAccess.isVisible,
          showOnlineOrders: onlineOrdersAccess.isVisible,
          showReturns: returnsAccess.isVisible,
          showCustomer: customerAccess.isVisible,
          showParkedSales: parkedSalesAccess.isVisible,
          showCashDrawer: cashDrawerAccess.isVisible,
          hasBottomCards: hasBottomCards,
          isStartSaleEnabled: startSaleAccess.isEnabled,
          startSaleDisabledMessage: startSaleAccess.disabledMessage,
        );

        if (!isTabletLayout) {
          return SingleChildScrollView(
            padding: TenantAdminInsets.pageForWidth(constraints.maxWidth),
            child: content,
          );
        }

        return Padding(
          padding: TenantAdminInsets.pageForWidth(constraints.maxWidth),
          child: SizedBox.expand(
            child: content,
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

class _DashboardSections extends StatelessWidget {
  const _DashboardSections({
    required this.dashboard,
    required this.startSaleAction,
    required this.onlineOrdersAction,
    required this.returnsAction,
    required this.customerAction,
    required this.parkedSalesAction,
    required this.cashDrawerAction,
    required this.showStartSale,
    required this.showOnlineOrders,
    required this.showReturns,
    required this.showCustomer,
    required this.showParkedSales,
    required this.showCashDrawer,
    required this.hasBottomCards,
    required this.isStartSaleEnabled,
    this.startSaleDisabledMessage,
  });

  final PosHomeDashboardState dashboard;
  final PosHomeAction startSaleAction;
  final PosHomeAction onlineOrdersAction;
  final PosHomeAction returnsAction;
  final PosHomeAction customerAction;
  final PosHomeAction parkedSalesAction;
  final PosHomeAction cashDrawerAction;
  final bool showStartSale;
  final bool showOnlineOrders;
  final bool showReturns;
  final bool showCustomer;
  final bool showParkedSales;
  final bool showCashDrawer;
  final bool hasBottomCards;
  final bool isStartSaleEnabled;
  final String? startSaleDisabledMessage;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isFixedTablet = constraints.hasBoundedHeight &&
            constraints.maxWidth >= TenantAdminBreakpoints.mobile;

        final topGrid = PosHomeTopGrid(
          startSaleAction: startSaleAction,
          onlineOrdersAction: onlineOrdersAction,
          startSaleTitle: 'Start a Sale',
          startSaleDescription:
              'Create a new transaction for any product, ticket, service or experience.',
          startSaleButtonLabel: dashboard.startSaleButtonLabel,
          showStartSale: showStartSale,
          showOnlineOrders: showOnlineOrders,
          isStartSaleEnabled: isStartSaleEnabled,
          startSaleDisabledMessage: startSaleDisabledMessage,
          onStartSale: () => context.go('/pos/new-sale'),
        );
        final bottomGrid = PosHomeBottomGrid(
          returnsAction: returnsAction,
          customerAction: customerAction,
          parkedSalesAction: parkedSalesAction,
          cashDrawerAction: cashDrawerAction,
          showReturns: showReturns,
          showCustomer: showCustomer,
          showParkedSales: showParkedSales,
          showCashDrawer: showCashDrawer,
          onViewReturns: () => context.go('/pos/returns-refunds'),
          onAddCustomer: () => context.go('/pos/customers'),
          onViewParkedSales: () => context.go('/pos/parked-sales'),
          onViewCashDrawer: () => context.go('/pos/cash-drawer'),
        );

        if (!isFixedTablet) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PosHomeHeader(dashboard: dashboard),
              const SizedBox(height: TenantAdminSpacing.xl),
              topGrid,
              if (hasBottomCards) ...[
                const SizedBox(height: TenantAdminSpacing.xl),
                bottomGrid,
              ],
            ],
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PosHomeHeader(dashboard: dashboard),
            const SizedBox(height: TenantAdminSpacing.lg),
            Expanded(
              flex: hasBottomCards ? 6 : 1,
              child: topGrid,
            ),
            if (hasBottomCards) ...[
              const SizedBox(height: TenantAdminSpacing.lg),
              Expanded(
                flex: 5,
                child: bottomGrid,
              ),
            ],
          ],
        );
      },
    );
  }
}
