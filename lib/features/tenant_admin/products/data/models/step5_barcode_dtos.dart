/// Represents a single additional barcode assigned to a product or variant.
/// Used in Step 5 of the Add Product wizard.
class Step5AdditionalBarcodeDto {
  final String? barcodeId;
  final String barcode;
  final String barcodeType;
  final String? productVariantId;
  final bool isPrimary;

  const Step5AdditionalBarcodeDto({
    this.barcodeId,
    required this.barcode,
    required this.barcodeType,
    this.productVariantId,
    this.isPrimary = false,
  });

  factory Step5AdditionalBarcodeDto.fromJson(Map<String, dynamic> json) {
    return Step5AdditionalBarcodeDto(
      barcodeId: json['barcodeId']?.toString(),
      barcode: json['barcode']?.toString() ?? '',
      barcodeType: json['barcodeType']?.toString() ?? 'CODE128',
      productVariantId: json['productVariantId']?.toString(),
      isPrimary: json['isPrimary'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (barcodeId != null) 'barcodeId': barcodeId,
      'barcode': barcode,
      'barcodeType': barcodeType,
      if (productVariantId != null) 'productVariantId': productVariantId,
      'isPrimary': isPrimary,
    };
  }

  Step5AdditionalBarcodeDto copyWith({
    String? barcodeId,
    String? barcode,
    String? barcodeType,
    String? productVariantId,
    bool clearVariantId = false,
    bool? isPrimary,
  }) {
    return Step5AdditionalBarcodeDto(
      barcodeId: barcodeId ?? this.barcodeId,
      barcode: barcode ?? this.barcode,
      barcodeType: barcodeType ?? this.barcodeType,
      productVariantId:
          clearVariantId ? null : (productVariantId ?? this.productVariantId),
      isPrimary: isPrimary ?? this.isPrimary,
    );
  }
}

/// Represents the SKU/barcode identifiers for a specific variant.
/// Used in Step 5 of the Add Product wizard.
class Step5VariantIdentifierDto {
  final String? productVariantId;
  final String? sku;
  final String? barcode;

  const Step5VariantIdentifierDto({
    this.productVariantId,
    this.sku,
    this.barcode,
  });

  factory Step5VariantIdentifierDto.fromJson(Map<String, dynamic> json) {
    return Step5VariantIdentifierDto(
      productVariantId: json['productVariantId']?.toString(),
      sku: json['sku']?.toString(),
      barcode: json['barcode']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (productVariantId != null) 'productVariantId': productVariantId,
      if (sku != null) 'sku': sku,
      if (barcode != null) 'barcode': barcode,
    };
  }

  Step5VariantIdentifierDto copyWith({
    String? productVariantId,
    String? sku,
    String? barcode,
  }) {
    return Step5VariantIdentifierDto(
      productVariantId: productVariantId ?? this.productVariantId,
      sku: sku ?? this.sku,
      barcode: barcode ?? this.barcode,
    );
  }
}

class BarcodeSkuConfigurationDto {
  final List<Step5IdentifierTargetDto>? identifierTargets;
  final List<BarcodeSkuAssignmentDto>? assignments;

  const BarcodeSkuConfigurationDto({
    this.identifierTargets,
    this.assignments,
  });

  factory BarcodeSkuConfigurationDto.fromJson(Map<String, dynamic> json) {
    return BarcodeSkuConfigurationDto(
      identifierTargets: (json['identifierTargets'] as List<dynamic>?)
          ?.map((e) => Step5IdentifierTargetDto.fromJson(e as Map<String, dynamic>))
          .toList(),
      assignments: (json['assignments'] as List<dynamic>?)
          ?.map((e) => BarcodeSkuAssignmentDto.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (identifierTargets != null)
        'identifierTargets': identifierTargets!.map((e) => e.toJson()).toList(),
      if (assignments != null)
        'assignments': assignments!.map((e) => e.toJson()).toList(),
    };
  }
}

class Step5IdentifierTargetDto {
  final String? productVariantId;
  final String clientCombinationKey;
  final String? label;

  const Step5IdentifierTargetDto({
    this.productVariantId,
    required this.clientCombinationKey,
    this.label,
  });

  factory Step5IdentifierTargetDto.fromJson(Map<String, dynamic> json) {
    return Step5IdentifierTargetDto(
      productVariantId: json['productVariantId']?.toString(),
      clientCombinationKey: json['clientCombinationKey']?.toString() ?? '',
      label: json['label']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (productVariantId != null) 'productVariantId': productVariantId,
      'clientCombinationKey': clientCombinationKey,
      if (label != null) 'label': label,
    };
  }
}

class BarcodeSkuAssignmentDto {
  final String clientCombinationKey;
  final String? productVariantId;
  final String? sku;
  final String? barcode;
  final bool isAssigned;
  // 'COMPLETE', 'DUPLICATE', 'INCOMPLETE' — used for table status chip display only
  final String? status;

  const BarcodeSkuAssignmentDto({
    required this.clientCombinationKey,
    this.productVariantId,
    this.sku,
    this.barcode,
    this.isAssigned = false,
    this.status,
  });

  factory BarcodeSkuAssignmentDto.fromJson(Map<String, dynamic> json) {
    return BarcodeSkuAssignmentDto(
      clientCombinationKey: json['clientCombinationKey']?.toString() ?? '',
      productVariantId: json['productVariantId']?.toString(),
      sku: json['sku']?.toString(),
      barcode: json['barcode']?.toString(),
      isAssigned: json['isAssigned'] as bool? ?? false,
      status: json['status']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'clientCombinationKey': clientCombinationKey,
      if (productVariantId != null) 'productVariantId': productVariantId,
      if (sku != null) 'sku': sku,
      if (barcode != null) 'barcode': barcode,
      'isAssigned': isAssigned,
      // status is UI-only, not sent to backend
    };
  }

  BarcodeSkuAssignmentDto copyWith({
    String? clientCombinationKey,
    String? productVariantId,
    bool clearProductVariantId = false,
    String? sku,
    bool clearSku = false,
    String? barcode,
    bool clearBarcode = false,
    bool? isAssigned,
    String? status,
    bool clearStatus = false,
  }) {
    return BarcodeSkuAssignmentDto(
      clientCombinationKey:
          clientCombinationKey ?? this.clientCombinationKey,
      productVariantId: clearProductVariantId
          ? null
          : (productVariantId ?? this.productVariantId),
      sku: clearSku ? null : (sku ?? this.sku),
      barcode: clearBarcode ? null : (barcode ?? this.barcode),
      isAssigned: isAssigned ?? this.isAssigned,
      status: clearStatus ? null : (status ?? this.status),
    );
  }

  /// Derives the effective status for UI display.
  /// - DUPLICATE: externally set from API conflict response
  /// - COMPLETE: SKU is filled (barcode is optional for wizard continue)
  /// - INCOMPLETE: missing SKU
  String get effectiveStatus {
    if (status == 'DUPLICATE') return 'DUPLICATE';
    final hasSku = sku != null && sku!.trim().isNotEmpty;
    if (hasSku) return 'COMPLETE';
    return 'INCOMPLETE';
  }
}
