import '../constants/inventory_api_paths.dart';

class CurrentStockQueryDto {
  const CurrentStockQueryDto({
    this.outletId,
    this.search,
    this.stockStatus,
    this.categoryId,
    this.batchNumber,
    this.expiryStatus,
    this.page = 1,
    this.pageSize = 50,
    this.sortBy,
    this.sortDirection,
  });

  final String? outletId;
  final String? search;
  final String? stockStatus;
  final String? categoryId;
  final String? batchNumber;
  final String? expiryStatus;
  final int page;
  final int pageSize;
  final String? sortBy;
  final String? sortDirection;

  Map<String, dynamic> toQueryParameters() {
    return {
      'page': page,
      'pageSize': pageSize,
      if (outletId != null && outletId!.trim().isNotEmpty) 'outletId': outletId,
      if (search != null && search!.trim().isNotEmpty) 'search': search!.trim(),
      if (stockStatus != null &&
          stockStatus!.trim().isNotEmpty &&
          stockStatus != InventoryStockStatusFilter.all)
        'stockStatus': stockStatus!.trim(),
      if (categoryId != null && categoryId!.trim().isNotEmpty)
        'categoryId': categoryId,
      if (batchNumber != null && batchNumber!.trim().isNotEmpty)
        'batchNumber': batchNumber!.trim(),
      if (expiryStatus != null &&
          expiryStatus!.trim().isNotEmpty &&
          expiryStatus != InventoryExpiryStatusFilter.all)
        'expiryStatus': expiryStatus!.trim(),
      if (sortBy != null && sortBy!.trim().isNotEmpty) 'sortBy': sortBy!.trim(),
      if (sortDirection != null && sortDirection!.trim().isNotEmpty)
        'sortDirection': sortDirection!.trim(),
    };
  }
}

class CurrentStockVariantOptionDto {
  const CurrentStockVariantOptionDto({
    required this.name,
    required this.value,
  });

  factory CurrentStockVariantOptionDto.fromJson(Map<String, dynamic> json) {
    return CurrentStockVariantOptionDto(
      name: json['name'] as String? ?? '',
      value: json['value'] as String? ?? '',
    );
  }

  final String name;
  final String value;
}

class CurrentStockItemDto {
  const CurrentStockItemDto({
    required this.inventoryBalanceId,
    required this.inventoryLocationId,
    required this.outletId,
    required this.outletName,
    required this.productId,
    required this.productName,
    this.productVariantId,
    this.variantName,
    required this.variantOptions,
    this.sku,
    this.barcode,
    this.productBatchId,
    this.batchNumber,
    this.expiryDate,
    required this.onHandQuantity,
    required this.reservedQuantity,
    required this.damagedQuantity,
    required this.quarantineQuantity,
    required this.availableQuantity,
    required this.stockStatus,
    required this.expiryStatus,
    this.lastMovementAt,
    required this.rowVersion,
  });

  factory CurrentStockItemDto.fromJson(Map<String, dynamic> json) {
    return CurrentStockItemDto(
      inventoryBalanceId: json['inventoryBalanceId']?.toString() ?? '',
      inventoryLocationId: json['inventoryLocationId']?.toString() ?? '',
      outletId: json['outletId']?.toString() ?? '',
      outletName: json['outletName'] as String? ?? '',
      productId: json['productId']?.toString() ?? '',
      productName: json['productName'] as String? ?? '',
      productVariantId: _nullableString(json['productVariantId']),
      variantName: _nullableString(json['variantName']),
      variantOptions: _mapList(
        json['variantOptions'],
        CurrentStockVariantOptionDto.fromJson,
      ),
      sku: _nullableString(json['sku']),
      barcode: _nullableString(json['barcode']),
      productBatchId: _nullableString(json['productBatchId']),
      batchNumber: _nullableString(json['batchNumber']),
      expiryDate: _nullableString(json['expiryDate']),
      onHandQuantity: _decimalValue(json['onHandQuantity']),
      reservedQuantity: _decimalValue(json['reservedQuantity']),
      damagedQuantity: _decimalValue(json['damagedQuantity']),
      quarantineQuantity: _decimalValue(json['quarantineQuantity']),
      availableQuantity: _decimalValue(json['availableQuantity']),
      stockStatus:
          json['stockStatus'] as String? ?? InventoryStockStatus.unknown,
      expiryStatus:
          json['expiryStatus'] as String? ?? InventoryExpiryStatus.unknown,
      lastMovementAt: _nullableString(json['lastMovementAt']),
      rowVersion: _intValue(json['rowVersion']),
    );
  }

