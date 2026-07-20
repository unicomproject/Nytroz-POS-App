class ReturnExchangeProduct {
  const ReturnExchangeProduct({
    required this.productId,
    required this.name,
    required this.sku,
    required this.stockStatus,
    required this.sellingPrice,
    required this.currencyCode,
    required this.hasVariants,
    required this.enabled,
    this.variantId,
    this.barcode,
    this.variantDisplayName,
    this.imageStorageKey,
    this.availableQuantity,
    this.disabledReason,
  });

  final String productId;
  final String? variantId;
  final String name;
  final String sku;
  final String? barcode;
  final String? variantDisplayName;
  final String? imageStorageKey;
  final String stockStatus;
  final double? availableQuantity;
  final double sellingPrice;
  final String currencyCode;
  final bool hasVariants;
  final bool enabled;
  final String? disabledReason;

  String get selectionKey =>
      variantId == null
          ? productId
          : '$productId::$variantId';

  bool get isOutOfStock =>
      !enabled ||
      stockStatus.trim().toUpperCase() == 'OUTOFSTOCK' ||
      (availableQuantity != null && availableQuantity! <= 0);

  factory ReturnExchangeProduct.fromJson(Map<String, dynamic> json) {
    return ReturnExchangeProduct(
      productId: json['productId']?.toString() ?? '',
      variantId: json['variantId']?.toString(),
      name: json['name']?.toString() ?? '',
      sku: json['sku']?.toString() ?? '',
      barcode: json['barcode']?.toString(),
      variantDisplayName: json['variantDisplayName']?.toString(),
      imageStorageKey:
          json['imageStorageKey']?.toString() ?? json['imageUrl']?.toString(),
      stockStatus: json['stockStatus']?.toString() ?? 'InStock',
      availableQuantity: _readDouble(json['availableQuantity']),
      sellingPrice: _readDouble(json['sellingPrice']) ?? 0,
      currencyCode: json['currencyCode']?.toString() ?? '',
      hasVariants: json['hasVariants'] == true,
      enabled: json['enabled'] != false,
      disabledReason: json['disabledReason']?.toString(),
    );
  }

  static double? _readDouble(dynamic value) {
    if (value == null) {
      return null;
    }
    if (value is num) {
      return value.toDouble();
    }
    return double.tryParse(value.toString());
  }
}

class ReturnExchangeProductsResponse {
  const ReturnExchangeProductsResponse({
    required this.items,
    required this.page,
    required this.pageSize,
    required this.totalCount,
    required this.currencyCode,
  });

  final List<ReturnExchangeProduct> items;
  final int page;
  final int pageSize;
  final int totalCount;
  final String currencyCode;

  factory ReturnExchangeProductsResponse.fromJson(Map<String, dynamic> json) {
    final itemsJson = json['items'];
    return ReturnExchangeProductsResponse(
      items: itemsJson is List
          ? itemsJson
              .whereType<Map<String, dynamic>>()
              .map(ReturnExchangeProduct.fromJson)
              .toList(growable: false)
          : const [],
      page: _readInt(json['page']),
      pageSize: _readInt(json['pageSize']),
      totalCount: _readInt(json['totalCount']),
      currencyCode: json['currencyCode']?.toString() ?? '',
    );
  }

  static int _readInt(dynamic value) {
    if (value is int) {
      return value;
    }
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}

class ReturnExchangeReplacementItem {
  const ReturnExchangeReplacementItem({
    required this.returnedSaleLineId,
    required this.replacementProductId,
    required this.replacementVariantId,
    required this.productName,
    required this.sku,
    required this.quantity,
    required this.unitPrice,
    required this.lineTotal,
    required this.currencyCode,
    required this.stockStatus,
    this.variantDisplayName,
    this.imageStorageKey,
    this.availableQuantity,
    this.selectedAt,
  });

  final String returnedSaleLineId;
  final String replacementProductId;
  final String replacementVariantId;
  final String productName;
  final String sku;
  final String? variantDisplayName;
  final String? imageStorageKey;
  final double quantity;
  final double unitPrice;
  final double lineTotal;
  final String currencyCode;
  final String stockStatus;
  final double? availableQuantity;
  final DateTime? selectedAt;

  factory ReturnExchangeReplacementItem.fromJson(Map<String, dynamic> json) {
    return ReturnExchangeReplacementItem(
      returnedSaleLineId: json['returnedSaleLineId']?.toString() ?? '',
      replacementProductId: json['replacementProductId']?.toString() ?? '',
      replacementVariantId: json['replacementVariantId']?.toString() ?? '',
      productName: json['productName']?.toString() ?? '',
      sku: json['sku']?.toString() ?? '',
      variantDisplayName: json['variantDisplayName']?.toString(),
      imageStorageKey: json['imageStorageKey']?.toString(),
      quantity: _readDouble(json['quantity']) ?? 0,
      unitPrice: _readDouble(json['unitPrice']) ?? 0,
      lineTotal: _readDouble(json['lineTotal']) ?? 0,
      currencyCode: json['currencyCode']?.toString() ?? '',
      stockStatus: json['stockStatus']?.toString() ?? 'InStock',
      availableQuantity: _readDouble(json['availableQuantity']),
      selectedAt: DateTime.tryParse(json['selectedAt']?.toString() ?? ''),
    );
  }

