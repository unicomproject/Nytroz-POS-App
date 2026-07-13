abstract final class InventoryApiPaths {
  static const inventoryBase = '/api/v1/tenant-admin/inventory';
  static const currentStock = '$inventoryBase/current-stock';
  static const currentStockSummary = '$inventoryBase/current-stock/summary';
  static const stockIn = '$inventoryBase/stock-in';

  static String productVariants(String productId) =>
      '/api/v1/tenant-admin/products/$productId/variants';
}

abstract final class InventoryStockStatusFilter {
  static const inStock = 'IN_STOCK';
  static const lowStock = 'LOW_STOCK';
  static const outOfStock = 'OUT_OF_STOCK';
  static const all = 'ALL';
}

abstract final class InventoryStockStatus {
  static const inStock = 'IN_STOCK';
  static const lowStock = 'LOW_STOCK';
  static const outOfStock = 'OUT_OF_STOCK';
  static const unknown = 'UNKNOWN';
}

abstract final class InventoryExpiryStatus {
  static const notApplicable = 'NOT_APPLICABLE';
  static const valid = 'VALID';
  static const expiringSoon = 'EXPIRING_SOON';
  static const expired = 'EXPIRED';
  static const unknown = 'UNKNOWN';
}

abstract final class InventoryExpiryStatusFilter {
  static const expiring = 'EXPIRING';
  static const expired = 'EXPIRED';
  static const all = 'ALL';
}
