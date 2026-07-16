abstract final class ReportApiPaths {
  static const base = '/api/v1/tenant-admin/reports';
  static const filterOptions = '$base/filter-options';
  static const dashboard = '$base/dashboard';
  static const sales = '$base/sales';
  static const stock = '$base/stock';
  static const outlets = '$base/outlets';
  static const exports = '$base/exports';

  static String salesDetail(String orderId) => '$sales/$orderId';

  static String exportStatus(String jobId) => '$exports/$jobId';
}

abstract final class ReportSections {
  static const dashboard = 'dashboard';
  static const salesSummary = 'summary';
  static const transactions = 'transactions';
  static const products = 'products';
  static const categories = 'categories';
  static const payments = 'payments';
  static const tax = 'tax';
  static const discounts = 'discounts';
  static const returns = 'returns';
  static const cashiers = 'cashiers';
  static const daily = 'daily';
  static const currentStock = 'current';
  static const lowStock = 'low-stock';
  static const outOfStock = 'out-of-stock';
  static const batchExpiry = 'batch-expiry';
  static const movements = 'movements';
  static const valuation = 'valuation';
  static const outletPerformance = 'performance';
  static const tillSummary = 'tills';
}
