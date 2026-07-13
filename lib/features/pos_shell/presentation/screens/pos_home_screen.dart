import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';
import '../../../auth/presentation/providers/session_provider.dart';
import '../../../device_activation/presentation/providers/device_activation_provider.dart';
import '../../../till/presentation/providers/till_provider.dart';
import '../../application/state/pos_home_dashboard_state.dart';
import '../../data/datasources/pos_home_remote_datasource.dart';
import '../../domain/entities/pos_home_action.dart';
import '../providers/pos_home_dashboard_provider.dart';
import '../widgets/home/pos_home_bottom_grid.dart';
import '../widgets/home/pos_home_header.dart';
import '../widgets/home/pos_home_top_grid.dart';

class PosHomeScreen extends ConsumerWidget {
  const PosHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardAsync = ref.watch(posHomeDashboardProvider);
    final shellDashboard = _shellDashboard(ref);

    return dashboardAsync.when(
      data: (dashboard) => _PosHomeContent(dashboard: dashboard),
      loading: () => _PosHomeContent(
        dashboard: shellDashboard,
        dashboardStatus: const _DashboardInlineStatus.loading(),
      ),
      error: (error, _) => _PosHomeContent(
        dashboard: shellDashboard,
        dashboardStatus: _DashboardInlineStatus.error(
          message: error is PosHomeException
              ? error.message
              : 'POS home dashboard could not be loaded. Try again.',
          onRetry: () => ref.invalidate(posHomeDashboardProvider),
        ),
      ),
    );
  }

  PosHomeDashboardState _shellDashboard(WidgetRef ref) {
    final session = ref.watch(authSessionProvider);
    final deviceContext = ref.watch(deviceActivationProvider).deviceContext;
    final tillState = ref.watch(tillProvider);

    return buildPosHomeShellState(
      userDisplayName: session?.userDisplayName ?? '',
      isTrustedDevice: deviceContext?.isTrusted == true,
      hasOpenTillSession: tillState.hasOpenSession,
      permissionCodes: session?.permissionCodes.toSet() ?? const {},
    );
  }
}

class _PosHomeContent extends StatelessWidget {
  const _PosHomeContent({
    required this.dashboard,
    this.dashboardStatus,
  });

  final PosHomeDashboardState dashboard;
  final Widget? dashboardStatus;

  @override
  Widget build(BuildContext context) {
    final startSaleAction = _action('start-new-sale');
    final onlineOrdersAction = _optionalAction('manage-online-orders');
    final returnsAction = _action('returns-refunds');
    final customerAction = _action('add-customer');
    final parkedSalesAction = _action('parked-sales');
    final cashDrawerAction = _action('cash-drawer');

    final startSaleAccess = dashboard.accessFor(startSaleAction);
    final onlineOrdersAccess = onlineOrdersAction == null
        ? const PosHomeActionAccess(isVisible: false, isEnabled: false)
        : dashboard.accessFor(onlineOrdersAction);
    final returnsAccess = dashboard.accessFor(returnsAction);
    final customerAccess = dashboard.accessFor(customerAction);
    final parkedSalesAccess = dashboard.accessFor(parkedSalesAction);
    final cashDrawerAccess = dashboard.accessFor(cashDrawerAction);

    return LayoutBuilder(
      builder: (context, constraints) {
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
          dashboardStatus: dashboardStatus,
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

  PosHomeAction? _optionalAction(String key) {
    for (final action in dashboard.actions) {
      if (action.key == key) {
        return action;
      }
    }

    return null;
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
    this.dashboardStatus,
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
  final PosHomeAction? onlineOrdersAction;
  final PosHomeAction returnsAction;
  final PosHomeAction customerAction;
  final PosHomeAction parkedSalesAction;
  final PosHomeAction cashDrawerAction;
  final Widget? dashboardStatus;
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
        final isFixedLayout = constraints.hasBoundedHeight;

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

        if (!isFixedLayout) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PosHomeHeader(dashboard: dashboard),
              if (dashboardStatus != null) ...[
                const SizedBox(height: TenantAdminSpacing.md),
                dashboardStatus!,
              ],
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
            if (dashboardStatus != null) ...[
              const SizedBox(height: TenantAdminSpacing.sm),
              dashboardStatus!,
            ],
            const SizedBox(height: TenantAdminSpacing.sm),
            Expanded(
              child: Column(
                children: [
                  Expanded(
                    flex: hasBottomCards ? 7 : 1,
                    child: topGrid,
                  ),
                  if (hasBottomCards) ...[
                    const SizedBox(height: TenantAdminSpacing.sm),
                    Expanded(
                      flex: 5,
                      child: bottomGrid,
                    ),
                  ],
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _DashboardInlineStatus extends StatelessWidget {
  const _DashboardInlineStatus.loading()
      : message = 'Dashboard metrics are loading.',
        onRetry = null;

  const _DashboardInlineStatus.error({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final isError = onRetry != null;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(TenantAdminSpacing.md),
      decoration: BoxDecoration(
        color: TenantAdminColors.surface,
        borderRadius: BorderRadius.circular(TenantAdminRadius.md),
        border: Border.all(color: TenantAdminColors.border),
      ),
      child: Row(
        children: [
          if (isError)
            const Icon(
              Icons.error_outline_rounded,
              color: TenantAdminColors.warning,
            )
          else
            const SizedBox.square(
              dimension: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          const SizedBox(width: TenantAdminSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: TenantAdminColors.bodyText,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
          if (onRetry != null) ...[
            const SizedBox(width: TenantAdminSpacing.sm),
            TextButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
            ),
          ],
        ],
      ),
    );
  }
}
