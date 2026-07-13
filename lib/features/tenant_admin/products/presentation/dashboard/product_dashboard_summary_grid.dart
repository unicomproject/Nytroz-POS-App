import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../domain/services/tenant_admin_access_checker.dart';
import '../../../presentation/theme/tenant_admin_theme.dart';
import '../../../presentation/widgets/tenant_admin_status_badge.dart';
import '../../domain/entities/product_dashboard.dart';
import 'product_dashboard_formatters.dart';
import 'product_dashboard_navigation.dart';
import 'product_dashboard_summary_card.dart';
import 'product_dashboard_visibility.dart';

class ProductDashboardSummaryGrid extends StatelessWidget {
  const ProductDashboardSummaryGrid({
    super.key,
    required this.summary,
    required this.visibility,
    required this.access,
    this.currencyCode,
    this.compact = false,
  });

  final ProductDashboardSummary summary;
  final ProductDashboardVisibility visibility;
  final TenantAdminAccessChecker? access;
  final String? currencyCode;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final cards = <_SummaryCardConfig>[];

    for (final metricKey in visibility.visibleSummaryMetrics) {
      final config = _configFor(metricKey, summary);
      if (config != null) {
        cards.add(config);
      }
    }

    if (cards.isEmpty) {
      return const ProductDashboardPermissionEmptyStateInline();
    }

    final width = MediaQuery.sizeOf(context).width;
    final crossAxisCount = compact
        ? 1
        : width >= TenantAdminBreakpoints.tablet
            ? 3
            : 2;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: TenantAdminSpacing.lg,
        mainAxisSpacing: TenantAdminSpacing.lg,
        mainAxisExtent: compact ? 172 : 168,
      ),
      itemCount: cards.length,
      itemBuilder: (context, index) {
        final card = cards[index];
        final canNavigate = access != null &&
            ProductDashboardNavigation.canNavigate(access!, card.metricKey);

        return ProductDashboardSummaryCard(
          title: card.title,
          value: card.value,
          trend: card.trend,
          icon: card.icon,
          status: card.status,
          dense: true,
          onTap: canNavigate
              ? () => context.go(
                    ProductDashboardNavigation.routeFor(card.metricKey)!,
                  )
              : null,
        );
      },
    );
  }

  _SummaryCardConfig? _configFor(
    ProductDashboardSummaryMetricKey key,
    ProductDashboardSummary summary,
  ) {
    switch (key) {
      case ProductDashboardSummaryMetricKey.totalProducts:
        return _buildConfig(
          key: key,
          title: 'Total Products',
          metric: summary.totalProducts,
          icon: Icons.inventory_2_outlined,
          status: TenantAdminStatusType.active,
        );
      case ProductDashboardSummaryMetricKey.lowStock:
        return _buildConfig(
          key: key,
          title: 'Low Stock',
          metric: summary.lowStock,
          icon: Icons.warning_amber_outlined,
          status: TenantAdminStatusType.warning,
        );
      case ProductDashboardSummaryMetricKey.outOfStock:
        return _buildConfig(
          key: key,
          title: 'Out of Stock',
          metric: summary.outOfStock,
          icon: Icons.remove_shopping_cart_outlined,
          status: TenantAdminStatusType.danger,
        );
      case ProductDashboardSummaryMetricKey.expiryAlerts:
        return _buildConfig(
          key: key,
          title: 'Expiry Alerts',
          metric: summary.expiryAlerts,
          icon: Icons.event_busy_outlined,
          status: TenantAdminStatusType.warning,
        );
      case ProductDashboardSummaryMetricKey.stockAdded:
        return _buildConfig(
          key: key,
          title: 'Stock Added',
          metric: summary.stockAdded,
          icon: Icons.add_box_outlined,
          status: TenantAdminStatusType.success,
        );
      case ProductDashboardSummaryMetricKey.fastMovingProducts:
        return _buildConfig(
          key: key,
          title: 'Fast Moving Products',
          metric: summary.fastMovingProducts,
          icon: Icons.trending_up,
          status: TenantAdminStatusType.success,
        );
    }
  }

  _SummaryCardConfig? _buildConfig({
    required ProductDashboardSummaryMetricKey key,
    required String title,
    required ProductDashboardMetric? metric,
    required IconData icon,
    required TenantAdminStatusType status,
  }) {
    if (metric == null) {
      return null;
    }

    final trendDisplay = formatProductDashboardTrend(metric.changePercent);

    return _SummaryCardConfig(
      metricKey: key,
      title: title,
      value: formatProductDashboardMetricValue(metric, currencyCode: currencyCode),
      trend: ProductDashboardSummaryCardTrend(
        label: trendDisplay.label,
        icon: trendDisplay.icon,
        color: _trendColor(metric.changePercent),
      ),
      icon: icon,
      status: status,
    );
  }

  Color _trendColor(double? changePercent) {
    if (changePercent == null || changePercent == 0) {
      return TenantAdminColors.mutedText;
    }

    return changePercent > 0
        ? TenantAdminColors.success
        : TenantAdminColors.danger;
  }
}

class _SummaryCardConfig {
  const _SummaryCardConfig({
    required this.metricKey,
    required this.title,
    required this.value,
    required this.trend,
    required this.icon,
    required this.status,
  });

  final ProductDashboardSummaryMetricKey metricKey;
  final String title;
  final String value;
  final ProductDashboardSummaryCardTrend trend;
  final IconData icon;
  final TenantAdminStatusType status;
}

class ProductDashboardPermissionEmptyStateInline extends StatelessWidget {
  const ProductDashboardPermissionEmptyStateInline({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: TenantAdminSpacing.lg),
      child: Text(
        'No summary metrics are available for your current permissions.',
        style: TextStyle(color: TenantAdminColors.mutedText),
      ),
    );
  }
}
