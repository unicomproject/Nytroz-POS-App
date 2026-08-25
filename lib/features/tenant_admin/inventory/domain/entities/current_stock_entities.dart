class CurrentStockSummary {
  const CurrentStockSummary({
    this.totalItemsInStock = 0,
    this.totalItemsLowStock = 0,
    this.totalItemsOutOfStock = 0,
    this.totalInventoryValue = 0.0,
    int? totalProducts,
    int? totalVariants,
    int? totalUnits,
    int? lowStockCount,
    int? outOfStockCount,
    int? expiringSoonCount,
  })  : _totalProducts = totalProducts,
        _lowStockCount = lowStockCount,
        _outOfStockCount = outOfStockCount;

  final int totalItemsInStock;
  final int totalItemsLowStock;
  final int totalItemsOutOfStock;
  final double totalInventoryValue;
  final int? _totalProducts;
  final int? _lowStockCount;
  final int? _outOfStockCount;

  int get totalProducts =>
      _totalProducts ??
      (totalItemsInStock + totalItemsLowStock + totalItemsOutOfStock);
  int get lowStockCount => _lowStockCount ?? totalItemsLowStock;
  int get outOfStockCount => _outOfStockCount ?? totalItemsOutOfStock;
  int get totalVariants => totalProducts;
  int get totalUnits => totalItemsInStock;
  int get expiringSoonCount => 0;
}

class CurrentStockItem {
  const CurrentStockItem({
    this.inventoryBalanceId,
    this.inventoryLocationId,
    this.outletId,
    this.outletName,
    this.productId,
    this.productName,
    this.variantId,
    this.variantName,
    this.variantOptions,
    this.sku,
    this.barcode,
    this.onHandQuantity = 0.0,
    this.reservedQuantity = 0.0,
    this.damagedQuantity = 0.0,
    this.quarantineQuantity = 0.0,
    this.availableQuantity = 0.0,
    this.stockStatus = 'InStock',
    this.expiryStatus = 'Normal',
    this.reorderLevel = 0.0,
    this.imageUrl,
    this.rowVersion,
  });

  final String? inventoryBalanceId;
  final String? inventoryLocationId;
  final String? outletId;
  final String? outletName;
  final String? productId;
  final String? productName;
  final String? variantId;
  final String? variantName;
  final List<String>? variantOptions;
  final String? sku;
  final String? barcode;
  final double onHandQuantity;
  final double reservedQuantity;
  final double damagedQuantity;
  final double quarantineQuantity;
  final double availableQuantity;
  final String stockStatus;
  final String expiryStatus;
  final double reorderLevel;
  final String? imageUrl;
  final int? rowVersion;

  List<Object?> get props => [
        inventoryBalanceId,
        inventoryLocationId,
        outletId,
        outletName,
        productId,
        productName,
        variantId,
        variantName,
        variantOptions,
        sku,
        barcode,
        onHandQuantity,
        reservedQuantity,
        damagedQuantity,
        quarantineQuantity,
        availableQuantity,
        stockStatus,
        expiryStatus,
        reorderLevel,
        imageUrl,
        rowVersion,
      ];
}

class CurrentStockPage {
  const CurrentStockPage({
    this.items = const [],
    this.page = 1,
    this.pageSize = 5,
    this.totalCount = 0,
  });

  final List<CurrentStockItem> items;
  final int page;
  final int pageSize;
  final int totalCount;
}

class ProductStockDetail {
  const ProductStockDetail({
    this.productId,
    this.productName,
    this.productVariantId,
    this.variantName,
    this.sku,
    this.categoryName,
    this.productStatus,
    this.stockStatus,
    this.batchTrackingEnabled = false,
    this.imageUrl,
    this.totalOnHand = 0.0,
    this.totalReserved = 0.0,
    this.totalAvailable = 0.0,
    this.totalReorderLevel = 0.0,
    this.locationBalances = const [],
  });

  final String? productId;
  final String? productName;
  final String? productVariantId;
  final String? variantName;
  final String? sku;
  final String? categoryName;
  final String? productStatus;
  final String? stockStatus;
  final bool batchTrackingEnabled;
  final String? imageUrl;
  final double totalOnHand;
  final double totalReserved;
  final double totalAvailable;
  final double totalReorderLevel;
  final List<LocationBalance> locationBalances;
}

class LocationBalance {
  const LocationBalance({
    this.locationId,
    this.locationName,
    this.onHand = 0.0,
    this.reserved = 0.0,
    this.available = 0.0,
    this.reorderLevel = 0.0,
  });

  final String? locationId;
  final String? locationName;
  final double onHand;
  final double reserved;
  final double available;
  final double reorderLevel;
}

class StockMovementHistory {
  const StockMovementHistory({
    this.movementId,
    this.movementType,
    this.reference,
    this.locationName,
    this.date,
    this.change = 0.0,
  });

  final String? movementId;
  final String? movementType;
  final String? reference;
  final String? locationName;
  final DateTime? date;
  final double change;
}

class StockMovementHistoryPage {
  const StockMovementHistoryPage({
    required this.items,
    required this.totalCount,
    required this.page,
    required this.pageSize,
  });

  final List<StockMovementHistory> items;
  final int totalCount;
  final int page;
  final int pageSize;
}
