import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/access/permission_access_providers.dart';
import '../../../../../core/access/pos_access_codes.dart';
import '../../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';
import '../../../application/state/pos_home_dashboard_state.dart';
import 'session_summary_card.dart';

class PosHomeSummarySection extends ConsumerWidget {
  const PosHomeSummarySection({
    super.key,
    required this.summary,
    this.onRetry,
  });

  final PosHomeSummaryState? summary;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final permissions = ref.watch(effectivePermissionSetProvider);
    if (!permissions.hasPermission(PosPermissionCodes.homeSessionSummaryView)) {
      return const SizedBox.shrink();
    }

    if (summary == null) {
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
            const Expanded(
              child: Text('Current session summary is unavailable.'),
            ),
            if (onRetry != null)
              TextButton.icon(
                key: const Key('pos-home-summary-retry'),
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Retry'),
              ),
          ],
        ),
      );
    }
    final data = summary!;
    final metrics = <({
      String label,
      IconData icon,
      Color iconColor,
      Color iconBackground,
      String value,
      String? supporting,
    })>[
      if (permissions
          .hasPermission(PosPermissionCodes.homeSessionSummaryTotalSales))
        (
          label: 'Total Sales',
          icon: Icons.shopping_bag_outlined,
          iconColor: TenantAdminColors.posHomeOrangeEnd,
          iconBackground:
              TenantAdminColors.posHomeOrangeEnd.withValues(alpha: 0.14),
          value:
              '${data.currencyCode} ${data.grossSalesAmount.toStringAsFixed(2)}',
          supporting: null,
        ),
      if (permissions.hasPermission(
          PosPermissionCodes.homeSessionSummaryTransactionCount))
        (
          label: 'Transactions',
          icon: Icons.receipt_long_outlined,
          iconColor: TenantAdminColors.success,
          iconBackground: TenantAdminColors.success.withValues(alpha: 0.14),
          value: '${data.transactionCount}',
          supporting: null,
        ),
      if (permissions
          .hasPermission(PosPermissionCodes.homeSessionSummaryReturns))
        (
          label: 'Returns',
          icon: Icons.assignment_return_outlined,
          iconColor: TenantAdminColors.pending,
          iconBackground: TenantAdminColors.pending.withValues(alpha: 0.13),
          value:
              '${data.currencyCode} ${data.refundAmount.toStringAsFixed(2)}',
          supporting: '${data.refundCount} completed',
        ),
      if (permissions
          .hasPermission(PosPermissionCodes.homeSessionSummaryDiscounts))
        (
          label: 'Discounts',
          icon: Icons.local_offer_outlined,
          iconColor: TenantAdminColors.warning,
          iconBackground: TenantAdminColors.warning.withValues(alpha: 0.15),
          value:
              '${data.currencyCode} ${data.discountAmount.toStringAsFixed(2)}',
          supporting: null,
        ),
      if (permissions
          .hasPermission(PosPermissionCodes.homeSessionSummaryNetSales))
        (
          label: 'Net Sales',
          icon: Icons.bar_chart_rounded,
          iconColor: TenantAdminColors.posHomeBlueEnd,
          iconBackground:
              TenantAdminColors.posHomeBlueStart.withValues(alpha: 0.14),
          value: '${data.currencyCode} ${data.netSalesAmount.toStringAsFixed(2)}',
          supporting: null,
        ),
    ];

    if (metrics.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        TenantAdminSpacing.lg,
        TenantAdminSpacing.lg,
        TenantAdminSpacing.lg,
        TenantAdminSpacing.lg,
      ),
      decoration: BoxDecoration(
        color: TenantAdminColors.surface,
        borderRadius: BorderRadius.circular(TenantAdminRadius.lg),
        boxShadow: TenantAdminShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            data.scope == 'CURRENT_TILL_SESSION'
                ? 'CURRENT SESSION SUMMARY'
                : 'TODAY’S SUMMARY',
            style: TenantAdminTextStyles.sectionTitle(context),
          ),
          const SizedBox(height: TenantAdminSpacing.md),
          SizedBox(
            height: 118,
            child: LayoutBuilder(
              builder: (context, constraints) {
                Widget metricCard(int index) {
                  final metric = metrics[index];
                  return SessionSummaryCard(
                    label: metric.label,
                    icon: metric.icon,
                    iconColor: metric.iconColor,
                    iconBackgroundColor: metric.iconBackground,
                    value: metric.value,
                    supporting: metric.supporting,
                  );
                }

                if (constraints.maxWidth >= 900) {
                  return Row(
                    children: [
                      for (var index = 0; index < metrics.length; index++) ...[
                        if (index > 0)
                          const SizedBox(width: TenantAdminSpacing.md),
                        Expanded(child: metricCard(index)),
                      ],
                    ],
                  );
                }
                return ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: metrics.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(width: TenantAdminSpacing.sm),
                  itemBuilder: (context, index) => SizedBox(
                    width: 220,
                    child: metricCard(index),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