  final String inventoryBalanceId;
  final String inventoryLocationId;
  final String outletId;
  final String outletName;
  final String productId;
  final String productName;
  final String? productVariantId;
  final String? variantName;
  final List<CurrentStockVariantOptionDto> variantOptions;
  final String? sku;
  final String? barcode;
  final String? productBatchId;
  final String? batchNumber;
  final String? expiryDate;
  final double onHandQuantity;
  final double reservedQuantity;
  final double damagedQuantity;
  final double quarantineQuantity;
  final double availableQuantity;
  final String stockStatus;
  final String expiryStatus;
  final String? lastMovementAt;
  final int rowVersion;
}

class CurrentStockPageDto {
  const CurrentStockPageDto({
    required this.items,
    required this.page,
    required this.pageSize,
    required this.totalCount,
  });

  factory CurrentStockPageDto.fromJson(Map<String, dynamic> json) {
    final items = _mapList(json['items'], CurrentStockItemDto.fromJson);
    return CurrentStockPageDto(
      items: items,
      page: _intValue(json['page'], fallback: 1),
      pageSize: _intValue(json['pageSize'], fallback: 50),
      totalCount: _intValue(json['totalCount'], fallback: items.length),
    );
  }

  final List<CurrentStockItemDto> items;
  final int page;
  final int pageSize;
  final int totalCount;
}

class CurrentStockSummaryDto {
  const CurrentStockSummaryDto({
    required this.totalProducts,
    required this.totalVariants,
    required this.totalUnits,
    required this.lowStockCount,
    required this.outOfStockCount,
    required this.expiringSoonCount,
  });

  factory CurrentStockSummaryDto.fromJson(Map<String, dynamic> json) {
    return CurrentStockSummaryDto(
      totalProducts: _intValue(json['totalProducts']),
      totalVariants: _intValue(json['totalVariants']),
      totalUnits: _decimalValue(json['totalUnits']),
      lowStockCount: _intValue(json['lowStockCount']),
      outOfStockCount: _intValue(json['outOfStockCount']),
      expiringSoonCount: _intValue(json['expiringSoonCount']),
    );
  }

  final int totalProducts;
  final int totalVariants;
  final double totalUnits;
  final int lowStockCount;
  final int outOfStockCount;
  final int expiringSoonCount;
}

class StockInLineRequestDto {
  const StockInLineRequestDto({
    required this.productVariantId,
    this.batchNumber,
    this.manufacturedDate,
    this.expiryDate,
    required this.quantity,
    this.unitCost,
    this.barcode,
  });

  Map<String, dynamic> toJson() {
    return {
      'productVariantId': productVariantId,
      if (batchNumber != null) 'batchNumber': batchNumber,
      if (manufacturedDate != null) 'manufacturedDate': manufacturedDate,
      if (expiryDate != null) 'expiryDate': expiryDate,
      'quantity': quantity,
      if (unitCost != null) 'unitCost': unitCost,
      if (barcode != null) 'barcode': barcode,
    };
  }

  final String productVariantId;
  final String? batchNumber;
  final String? manufacturedDate;
  final String? expiryDate;
  final double quantity;
  final double? unitCost;
  final String? barcode;
}

class CreateStockInRequestDto {
  const CreateStockInRequestDto({
    required this.outletId,
    this.referenceNumber,
    this.receivedAt,
    this.notes,
    this.idempotencyKey,
    required this.items,
  });

  Map<String, dynamic> toJson() {
    return {
      'outletId': outletId,
      if (referenceNumber != null) 'referenceNumber': referenceNumber,
      if (receivedAt != null) 'receivedAt': receivedAt,
      if (notes != null) 'notes': notes,
      if (idempotencyKey != null) 'idempotencyKey': idempotencyKey,
      'items': items.map((item) => item.toJson()).toList(),
    };
  }

  final String outletId;
  final String? referenceNumber;
  final String? receivedAt;
  final String? notes;
  final String? idempotencyKey;
  final List<StockInLineRequestDto> items;
}

class StockInLineResponseDto {
  const StockInLineResponseDto({
    required this.productVariantId,
    required this.variantName,
    this.productBatchId,
    this.batchNumber,
    required this.quantityReceived,
    required this.onHandAfter,
    required this.availableAfter,
    required this.stockMovementId,
  });

  factory StockInLineResponseDto.fromJson(Map<String, dynamic> json) {
    return StockInLineResponseDto(
      productVariantId: json['productVariantId']?.toString() ?? '',
      variantName: json['variantName'] as String? ?? '',
      productBatchId: _nullableString(json['productBatchId']),
      batchNumber: _nullableString(json['batchNumber']),
      quantityReceived: _decimalValue(json['quantityReceived']),
      onHandAfter: _decimalValue(json['onHandAfter']),
      availableAfter: _decimalValue(json['availableAfter']),
      stockMovementId: json['stockMovementId']?.toString() ?? '',
    );
  }

