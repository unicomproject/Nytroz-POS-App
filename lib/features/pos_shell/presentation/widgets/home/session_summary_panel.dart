import 'package:flutter/material.dart';

import '../../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';
import '../../../application/state/pos_home_dashboard_state.dart';
import 'session_summary_card.dart';

class PosHomeSummarySection extends StatelessWidget {
  const PosHomeSummarySection({
    super.key,
    required this.summary,
    this.onRetry,
  });

  final PosHomeSummaryState? summary;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
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
    final metrics = [
      (
        'Total Sales',
        Icons.shopping_bag_outlined,
        TenantAdminColors.posHomeOrangeEnd,
        TenantAdminColors.posHomeOrangeEnd.withValues(alpha: 0.14),
        data.grossSalesAmount,
        null,
      ),
      (
        'Transactions',
        Icons.receipt_long_outlined,
        TenantAdminColors.success,
        TenantAdminColors.success.withValues(alpha: 0.14),
        null,
        data.transactionCount,
      ),
      (
        'Returns',
        Icons.assignment_return_outlined,
        TenantAdminColors.pending,
        TenantAdminColors.pending.withValues(alpha: 0.13),
        data.refundAmount,
        data.refundCount,
      ),
      (
        'Discounts',
        Icons.local_offer_outlined,
        TenantAdminColors.warning,
        TenantAdminColors.warning.withValues(alpha: 0.15),
        data.discountAmount,
        null,
      ),
      (
        'Net Sales',
        Icons.bar_chart_rounded,
        TenantAdminColors.posHomeBlueEnd,
        TenantAdminColors.posHomeBlueStart.withValues(alpha: 0.14),
        data.netSalesAmount,
        null,
      ),
    ];
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
                    label: metric.$1,
                    icon: metric.$2,
                    iconColor: metric.$3,
                    iconBackgroundColor: metric.$4,
                    value: metric.$5 == null
                        ? '${metric.$6}'
                        : '${data.currencyCode} ${metric.$5!.toStringAsFixed(2)}',
                    supporting: metric.$5 != null && metric.$6 != null
                        ? '${metric.$6} completed'
                        : null,
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
