import '../../../domain/services/tenant_admin_access_checker.dart';

enum ProductDashboardSummaryMetricKey {
  totalProducts,
  lowStock,
  outOfStock,
  expiryAlerts,
  stockAdded,
  fastMovingProducts,
}

class ProductDashboardVisibility {
  const ProductDashboardVisibility({
    required this.showPage,
    required this.showTitle,
    required this.showSubtitle,
    required this.showDateFilter,
    required this.showOutletFilter,
    required this.showSummarySection,
    required this.showStockValueCard,
    required this.showStockMovementCard,
    required this.visibleSummaryMetrics,
  });

  final bool showPage;
  final bool showTitle;
  final bool showSubtitle;
  final bool showDateFilter;
  final bool showOutletFilter;
  final bool showSummarySection;
  final bool showStockValueCard;
  final bool showStockMovementCard;
  final List<ProductDashboardSummaryMetricKey> visibleSummaryMetrics;

  static ProductDashboardVisibility resolve({
    required TenantAdminAccessChecker access,
  }) {
    final showPage = access.canViewProductDashboard();
    final summaryMetrics = showPage
        ? _visibleSummaryMetrics(access)
        : const <ProductDashboardSummaryMetricKey>[];

    return ProductDashboardVisibility(
      showPage: showPage,
      showTitle: showPage,
      showSubtitle: showPage,
      showDateFilter: showPage && access.canViewProductDashboardDateFilter(),
      showOutletFilter:
          showPage && access.canViewProductDashboardOutletFilter(),
      showSummarySection: summaryMetrics.isNotEmpty,
      showStockValueCard:
          showPage && access.canViewProductDashboardStockValue(),
      showStockMovementCard:
          showPage && access.canViewProductDashboardStockMovement(),
      visibleSummaryMetrics: summaryMetrics,
    );
  }

  static List<ProductDashboardSummaryMetricKey> _visibleSummaryMetrics(
    TenantAdminAccessChecker access,
  ) {
    final metrics = <ProductDashboardSummaryMetricKey>[];

    if (access.canViewProductDashboardTotalProducts()) {
      metrics.add(ProductDashboardSummaryMetricKey.totalProducts);
    }
    if (access.canViewProductDashboardLowStock()) {
      metrics.add(ProductDashboardSummaryMetricKey.lowStock);
    }
    if (access.canViewProductDashboardOutOfStock()) {
      metrics.add(ProductDashboardSummaryMetricKey.outOfStock);
    }
    if (access.canViewProductDashboardExpiryAlerts()) {
      metrics.add(ProductDashboardSummaryMetricKey.expiryAlerts);
    }
    if (access.canViewProductDashboardStockAdded()) {
      metrics.add(ProductDashboardSummaryMetricKey.stockAdded);
    }
    if (access.canViewProductDashboardFastMoving()) {
      metrics.add(ProductDashboardSummaryMetricKey.fastMovingProducts);
    }

    return metrics;
  }
}
