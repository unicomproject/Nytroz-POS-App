class Step5VariantIdentifierDto {
  final String productVariantId;
  final String? sku;
  final String? barcode;

  const Step5VariantIdentifierDto({
    required this.productVariantId,
    this.sku,
    this.barcode,
  });

  factory Step5VariantIdentifierDto.fromJson(Map<String, dynamic> json) {
    return Step5VariantIdentifierDto(
      productVariantId: json['productVariantId']?.toString() ?? '',
      sku: json['sku']?.toString(),
      barcode: json['barcode']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'productVariantId': productVariantId,
      if (sku != null) 'sku': sku,
      if (barcode != null) 'barcode': barcode,
    };
  }
}

class Step5AdditionalBarcodeDto {
  final String? barcodeId;
  final String barcode;
  final String barcodeType;
  final String? productVariantId;
  final String? uomId;
  final num quantityPerScan;
  final bool isPrimary;
  final String status;

  const Step5AdditionalBarcodeDto({
    this.barcodeId,
    required this.barcode,
    required this.barcodeType,
    this.productVariantId,
    this.uomId,
    required this.quantityPerScan,
    required this.isPrimary,
    required this.status,
  });

  Step5AdditionalBarcodeDto copyWith({
    String? barcodeId,
    String? barcode,
    String? barcodeType,
    String? productVariantId,
    String? uomId,
    num? quantityPerScan,
    bool? isPrimary,
    String? status,
  }) {
    return Step5AdditionalBarcodeDto(
      barcodeId: barcodeId ?? this.barcodeId,
      barcode: barcode ?? this.barcode,
      barcodeType: barcodeType ?? this.barcodeType,
      productVariantId: productVariantId ?? this.productVariantId,
      uomId: uomId ?? this.uomId,
      quantityPerScan: quantityPerScan ?? this.quantityPerScan,
      isPrimary: isPrimary ?? this.isPrimary,
      status: status ?? this.status,
    );
  }

  factory Step5AdditionalBarcodeDto.fromJson(Map<String, dynamic> json) {
    return Step5AdditionalBarcodeDto(
      barcodeId: json['barcodeId']?.toString(),
      barcode: json['barcode']?.toString() ?? '',
      barcodeType: json['barcodeType']?.toString() ?? '',
      productVariantId: json['productVariantId']?.toString(),
      uomId: json['uomId']?.toString(),
      quantityPerScan: json['quantityPerScan'] as num? ?? 1,
      isPrimary: json['isPrimary'] as bool? ?? false,
      status: json['status']?.toString() ?? 'ACTIVE',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (barcodeId != null) 'barcodeId': barcodeId,
      'barcode': barcode,
      'barcodeType': barcodeType,
      if (productVariantId != null) 'productVariantId': productVariantId,
      if (uomId != null) 'uomId': uomId,
      'quantityPerScan': quantityPerScan,
      'isPrimary': isPrimary,
      'status': status,
    };
  }
}
