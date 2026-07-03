class InventoryLocation {
  const InventoryLocation({
    required this.id,
    required this.name,
    this.code,
  });

  final String id;
  final String name;
  final String? code;
}

class StockProductOption {
  const StockProductOption({
    required this.productId,
    required this.name,
    required this.variants,
    this.primarySku,
  });

  final String productId;
  final String name;
  final List<StockVariantOption> variants;
  final String? primarySku;

  String get displayLabel {
    final sku = primarySku?.trim();
    if (sku == null || sku.isEmpty) {
      return name;
    }

    return '$name ($sku)';
  }

  String? get unitOfMeasure {
    for (final variant in variants) {
      final unit = variant.unitOfMeasure?.trim();
      if (unit != null && unit.isNotEmpty) {
        return unit;
      }
    }

    return null;
  }
}

class StockVariantOption {
  const StockVariantOption({
    required this.variantId,
    required this.label,
    required this.sku,
    this.unitOfMeasure,
  });

  final String variantId;
  final String label;
  final String sku;
  final String? unitOfMeasure;
}

class InventoryBalanceSummary {
  const InventoryBalanceSummary({
    this.onHand,
    this.reserved,
    this.available,
    this.lowStockItems,
  });

  final num? onHand;
  final num? reserved;
  final num? available;
  final int? lowStockItems;
}

class InventoryBalanceRow {
  const InventoryBalanceRow({
    required this.productId,
    required this.productName,
    required this.variantId,
    required this.variantLabel,
    required this.onHand,
    required this.reserved,
    this.available,
    this.lowStockThreshold,
  });

  final String productId;
  final String productName;
  final String variantId;
  final String variantLabel;
  final num onHand;
  final num reserved;
  final num? available;
  final num? lowStockThreshold;

  num get displayAvailable => available ?? (onHand - reserved);
}

class InventoryBalanceListResult {
  const InventoryBalanceListResult({
    required this.summary,
    required this.items,
    required this.page,
    required this.pageSize,
    required this.totalCount,
  });

  final InventoryBalanceSummary summary;
  final List<InventoryBalanceRow> items;
  final int page;
  final int pageSize;
  final int totalCount;
}

class InventoryBalanceQuery {
  const InventoryBalanceQuery({
    this.locationId,
    this.search,
    this.page = 1,
    this.pageSize = 10,
    this.lowStockOnly = false,
  });

  final String? locationId;
  final String? search;
  final int page;
  final int pageSize;
  final bool lowStockOnly;
}

class StockInFormData {
  const StockInFormData({
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

  final String productId;
  final String variantId;
  final String inventoryLocationId;
  final double quantity;
  final double? unitCost;
  final String? batchNumber;
  final DateTime? expiryDate;
  final DateTime? manufacturedDate;
  final String? reason;
}
