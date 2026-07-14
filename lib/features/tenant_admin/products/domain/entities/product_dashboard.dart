class ProductDashboardMetric {
  const ProductDashboardMetric({
    required this.value,
    this.changePercent,
  });

  final num value;
  final double? changePercent;
}

class ProductDashboardSummary {
  const ProductDashboardSummary({
    this.totalProducts,
    this.lowStock,
    this.outOfStock,
    this.expiryAlerts,
    this.stockAdded,
    this.fastMovingProducts,
  });

  final ProductDashboardMetric? totalProducts;
  final ProductDashboardMetric? lowStock;
  final ProductDashboardMetric? outOfStock;
  final ProductDashboardMetric? expiryAlerts;
  final ProductDashboardMetric? stockAdded;
  final ProductDashboardMetric? fastMovingProducts;
}

class ProductDashboardTrendPoint {
  const ProductDashboardTrendPoint({
    required this.date,
    required this.label,
    required this.value,
  });

  final String date;
  final String label;
  final double value;
}

class ProductDashboardStockValue {
  const ProductDashboardStockValue({
    required this.currentValue,
    this.changePercent,
    this.trend = const [],
  });

  final double currentValue;
  final double? changePercent;
  final List<ProductDashboardTrendPoint> trend;
}

class ProductDashboardMovementItem {
  const ProductDashboardMovementItem({
    required this.type,
    required this.label,
    required this.count,
    required this.percentage,
  });

  final String type;
  final String label;
  final int count;
  final double percentage;
}

class ProductDashboardStockMovement {
  const ProductDashboardStockMovement({
    required this.totalCount,
    this.items = const [],
  });

  final int totalCount;
  final List<ProductDashboardMovementItem> items;
}

class ProductDashboard {
  const ProductDashboard({
    this.lastUpdatedAt,
    this.currencyCode,
    this.summary,
    this.stockValue,
    this.stockMovement,
  });

  final DateTime? lastUpdatedAt;
  final String? currencyCode;
  final ProductDashboardSummary? summary;
  final ProductDashboardStockValue? stockValue;
  final ProductDashboardStockMovement? stockMovement;
}

class ProductDashboardQuery {
  const ProductDashboardQuery({
    this.outletId,
    required this.dateFrom,
    required this.dateTo,
  });

  final String? outletId;
  final DateTime dateFrom;
  final DateTime dateTo;
}
