import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/outlet_detail_entities.dart';
import '../../../presentation/theme/tenant_admin_theme.dart';
import '../../../presentation/widgets/tenant_admin_states.dart';
import '../providers/outlet_detail_providers.dart';
import 'outlet_detail_kpi_row.dart';
import 'outlet_details_section_card.dart';

class OutletRevenueTab extends ConsumerWidget {
  const OutletRevenueTab({super.key, required this.outletId});

  final String outletId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(outletRevenueSummaryProvider(outletId));

    return state.when(
      loading: () => const TenantAdminLoadingSkeleton(rowCount: 8),
      error: (error, stackTrace) => TenantAdminErrorState(
        title: 'Unable to load revenue',
        message: 'Please try again.',
        onRetry: () => ref.invalidate(outletRevenueSummaryProvider(outletId)),
      ),
      data: (summary) {
        if (summary.totalOrders == 0 && summary.totalRevenue == 0) {
          return const TenantAdminEmptyState(
            title: 'No revenue data',
            message:
                'Revenue will appear when sales are recorded for this outlet.',
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            OutletDetailKpiRow(
              cards: [
                OutletDetailKpiCardData(
                  title: 'Total Revenue',
                  value: formatCurrency(summary.totalRevenue),
                  icon: Icons.payments_outlined,
                  trend: formatPercentChange(summary.revenueChangePercent),
                ),
                OutletDetailKpiCardData(
                  title: 'Average Order Value',
                  value: formatCurrency(summary.averageOrderValue),
                  icon: Icons.receipt_long_outlined,
                  trend: formatPercentChange(
                      summary.averageOrderValueChangePercent),
                ),
                OutletDetailKpiCardData(
                  title: 'Total Orders',
                  value: summary.totalOrders.toString(),
                  icon: Icons.shopping_bag_outlined,
                  trend: formatPercentChange(summary.ordersChangePercent),
                ),
                OutletDetailKpiCardData(
                  title: 'Refunds',
                  value: formatCurrency(summary.refunds),
                  icon: Icons.undo_outlined,
                  trend: formatPercentChange(summary.refundsChangePercent),
                ),
              ],
            ),
            const SizedBox(height: TenantAdminSpacing.lg),
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 1000;

                final chartSection = OutletDetailsSectionCard(
                  title: 'Revenue Over Time',
                  child: _RevenueLineChart(points: summary.revenueOverTime),
                );
                final paymentSection = OutletDetailsSectionCard(
                  title: 'Revenue by Payment Method',
                  child: _PaymentMethodChart(
                      items: summary.revenueByPaymentMethod),
                );
                final summarySection = OutletDetailsSectionCard(
                  title: 'Revenue Summary',
                  child: _RevenueSummaryList(summary: summary.revenueSummary),
                );

                if (!isWide) {
                  return Column(
                    children: [
                      chartSection,
                      const SizedBox(height: TenantAdminSpacing.lg),
                      paymentSection,
                      const SizedBox(height: TenantAdminSpacing.lg),
                      summarySection,
                    ],
                  );
                }

                return Column(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 2, child: chartSection),
                        const SizedBox(width: TenantAdminSpacing.lg),
                        Expanded(child: paymentSection),
                      ],
                    ),
                    const SizedBox(height: TenantAdminSpacing.lg),
                    summarySection,
                  ],
                );
              },
            ),
          ],
        );
      },
    );
  }
}

class _RevenueLineChart extends StatelessWidget {
  const _RevenueLineChart({required this.points});

  final List<OutletRevenuePoint> points;

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) {
      return const Text('No revenue trend available yet.');
    }

    final maxValue = points
        .map((point) => point.amount)
        .fold<double>(0, (a, b) => a > b ? a : b);

    return SizedBox(
      height: 220,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (final point in points)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: FractionallySizedBox(
                          heightFactor:
                              maxValue <= 0 ? 0.04 : point.amount / maxValue,
                          child: Container(
                            decoration: BoxDecoration(
                              color: TenantAdminColors.primary,
                              borderRadius:
                                  BorderRadius.circular(TenantAdminRadius.sm),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: TenantAdminSpacing.sm),
                    Text(
                      point.label,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: TenantAdminColors.mutedText,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _PaymentMethodChart extends StatelessWidget {
  const _PaymentMethodChart({required this.items});

  final List<OutletPaymentMethodShare> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const Text('No payment breakdown available yet.');
    }

    return Column(
      children: [
        for (final item in items) ...[
          Row(
            children: [
              Expanded(
                flex: 3,
                child: Text(item.method,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
              ),
              Expanded(
                flex: 5,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(TenantAdminRadius.sm),
                  child: LinearProgressIndicator(
                    value: item.percent <= 0 ? 0.01 : item.percent / 100,
                    minHeight: 10,
                    backgroundColor: TenantAdminColors.secondary,
                    color: TenantAdminColors.primary,
                  ),
                ),
              ),
              const SizedBox(width: TenantAdminSpacing.sm),
              Text('${item.percent.toStringAsFixed(1)}%'),
            ],
          ),
          const SizedBox(height: TenantAdminSpacing.md),
        ],
      ],
    );
  }
}

class _RevenueSummaryList extends StatelessWidget {
  const _RevenueSummaryList({required this.summary});

  final OutletRevenueBreakdown summary;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _summaryRow('Gross Revenue', formatCurrency(summary.grossRevenue)),
        _summaryRow('Discounts', '-${formatCurrency(summary.discounts)}'),
        _summaryRow('Returns', '-${formatCurrency(summary.returns)}'),
        _summaryRow(
          'Net Revenue',
          formatCurrency(summary.netRevenue),
          emphasized: true,
        ),
        _summaryRow('Tax Collected', formatCurrency(summary.taxCollected)),
      ],
    );
  }

  Widget _summaryRow(String label, String value, {bool emphasized = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: TenantAdminSpacing.sm),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontWeight: emphasized ? FontWeight.w800 : FontWeight.w600,
                color: emphasized
                    ? TenantAdminColors.primary
                    : TenantAdminColors.bodyText,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: emphasized ? FontWeight.w800 : FontWeight.w700,
              color: emphasized
                  ? TenantAdminColors.primary
                  : TenantAdminColors.bodyText,
            ),
          ),
        ],
      ),
    );
  }
}
