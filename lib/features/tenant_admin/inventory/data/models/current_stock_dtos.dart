import '../../domain/entities/current_stock_entities.dart';

class CurrentStockQueryDto {
  const CurrentStockQueryDto({
    this.outletId,
    this.search,
    this.stockStatus,
    this.expiryStatus,
    this.batchNumber,
    this.page = 1,
    this.pageSize = 10,
    this.sortBy,
    this.sortDirection,
  });

  final String? outletId;
  final String? search;
  final String? stockStatus;
  final String? expiryStatus;
  final String? batchNumber;
  final int page;
  final int pageSize;
  final String? sortBy;
  final String? sortDirection;

  Map<String, dynamic> toQueryParameters() {
    return {
      if (outletId != null) 'outletId': outletId,
      if (search != null) 'search': search,
      if (stockStatus != null) 'stockStatus': stockStatus,
      if (expiryStatus != null) 'expiryStatus': expiryStatus,
      if (batchNumber != null) 'batchNumber': batchNumber,
      'page': page,
      'pageSize': pageSize,
      if (sortBy != null) 'sortBy': sortBy,
      if (sortDirection != null) 'sortDirection': sortDirection,
    };
  }
}

class CurrentStockSummaryDto {
  const CurrentStockSummaryDto({
    this.totalItemsInStock = 0,
    this.totalItemsLowStock = 0,
    this.totalItemsOutOfStock = 0,
    this.totalInventoryValue = 0.0,
  });

  factory CurrentStockSummaryDto.fromJson(Map<String, dynamic> json) {
    return CurrentStockSummaryDto(
      totalItemsInStock: (json['totalItemsInStock'] as num?)?.toInt() ?? 0,
      totalItemsLowStock: (json['totalItemsLowStock'] as num?)?.toInt() ?? 0,
      totalItemsOutOfStock: (json['totalItemsOutOfStock'] as num?)?.toInt() ?? 0,
      totalInventoryValue: (json['totalInventoryValue'] as num?)?.toDouble() ?? 0.0,
    );
  }

  final int totalItemsInStock;
  final int totalItemsLowStock;
  final int totalItemsOutOfStock;
  final double totalInventoryValue;

  CurrentStockSummary toDomain() {
    return CurrentStockSummary(
      totalItemsInStock: totalItemsInStock,
      totalItemsLowStock: totalItemsLowStock,
      totalItemsOutOfStock: totalItemsOutOfStock,
      totalInventoryValue: totalInventoryValue,
    );
  }
}

class CurrentStockItemDto {
  const CurrentStockItemDto({
    this.inventoryBalanceId,
    this.outletId,
    this.productId,
    this.productName,
    this.variantId,
    this.variantName,
    this.sku,
    this.barcode,
    this.onHandQuantity = 0.0,
    this.reservedQuantity = 0.0,
    this.damagedQuantity = 0.0,
    this.quarantineQuantity = 0.0,
    this.availableQuantity = 0.0,
    this.stockStatus,
    this.expiryStatus,
    this.reorderLevel = 0.0,
    this.imageUrl,
  });

  factory CurrentStockItemDto.fromJson(Map<String, dynamic> json) {
    return CurrentStockItemDto(
      inventoryBalanceId: json['inventoryBalanceId'] as String?,
      outletId: json['outletId'] as String?,
      productId: json['productId'] as String?,
      productName: json['productName'] as String?,
      variantId: json['variantId'] as String?,
      variantName: json['variantName'] as String?,
      sku: json['sku'] as String?,
      barcode: json['barcode'] as String?,
      onHandQuantity: (json['onHandQuantity'] as num?)?.toDouble() ?? 0.0,
      reservedQuantity: (json['reservedQuantity'] as num?)?.toDouble() ?? 0.0,
      damagedQuantity: (json['damagedQuantity'] as num?)?.toDouble() ?? 0.0,
      quarantineQuantity: (json['quarantineQuantity'] as num?)?.toDouble() ?? 0.0,
      availableQuantity: (json['availableQuantity'] as num?)?.toDouble() ?? 0.0,
      stockStatus: json['stockStatus'] as String?,
      expiryStatus: json['expiryStatus'] as String?,
      reorderLevel: (json['reorderLevel'] as num?)?.toDouble() ?? 0.0,
      imageUrl: json['imageUrl'] as String?,
    );
  }

