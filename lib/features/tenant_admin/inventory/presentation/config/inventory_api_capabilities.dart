/// Flags for inventory APIs. UI must not call or fake data when a flag is false.
class InventoryApiCapabilities {
  const InventoryApiCapabilities._();

  /// GET /api/v1/inventory/locations
  static const bool listLocations = false;

  /// GET /api/v1/inventory/balances
  static const bool listBalances = false;

  /// GET /api/v1/inventory/reorder-rules
  static const bool listReorderRules = false;

  /// POST /api/v1/inventory/stock-movements (stock-in)
  static const bool stockIn = false;

  /// Stock-in reason options from backend metadata
  static const bool stockInReasons = false;

  /// GET /api/v1/inventory/balances/export
  static const bool stockExport = false;

  /// GET /api/v1/inventory/alerts
  static const bool expiryAlerts = false;

  /// Expiry discount rules API
  static const bool expiryDiscountRules = false;

  /// GET /api/v1/products/{id}/variants — use product list grouping when false
  static const bool listVariantsByProduct = false;

  /// Product reference data for stock-in via tenant-admin products list
  static const bool listProductsReference = true;
}
