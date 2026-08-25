class DuplicateBarcodeConflictDto {
  final String? barcode;
  final String? barcodeType;
  final String? productName;
  final String? productType;
  final String? variantName;
  final String? sku;
  final String? assignedLevel;
  final String? productStatus;
  final String? stockStatus;
  final String? createdBy;
  final DateTime? createdDate;
  final String? conflictingProductId;
  final String? conflictingVariantId;

  const DuplicateBarcodeConflictDto({
    this.barcode,
    this.barcodeType,
    this.productName,
    this.productType,
    this.variantName,
    this.sku,
    this.assignedLevel,
    this.productStatus,
    this.stockStatus,
    this.createdBy,
    this.createdDate,
    this.conflictingProductId,
    this.conflictingVariantId,
  });

  factory DuplicateBarcodeConflictDto.fromJson(Map<String, dynamic> json) {
    return DuplicateBarcodeConflictDto(
      barcode: json['barcode']?.toString(),
      barcodeType: json['barcodeType']?.toString(),
      productName: json['productName']?.toString(),
      productType: json['productType']?.toString(),
      variantName: json['variantName']?.toString(),
      sku: json['sku']?.toString(),
      assignedLevel: json['assignedLevel']?.toString(),
      productStatus: json['productStatus']?.toString(),
      stockStatus: json['stockStatus']?.toString(),
      createdBy: json['createdBy']?.toString(),
      createdDate: json['createdDate'] != null
          ? DateTime.tryParse(json['createdDate'].toString())
          : null,
      conflictingProductId: json['conflictingProductId']?.toString(),
      conflictingVariantId: json['conflictingVariantId']?.toString(),
    );
  }
}