  final String? inventoryBalanceId;
  final String? outletId;
  final String? productId;
  final String? productName;
  final String? variantId;
  final String? variantName;
  final String? sku;
  final String? barcode;
  final double onHandQuantity;
  final double reservedQuantity;
  final double damagedQuantity;
  final double quarantineQuantity;
  final double availableQuantity;
  final String? stockStatus;
  final String? expiryStatus;
  final double reorderLevel;
  final String? imageUrl;

  CurrentStockItem toDomain() {
    return CurrentStockItem(
      inventoryBalanceId: inventoryBalanceId,
      outletId: outletId,
      productId: productId,
      productName: productName,
      variantId: variantId,
      variantName: variantName,
      sku: sku,
      barcode: barcode,
      onHandQuantity: onHandQuantity,
      reservedQuantity: reservedQuantity,
      damagedQuantity: damagedQuantity,
      quarantineQuantity: quarantineQuantity,
      availableQuantity: availableQuantity,
      stockStatus: stockStatus ?? 'InStock',
      expiryStatus: expiryStatus ?? 'Normal',
      reorderLevel: reorderLevel,
      imageUrl: imageUrl,
    );
  }
}

class CurrentStockPageDto {
  const CurrentStockPageDto({
    required this.items,
    required this.totalCount,
    required this.page,
    required this.pageSize,
  });

