class CurrentStockQuery {
  const CurrentStockQuery({
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

  bool get hasActiveFilters {
    return (outletId != null && outletId!.isNotEmpty) ||
        (search != null && search!.trim().isNotEmpty) ||
        (stockStatus != null && stockStatus!.isNotEmpty) ||
        (categoryId != null && categoryId!.isNotEmpty) ||
        (batchNumber != null && batchNumber!.trim().isNotEmpty) ||
        (expiryStatus != null && expiryStatus!.isNotEmpty);
  }
}

class CurrentStockVariantOption {
  const CurrentStockVariantOption({
    required this.name,
    required this.value,
  });

  final String name;
  final String value;
}

class CurrentStockItem {
  const CurrentStockItem({
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

  final String inventoryBalanceId;
  final String inventoryLocationId;
  final String outletId;
  final String outletName;
  final String productId;
  final String productName;
  final String? productVariantId;
  final String? variantName;
  final List<CurrentStockVariantOption> variantOptions;
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

  String get displayVariant {
    if (variantName != null && variantName!.trim().isNotEmpty) {
      return variantName!;
    }

    if (variantOptions.isEmpty) {
      return '—';
    }

    return variantOptions.map((option) => option.value).join(' / ');
  }
}

class CurrentStockPage {
  const CurrentStockPage({
    required this.items,
    required this.page,
    required this.pageSize,
    required this.totalCount,
  });

  final List<CurrentStockItem> items;
  final int page;
  final int pageSize;
  final int totalCount;
}

class CurrentStockSummary {
  const CurrentStockSummary({
    required this.totalProducts,
    required this.totalVariants,
    required this.totalUnits,
    required this.lowStockCount,
    required this.outOfStockCount,
    required this.expiringSoonCount,
  });

  final int totalProducts;
  final int totalVariants;
  final double totalUnits;
  final int lowStockCount;
  final int outOfStockCount;
  final int expiringSoonCount;
}

class StockInLineInput {
  const StockInLineInput({
    this.productId,
    this.productName,
    this.productVariantId,
    this.variantName,
    this.isBatchTracked = false,
    this.isExpiryTracked = false,
    this.batchNumber,
    this.manufacturedDate,
    this.expiryDate,
    this.quantity,
    this.unitCost,
    this.barcode,
  });

  final String? productId;
  final String? productName;
  final String? productVariantId;
  final String? variantName;
  final bool isBatchTracked;
  final bool isExpiryTracked;
  final String? batchNumber;
  final DateTime? manufacturedDate;
  final DateTime? expiryDate;
  final double? quantity;
  final double? unitCost;
  final String? barcode;

  StockInLineInput copyWith({
    String? productId,
    String? productName,
    String? productVariantId,
    String? variantName,
    bool? isBatchTracked,
    bool? isExpiryTracked,
    String? batchNumber,
    DateTime? manufacturedDate,
    DateTime? expiryDate,
    double? quantity,
    double? unitCost,
    String? barcode,
    bool clearProduct = false,
    bool clearVariant = false,
  }) {
    return StockInLineInput(
      productId: clearProduct ? null : productId ?? this.productId,
      productName: clearProduct ? null : productName ?? this.productName,
      productVariantId:
          clearVariant ? null : productVariantId ?? this.productVariantId,
      variantName: clearVariant ? null : variantName ?? this.variantName,
      isBatchTracked: isBatchTracked ?? this.isBatchTracked,
      isExpiryTracked: isExpiryTracked ?? this.isExpiryTracked,
      batchNumber: batchNumber ?? this.batchNumber,
      manufacturedDate: manufacturedDate ?? this.manufacturedDate,
      expiryDate: expiryDate ?? this.expiryDate,
      quantity: quantity ?? this.quantity,
      unitCost: unitCost ?? this.unitCost,
      barcode: barcode ?? this.barcode,
    );
  }
}

class StockInFormInput {
  const StockInFormInput({
    this.outletId,
    this.referenceNumber = '',
    this.receivedAt,
    this.notes = '',
    this.items = const [StockInLineInput()],
  });

  final String? outletId;
  final String referenceNumber;
  final DateTime? receivedAt;
  final String notes;
  final List<StockInLineInput> items;

  StockInFormInput copyWith({
    String? outletId,
    String? referenceNumber,
    DateTime? receivedAt,
    String? notes,
    List<StockInLineInput>? items,
  }) {
    return StockInFormInput(
      outletId: outletId ?? this.outletId,
      referenceNumber: referenceNumber ?? this.referenceNumber,
      receivedAt: receivedAt ?? this.receivedAt,
      notes: notes ?? this.notes,
      items: items ?? this.items,
    );
  }
}

class StockInResult {
  const StockInResult({
    required this.operationId,
    required this.outletId,
    required this.outletName,
    this.referenceNumber,
    required this.receivedAt,
    required this.itemCount,
    required this.totalQuantity,
    required this.status,
    required this.createdAt,
  });

  final String operationId;
  final String outletId;
  final String outletName;
  final String? referenceNumber;
  final String receivedAt;
  final int itemCount;
  final double totalQuantity;
  final String status;
  final String createdAt;
}

class VariantOptionValue {
  const VariantOptionValue({
    required this.attributeName,
    required this.value,
  });

  final String attributeName;
  final String value;
}

class VariantLookupItem {
  const VariantLookupItem({
    required this.id,
    required this.name,
    this.sku,
    this.barcode,
    required this.status,
    required this.isBatchTracked,
    required this.isExpiryTracked,
    required this.optionValues,
  });

  final String id;
  final String name;
  final String? sku;
  final String? barcode;
  final String status;
  final bool isBatchTracked;
  final bool isExpiryTracked;
  final List<VariantOptionValue> optionValues;

  String get displayLabel {
    if (optionValues.isEmpty) {
      return name;
    }

    final options = optionValues.map((item) => item.value).join(' / ');
    return '$name ($options)';
  }
}

class VariantLookup {
  const VariantLookup({
    required this.productId,
    required this.productName,
    required this.isBatchTracked,
    required this.isExpiryTracked,
    required this.variants,
  });

  final String productId;
  final String productName;
  final bool isBatchTracked;
  final bool isExpiryTracked;
  final List<VariantLookupItem> variants;
}

class AccessibleOutletOption {
  const AccessibleOutletOption({
    required this.id,
    required this.name,
    required this.isDefault,
  });

  final String id;
  final String name;
  final bool isDefault;
}