  static double? _readDouble(dynamic value) {
    if (value == null) {
      return null;
    }
    if (value is num) {
      return value.toDouble();
    }
    return double.tryParse(value.toString());
  }
}

class ReturnExchangeReplacementResponse {
  const ReturnExchangeReplacementResponse({
    required this.saleId,
    required this.items,
    required this.selectedAt,
    required this.version,
    this.expiresAt,
  });

  final String saleId;
  final List<ReturnExchangeReplacementItem> items;
  final DateTime selectedAt;
  final int version;
  final DateTime? expiresAt;

  factory ReturnExchangeReplacementResponse.fromJson(Map<String, dynamic> json) {
    final itemsJson = json['items'];
    return ReturnExchangeReplacementResponse(
      saleId: json['saleId']?.toString() ?? '',
      items: itemsJson is List
          ? itemsJson
              .whereType<Map<String, dynamic>>()
              .map(ReturnExchangeReplacementItem.fromJson)
              .toList(growable: false)
          : const [],
      selectedAt: DateTime.tryParse(json['selectedAt']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      version: _readInt(json['version']),
      expiresAt: DateTime.tryParse(json['expiresAt']?.toString() ?? ''),
    );
  }

  static int _readInt(dynamic value) {
    if (value is int) {
      return value;
    }
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}

class ReturnExchangePreview {
  const ReturnExchangePreview({
    required this.saleId,
    required this.currencyCode,
    required this.returnedItemCount,
    required this.returnItemValue,
    required this.replacementItemValue,
    required this.taxAdjustment,
    required this.discountAdjustment,
    required this.differenceAmount,
    required this.differenceDirection,
    required this.canProceed,
    required this.requiresApproval,
    required this.policyMessages,
    required this.replacementItems,
    this.replacementSubtotal = 0,
    this.replacementDiscount = 0,
    this.replacementTax = 0,
    this.amountDueFromCustomer = 0,
    this.amountDueToCustomer = 0,
    this.draftVersion,
  });

  final String saleId;
  final String currencyCode;
  final int returnedItemCount;
  final double returnItemValue;
  final double replacementItemValue;
  final double taxAdjustment;
  final double discountAdjustment;
  final double differenceAmount;
  final String differenceDirection;
  final bool canProceed;
  final bool requiresApproval;
  final List<String> policyMessages;
  final List<ReturnExchangeReplacementItem> replacementItems;
  final double replacementSubtotal;
  final double replacementDiscount;
  final double replacementTax;
  final double amountDueFromCustomer;
  final double amountDueToCustomer;
  final int? draftVersion;

  factory ReturnExchangePreview.fromJson(Map<String, dynamic> json) {
    final messages = json['policyMessages'];
    return ReturnExchangePreview(
      saleId: json['saleId']?.toString() ?? '',
      currencyCode: json['currencyCode']?.toString() ?? '',
      returnedItemCount: _readInt(json['returnedItemCount']),
      returnItemValue: _readDouble(json['returnItemValue']) ?? 0,
      replacementItemValue: _readDouble(json['replacementItemValue']) ?? 0,
      taxAdjustment: _readDouble(json['taxAdjustment']) ?? 0,
      discountAdjustment: _readDouble(json['discountAdjustment']) ?? 0,
      differenceAmount: _readDouble(json['differenceAmount']) ?? 0,
      differenceDirection: json['differenceDirection']?.toString() ?? 'EVEN_EXCHANGE',
      canProceed: json['canProceed'] == true,
      requiresApproval: json['requiresApproval'] == true,
      policyMessages: messages is List
          ? messages.map((item) => item.toString()).toList(growable: false)
          : const [],
      replacementItems: json['replacementItems'] is List
          ? (json['replacementItems'] as List)
              .whereType<Map<String, dynamic>>()
              .map(ReturnExchangeReplacementItem.fromJson)
              .toList(growable: false)
          : const [],
      replacementSubtotal: _readDouble(json['replacementSubtotal']) ?? 0,
      replacementDiscount: _readDouble(json['replacementDiscount']) ??
          _readDouble(json['discountAdjustment']) ??
          0,
      replacementTax: _readDouble(json['replacementTax']) ??
          _readDouble(json['taxAdjustment']) ??
          0,
      amountDueFromCustomer: _readDouble(json['amountDueFromCustomer']) ?? 0,
      amountDueToCustomer: _readDouble(json['amountDueToCustomer']) ?? 0,
      draftVersion: _readIntNullable(json['draftVersion']),
    );
  }

  static int _readInt(dynamic value) {
    if (value is int) {
      return value;
    }
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static int? _readIntNullable(dynamic value) {
    if (value == null) {
      return null;
    }
    if (value is int) {
      return value;
    }
    return int.tryParse(value.toString());
  }

  static double? _readDouble(dynamic value) {
    if (value == null) {
      return null;
    }
    if (value is num) {
      return value.toDouble();
    }
    return double.tryParse(value.toString());
  }
}
