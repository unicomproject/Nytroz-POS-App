import '../../domain/entities/inventory.dart';

class InventoryLocationDto {
  const InventoryLocationDto({
    required this.id,
    required this.name,
    this.code,
  });

  factory InventoryLocationDto.fromJson(Map<String, dynamic> json) {
    return InventoryLocationDto(
      id: json['id']?.toString() ?? '',
      name: json['name'] as String? ?? '',
      code: json['code'] as String?,
    );
  }

  final String id;
  final String name;
  final String? code;
}

class InventoryBalanceSummaryDto {
  const InventoryBalanceSummaryDto({
    this.onHand,
    this.reserved,
    this.available,
    this.lowStockItems,
  });

  factory InventoryBalanceSummaryDto.fromJson(Map<String, dynamic> json) {
    return InventoryBalanceSummaryDto(
      onHand: _numValue(json['onHand']),
      reserved: _numValue(json['reserved']),
      available: _numValue(json['available']),
      lowStockItems: _intValue(json['lowStockItems']),
    );
  }

  final num? onHand;
  final num? reserved;
  final num? available;
  final int? lowStockItems;
}

class InventoryBalanceRowDto {
  const InventoryBalanceRowDto({
    required this.productId,
    required this.productName,
    required this.variantId,
    required this.variantLabel,
    required this.onHand,
    required this.reserved,
    this.available,
    this.lowStockThreshold,
  });

  factory InventoryBalanceRowDto.fromJson(Map<String, dynamic> json) {
    return InventoryBalanceRowDto(
      productId: json['productId']?.toString() ?? '',
      productName: json['productName'] as String? ?? '',
      variantId: json['variantId']?.toString() ?? '',
      variantLabel: json['variantLabel'] as String? ??
          json['variantName'] as String? ??
          '',
      onHand: _numValue(json['onHand']) ?? 0,
      reserved: _numValue(json['reserved']) ?? 0,
      available: _numValue(json['available']),
      lowStockThreshold: _numValue(json['lowStockThreshold']),
    );
  }

  final String productId;
  final String productName;
  final String variantId;
  final String variantLabel;
  final num onHand;
  final num reserved;
  final num? available;
  final num? lowStockThreshold;
}

class InventoryBalanceListResultDto {
  const InventoryBalanceListResultDto({
    required this.summary,
    required this.items,
    this.page = 1,
    this.pageSize = 10,
    this.totalCount = 0,
  });

  factory InventoryBalanceListResultDto.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'];
    final items = rawItems is List
        ? rawItems
            .whereType<Map>()
            .map(
              (item) => InventoryBalanceRowDto.fromJson(
                Map<String, dynamic>.from(item),
              ),
            )
            .toList(growable: false)
        : const <InventoryBalanceRowDto>[];

    return InventoryBalanceListResultDto(
      summary: json['summary'] is Map
          ? InventoryBalanceSummaryDto.fromJson(
              Map<String, dynamic>.from(json['summary'] as Map),
            )
          : const InventoryBalanceSummaryDto(),
      items: items,
      page: _intValue(json['page'], fallback: 1),
      pageSize: _intValue(json['pageSize'], fallback: 10),
      totalCount: _intValue(json['totalCount'], fallback: items.length),
    );
  }

  final InventoryBalanceSummaryDto summary;
  final List<InventoryBalanceRowDto> items;
  final int page;
  final int pageSize;
  final int totalCount;
}

class StockInRequestDto {
  const StockInRequestDto({
    required this.productId,
    required this.variantId,
    required this.inventoryLocationId,
    required this.quantity,
    this.unitCost,
    this.batchNumber,
    this.expiryDate,
    this.manufacturedDate,
    this.reason,
  });

  factory StockInRequestDto.fromEntity(StockInFormData data) {
    return StockInRequestDto(
      productId: data.productId,
      variantId: data.variantId,
      inventoryLocationId: data.inventoryLocationId,
      quantity: data.quantity,
      unitCost: data.unitCost,
      batchNumber: data.batchNumber,
      expiryDate: data.expiryDate?.toIso8601String(),
      manufacturedDate: data.manufacturedDate?.toIso8601String(),
      reason: data.reason,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'variantId': variantId,
      'inventoryLocationId': inventoryLocationId,
      'quantity': quantity,
      if (unitCost != null) 'unitCost': unitCost,
      if (batchNumber != null && batchNumber!.trim().isNotEmpty)
        'batchNumber': batchNumber,
      if (expiryDate != null) 'expiryDate': expiryDate,
      if (manufacturedDate != null) 'manufacturedDate': manufacturedDate,
      if (reason != null && reason!.trim().isNotEmpty) 'reason': reason,
    };
  }

  final String productId;
  final String variantId;
  final String inventoryLocationId;
  final double quantity;
  final double? unitCost;
  final String? batchNumber;
  final String? expiryDate;
  final String? manufacturedDate;
  final String? reason;
}

num? _numValue(Object? value) {
  if (value is num) {
    return value;
  }

  return num.tryParse(value?.toString() ?? '');
}

int _intValue(Object? value, {int fallback = 0}) {
  if (value is int) {
    return value;
  }

  return int.tryParse(value?.toString() ?? '') ?? fallback;
}