  final String productVariantId;
  final String variantName;
  final String? productBatchId;
  final String? batchNumber;
  final double quantityReceived;
  final double onHandAfter;
  final double availableAfter;
  final String stockMovementId;
}

class StockInResponseDto {
  const StockInResponseDto({
    required this.operationId,
    required this.outletId,
    required this.outletName,
    this.referenceNumber,
    required this.receivedAt,
    required this.itemCount,
    required this.totalQuantity,
    required this.status,
    required this.items,
    required this.createdAt,
  });

  factory StockInResponseDto.fromJson(Map<String, dynamic> json) {
    return StockInResponseDto(
      operationId: json['operationId']?.toString() ?? '',
      outletId: json['outletId']?.toString() ?? '',
      outletName: json['outletName'] as String? ?? '',
      referenceNumber: _nullableString(json['referenceNumber']),
      receivedAt: json['receivedAt']?.toString() ?? '',
      itemCount: _intValue(json['itemCount']),
      totalQuantity: _decimalValue(json['totalQuantity']),
      status: json['status'] as String? ?? '',
      items: _mapList(json['items'], StockInLineResponseDto.fromJson),
      createdAt: json['createdAt']?.toString() ?? '',
    );
  }

  final String operationId;
  final String outletId;
  final String outletName;
  final String? referenceNumber;
  final String receivedAt;
  final int itemCount;
  final double totalQuantity;
  final String status;
  final List<StockInLineResponseDto> items;
  final String createdAt;
}

class VariantOptionValueDto {
  const VariantOptionValueDto({
    required this.attributeName,
    required this.value,
  });

  factory VariantOptionValueDto.fromJson(Map<String, dynamic> json) {
    return VariantOptionValueDto(
      attributeName: json['attributeName'] as String? ?? '',
      value: json['value'] as String? ?? '',
    );
  }

  final String attributeName;
  final String value;
}

class VariantLookupItemDto {
  const VariantLookupItemDto({
    required this.id,
    required this.name,
    this.sku,
    this.barcode,
    required this.status,
    required this.isBatchTracked,
    required this.isExpiryTracked,
    required this.optionValues,
  });

  factory VariantLookupItemDto.fromJson(Map<String, dynamic> json) {
    return VariantLookupItemDto(
      id: json['id']?.toString() ?? '',
      name: json['name'] as String? ?? '',
      sku: _nullableString(json['sku']),
      barcode: _nullableString(json['barcode']),
      status: json['status'] as String? ?? '',
      isBatchTracked: json['isBatchTracked'] as bool? ?? false,
      isExpiryTracked: json['isExpiryTracked'] as bool? ?? false,
      optionValues:
          _mapList(json['optionValues'], VariantOptionValueDto.fromJson),
    );
  }

  final String id;
  final String name;
  final String? sku;
  final String? barcode;
  final String status;
  final bool isBatchTracked;
  final bool isExpiryTracked;
  final List<VariantOptionValueDto> optionValues;
}

class VariantLookupDto {
  const VariantLookupDto({
    required this.productId,
    required this.productName,
    required this.isBatchTracked,
    required this.isExpiryTracked,
    required this.variants,
  });

  factory VariantLookupDto.fromJson(Map<String, dynamic> json) {
    return VariantLookupDto(
      productId: json['productId']?.toString() ?? '',
      productName: json['productName'] as String? ?? '',
      isBatchTracked: json['isBatchTracked'] as bool? ?? false,
      isExpiryTracked: json['isExpiryTracked'] as bool? ?? false,
      variants: _mapList(json['variants'], VariantLookupItemDto.fromJson),
    );
  }

  final String productId;
  final String productName;
  final bool isBatchTracked;
  final bool isExpiryTracked;
  final List<VariantLookupItemDto> variants;
}

String? _nullableString(Object? value) {
  if (value == null) {
    return null;
  }

  final text = value.toString().trim();
  return text.isEmpty ? null : text;
}

double _decimalValue(Object? value, {double fallback = 0}) {
  if (value is num) {
    return value.toDouble();
  }

  if (value is String) {
    return double.tryParse(value) ?? fallback;
  }

  return fallback;
}

int _intValue(Object? value, {int fallback = 0}) {
  if (value is int) {
    return value;
  }

  if (value is num) {
    return value.toInt();
  }

  if (value is String) {
    return int.tryParse(value) ?? fallback;
  }

  return fallback;
}

List<T> _mapList<T>(
  Object? value,
  T Function(Map<String, dynamic> json) mapper,
) {
  if (value is! List) {
    return const [];
  }

  return value
      .whereType<Map>()
      .map((item) => mapper(Map<String, dynamic>.from(item)))
      .toList();
}