  factory CurrentStockPageDto.fromJson(Map<String, dynamic> json) {
    return CurrentStockPageDto(
      items: (json['items'] as List<dynamic>?)
              ?.map((e) => CurrentStockItemDto.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      totalCount: (json['totalCount'] as num?)?.toInt() ?? 0,
      page: (json['page'] as num?)?.toInt() ?? 1,
      pageSize: (json['pageSize'] as num?)?.toInt() ?? 10,
    );
  }

  final List<CurrentStockItemDto> items;
  final int totalCount;
  final int page;
  final int pageSize;

  CurrentStockPage toDomain() {
    return CurrentStockPage(
      items: items.map((e) => e.toDomain()).toList(),
      totalCount: totalCount,
      page: page,
      pageSize: pageSize,
    );
  }
}

class ProductStockDetailDto {
  const ProductStockDetailDto({
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

  factory ProductStockDetailDto.fromJson(Map<String, dynamic> json) {
    return ProductStockDetailDto(
      productId: json['productId'] as String?,
      productName: json['productName'] as String?,
      productVariantId: json['productVariantId'] as String?,
      variantName: json['variantName'] as String?,
      sku: json['sku'] as String?,
      categoryName: json['categoryName'] as String?,
      productStatus: json['productStatus'] as String?,
      stockStatus: json['stockStatus'] as String?,
      batchTrackingEnabled: json['batchTrackingEnabled'] as bool? ?? false,
      imageUrl: json['imageUrl'] as String?,
      totalOnHand: (json['totalOnHand'] as num?)?.toDouble() ?? 0.0,
      totalReserved: (json['totalReserved'] as num?)?.toDouble() ?? 0.0,
      totalAvailable: (json['totalAvailable'] as num?)?.toDouble() ?? 0.0,
      totalReorderLevel: (json['totalReorderLevel'] as num?)?.toDouble() ?? 0.0,
      locationBalances: (json['locationBalances'] as List<dynamic>?)
              ?.map((e) => LocationBalanceDto.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

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
  final List<LocationBalanceDto> locationBalances;

  ProductStockDetail toDomain() {
    return ProductStockDetail(
      productId: productId,
      productName: productName,
      productVariantId: productVariantId,
      variantName: variantName,
      sku: sku,
      categoryName: categoryName,
      productStatus: productStatus,
      stockStatus: stockStatus,
      batchTrackingEnabled: batchTrackingEnabled,
      imageUrl: imageUrl,
      totalOnHand: totalOnHand,
      totalReserved: totalReserved,
      totalAvailable: totalAvailable,
      totalReorderLevel: totalReorderLevel,
      locationBalances: locationBalances.map((e) => e.toDomain()).toList(),
    );
  }
}

class LocationBalanceDto {
  const LocationBalanceDto({
    this.locationId,
    this.locationName,
    this.onHand = 0.0,
    this.reserved = 0.0,
    this.available = 0.0,
    this.reorderLevel = 0.0,
  });

  factory LocationBalanceDto.fromJson(Map<String, dynamic> json) {
    return LocationBalanceDto(
      locationId: json['locationId'] as String?,
      locationName: json['locationName'] as String?,
      onHand: (json['onHand'] as num?)?.toDouble() ?? 0.0,
      reserved: (json['reserved'] as num?)?.toDouble() ?? 0.0,
      available: (json['available'] as num?)?.toDouble() ?? 0.0,
      reorderLevel: (json['reorderLevel'] as num?)?.toDouble() ?? 0.0,
    );
  }

  final String? locationId;
  final String? locationName;
  final double onHand;
  final double reserved;
  final double available;
  final double reorderLevel;

  LocationBalance toDomain() {
    return LocationBalance(
      locationId: locationId,
      locationName: locationName,
      onHand: onHand,
      reserved: reserved,
      available: available,
      reorderLevel: reorderLevel,
    );
  }
}

class StockMovementHistoryDto {
  const StockMovementHistoryDto({
    this.movementId,
    this.movementType,
    this.reference,
    this.locationName,
    this.date,
    this.change = 0.0,
  });

  factory StockMovementHistoryDto.fromJson(Map<String, dynamic> json) {
    return StockMovementHistoryDto(
      movementId: json['movementId'] as String?,
      movementType: json['movementType'] as String?,
      reference: json['reference'] as String?,
      locationName: json['locationName'] as String?,
      date: json['date'] != null ? DateTime.tryParse(json['date'] as String) : null,
      change: (json['change'] as num?)?.toDouble() ?? 0.0,
    );
  }

  final String? movementId;
  final String? movementType;
  final String? reference;
  final String? locationName;
  final DateTime? date;
  final double change;

  StockMovementHistory toDomain() {
    return StockMovementHistory(
      movementId: movementId,
      movementType: movementType,
      reference: reference,
      locationName: locationName,
      date: date,
      change: change,
    );
  }
}

class StockMovementHistoryPageDto {
  const StockMovementHistoryPageDto({
    required this.items,
    required this.totalCount,
    required this.page,
    required this.pageSize,
  });

  factory StockMovementHistoryPageDto.fromJson(Map<String, dynamic> json) {
    return StockMovementHistoryPageDto(
      items: (json['items'] as List<dynamic>?)
              ?.map((e) => StockMovementHistoryDto.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      totalCount: (json['totalCount'] as num?)?.toInt() ?? 0,
      page: (json['page'] as num?)?.toInt() ?? 1,
      pageSize: (json['pageSize'] as num?)?.toInt() ?? 10,
    );
  }

  final List<StockMovementHistoryDto> items;
  final int totalCount;
  final int page;
  final int pageSize;

  StockMovementHistoryPage toDomain() {
    return StockMovementHistoryPage(
      items: items.map((e) => e.toDomain()).toList(),
      totalCount: totalCount,
      page: page,
      pageSize: pageSize,
    );
  }
}

class StockMovementHistoryQueryDto {
  const StockMovementHistoryQueryDto({
    this.outletId,
    this.page = 1,
    this.pageSize = 10,
  });

  final String? outletId;
  final int page;
  final int pageSize;

  Map<String, dynamic> toQueryParameters() {
    return {
      if (outletId != null) 'outletId': outletId,
      'page': page.toString(),
      'pageSize': pageSize.toString(),
    };
  }
}
