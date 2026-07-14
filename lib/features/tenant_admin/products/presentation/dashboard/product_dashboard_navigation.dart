import '../../../domain/services/tenant_admin_access_checker.dart';
import 'product_dashboard_visibility.dart';

class ProductDashboardNavigation {
  const ProductDashboardNavigation._();

  static String? routeFor(ProductDashboardSummaryMetricKey key) {
    switch (key) {
      case ProductDashboardSummaryMetricKey.totalProducts:
        return '/tenant-admin/products';
      case ProductDashboardSummaryMetricKey.lowStock:
        return '/tenant-admin/stock/current?stockStatus=LOW_STOCK';
      case ProductDashboardSummaryMetricKey.outOfStock:
        return '/tenant-admin/stock/current?stockStatus=OUT_OF_STOCK';
      case ProductDashboardSummaryMetricKey.expiryAlerts:
        return '/tenant-admin/stock/current?expiryStatus=EXPIRING';
      case ProductDashboardSummaryMetricKey.stockAdded:
        return '/tenant-admin/stock/in';
      case ProductDashboardSummaryMetricKey.fastMovingProducts:
        return '/tenant-admin/reports/products?type=fast-moving';
    }
  }

  static bool canNavigate(
    TenantAdminAccessChecker access,
    ProductDashboardSummaryMetricKey key,
  ) {
    switch (key) {
      case ProductDashboardSummaryMetricKey.totalProducts:
        return access.canNavigateProductDashboardTotalProducts();
      case ProductDashboardSummaryMetricKey.lowStock:
        return access.canNavigateProductDashboardLowStock();
      case ProductDashboardSummaryMetricKey.outOfStock:
        return access.canNavigateProductDashboardOutOfStock();
      case ProductDashboardSummaryMetricKey.expiryAlerts:
        return access.canNavigateProductDashboardExpiryAlerts();
      case ProductDashboardSummaryMetricKey.stockAdded:
        return access.canNavigateProductDashboardStockAdded();
      case ProductDashboardSummaryMetricKey.fastMovingProducts:
        return access.canNavigateProductDashboardFastMoving();
    }
  }

  static String? movementRouteFor(String type) {
    switch (type) {
      case 'stock_in':
        return '/tenant-admin/stock/movements?type=stock-in';
      case 'stock_out':
        return '/tenant-admin/stock/movements?type=stock-out';
      case 'adjustment':
        return '/tenant-admin/stock/adjustments';
      case 'transfer':
        return '/tenant-admin/stock/transfers';
      default:
        return null;
    }
  }

  static bool canNavigateMovement(
    TenantAdminAccessChecker access,
    String type,
  ) {
    switch (type) {
      case 'stock_in':
        return access.canNavigateProductDashboardStockInMovement();
      case 'stock_out':
        return access.canNavigateProductDashboardStockOutMovement();
      case 'adjustment':
        return access.canNavigateProductDashboardAdjustments();
      case 'transfer':
        return access.canNavigateProductDashboardTransfers();
      default:
        return false;
    }
  }
}
