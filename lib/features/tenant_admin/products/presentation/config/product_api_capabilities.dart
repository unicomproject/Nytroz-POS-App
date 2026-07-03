/// Flags for tenant-admin product APIs that exist today.
/// UI sections and actions should stay hidden when the matching flag is false.
class ProductApiCapabilities {
  const ProductApiCapabilities._();

  /// GET /api/v1/tenant-admin/products
  static const bool listProducts = true;

  /// POST /api/v1/tenant-admin/products
  static const bool createProduct = true;

  /// POST /api/v1/tenant-admin/products/{id}/image
  static const bool uploadProductImage = true;

  /// GET /api/v1/tenant-admin/products/{id}
  static const bool getProductById = false;

  /// PUT/PATCH /api/v1/tenant-admin/products/{id}
  static const bool updateProduct = false;

  /// DELETE /api/v1/tenant-admin/products/{id}
  static const bool deleteProduct = false;

  /// POST /api/v1/tenant-admin/products/import
  static const bool importProductsCsv = false;

  /// Top-selling products report endpoint
  static const bool topSellingReport = false;

  /// Variant option templates and generated variants on create
  static const bool variantsOnCreate = false;

  /// Barcode and SKU management step on create
  static const bool barcodesOnCreate = false;

  /// Channel visibility step on create
  static const bool channelVisibilityOnCreate = false;

  /// Tax classes and price lists from backend
  static const bool pricingTaxClasses = false;

  /// Barcode scanner integration
  static const bool barcodeScanner = false;

  static const bool expiryOnCreate = false;
  static const bool saveDraft = false;
  static const bool statusOnCreate = false;
  static const bool openingStockOnCreate = false;
  static const bool outletAssignmentOnCreate = false;

  /// Create payload field: trackStock
  static const bool trackStockOnCreate = true;

  /// Product detail screen and tabs
  static const bool productDetail = false;

  /// Product audit/history tab
  static const bool productAuditTab = false;
}
