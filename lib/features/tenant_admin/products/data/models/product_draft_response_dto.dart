class ProductImageResponseDto {
  final String productImageId;
  final String? mediaAssetId;
  final String? productVariantId;
  final String imageUrl;
  final String? altText;
  final String imagePurpose;
  final int sortOrder;
  final bool isPrimaryImage;

  const ProductImageResponseDto({
    required this.productImageId,
    this.mediaAssetId,
    this.productVariantId,
    required this.imageUrl,
    this.altText,
    required this.imagePurpose,
    required this.sortOrder,
    required this.isPrimaryImage,
  });

  factory ProductImageResponseDto.fromJson(Map<String, dynamic> json) {
    return ProductImageResponseDto(
      productImageId: json['productImageId']?.toString() ?? '',
      mediaAssetId: json['mediaAssetId']?.toString(),
      productVariantId: json['productVariantId']?.toString(),
      imageUrl:
          json['imageUrl']?.toString() ?? json['publicUrl']?.toString() ?? '',
      altText: json['altText']?.toString(),
      imagePurpose: json['imagePurpose']?.toString() ?? 'GALLERY',
      sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
      isPrimaryImage: json['isPrimaryImage'] as bool? ?? false,
    );
  }
}

class ProductUnitConversionResponseDto {
  final String uomId;
  final String uomCode;
  final String uomName;
  final String unitLevel;
  final num conversionToBaseFactor;
  final bool isBaseUnit;
  final bool isSellingUnit;
  final bool isPurchaseUnit;
  final bool isOuterPackUnit;

  const ProductUnitConversionResponseDto({
    required this.uomId,
    required this.uomCode,
    required this.uomName,
    required this.unitLevel,
    required this.conversionToBaseFactor,
    required this.isBaseUnit,
    required this.isSellingUnit,
    required this.isPurchaseUnit,
    required this.isOuterPackUnit,
  });

  factory ProductUnitConversionResponseDto.fromJson(
    Map<String, dynamic> json,
  ) {
    return ProductUnitConversionResponseDto(
      uomId: json['uomId']?.toString() ?? '',
      uomCode: json['uomCode']?.toString() ?? '',
      uomName: json['uomName']?.toString() ?? '',
      unitLevel: json['unitLevel']?.toString() ?? 'BASE',
      conversionToBaseFactor: (json['conversionToBaseFactor'] as num?) ?? 1.0,
      isBaseUnit: json['isBaseUnit'] as bool? ?? false,
      isSellingUnit: json['isSellingUnit'] as bool? ?? false,
      isPurchaseUnit: json['isPurchaseUnit'] as bool? ?? false,
      isOuterPackUnit: json['isOuterPackUnit'] as bool? ?? false,
    );
  }
}

class ProductDraftResponseDto {
  final String productId;
  final String productName;
  final String? productCode;
  final String status;
  final String? desiredPublishStatus;
  final int currentSetupStep;
  final int? targetSetupStep;
  final int? lastCompletedSetupStep;
  final DateTime? draftSavedAt;
  final int rowVersion;
  final String? categoryId;
  final String? brandId;
  final String? shortDescription;
  final String? longDescription;
  final bool posSellable;
  final bool trackInventory;
  final bool allowOnlineSale;
  final String productStructure;
  final bool batchTracking;
  final bool expiryTracking;
  final bool serialTracking;
  final String? inventoryMethod;
  final int componentCount;
  final bool componentsConfigured;
  final List<ProductImageResponseDto> images;

  // Step 3 Projected Properties
  final String? unitModel;
  final String? baseUnitId;
  final String? baseUnitName;
  final String? sellingUnitId;
  final String? sellingUnitName;
  final String? purchaseUnitId;
  final String? purchaseUnitName;
  final String? outerPackUnitId;
  final String? outerPackUnitName;
  final num? itemsPerPurchaseUnit;
  final num? purchaseUnitsPerOuterPack;
  final bool allowDecimalQuantity;
  final List<ProductUnitConversionResponseDto> unitConversions;

  const ProductDraftResponseDto({
    required this.productId,
    required this.productName,
    this.productCode,
    required this.status,
    this.desiredPublishStatus,
    required this.currentSetupStep,
    this.targetSetupStep,
    this.lastCompletedSetupStep,
    this.draftSavedAt,
    required this.rowVersion,
    this.categoryId,
    this.brandId,
    this.shortDescription,
    this.longDescription,
    required this.posSellable,
    required this.trackInventory,
    required this.allowOnlineSale,
    this.productStructure = 'SIMPLE',
    this.batchTracking = false,
    this.expiryTracking = false,
    this.serialTracking = false,
    required this.images,
    this.inventoryMethod,
    this.componentCount = 0,
    this.componentsConfigured = false,
    this.unitModel,
    this.baseUnitId,
    this.baseUnitName,
    this.sellingUnitId,
    this.sellingUnitName,
    this.purchaseUnitId,
    this.purchaseUnitName,
    this.outerPackUnitId,
    this.outerPackUnitName,
    this.itemsPerPurchaseUnit,
    this.purchaseUnitsPerOuterPack,
    this.allowDecimalQuantity = false,
    this.unitConversions = const [],
  });

  factory ProductDraftResponseDto.fromJson(Map<String, dynamic> json) {
    return ProductDraftResponseDto(
      productId: json['productId']?.toString() ?? '',
      productName: json['productName']?.toString() ?? '',
      productCode: json['productCode']?.toString(),
      status: json['status']?.toString() ?? 'DRAFT',
      desiredPublishStatus: json['desiredPublishStatus']?.toString(),
      currentSetupStep: (json['currentSetupStep'] as num?)?.toInt() ?? 1,
      targetSetupStep: (json['targetSetupStep'] as num?)?.toInt(),
      lastCompletedSetupStep: (json['lastCompletedSetupStep'] as num?)?.toInt(),
      draftSavedAt: json['draftSavedAt'] != null
          ? DateTime.tryParse(json['draftSavedAt'].toString())
          : null,
      rowVersion: (json['rowVersion'] as num?)?.toInt() ?? 0,
      categoryId: json['categoryId']?.toString(),
      brandId: json['brandId']?.toString(),
      shortDescription: json['shortDescription']?.toString(),
      longDescription: json['longDescription']?.toString(),
      posSellable: json['posSellable'] as bool? ?? true,
      trackInventory: json['trackInventory'] as bool? ?? true,
      allowOnlineSale: json['allowOnlineSale'] as bool? ?? true,
      productStructure: json['productStructure']?.toString() ?? 'SIMPLE',
      batchTracking: json['batchTracking'] as bool? ?? false,
      expiryTracking: json['expiryTracking'] as bool? ?? false,
      serialTracking: json['serialTracking'] as bool? ?? false,
      images: (json['images'] as List<dynamic>?)
              ?.map((e) =>
                  ProductImageResponseDto.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      inventoryMethod: json['inventoryMethod']?.toString(),
      componentCount: (json['componentCount'] as num?)?.toInt() ?? 0,
      componentsConfigured: json['componentsConfigured'] as bool? ?? false,
      unitModel: json['unitModel']?.toString(),
      baseUnitId: json['baseUnitId']?.toString(),
      baseUnitName: json['baseUnitName']?.toString(),
      sellingUnitId: json['sellingUnitId']?.toString(),
      sellingUnitName: json['sellingUnitName']?.toString(),
      purchaseUnitId: json['purchaseUnitId']?.toString(),
      purchaseUnitName: json['purchaseUnitName']?.toString(),
      outerPackUnitId: json['outerPackUnitId']?.toString(),
      outerPackUnitName: json['outerPackUnitName']?.toString(),
      itemsPerPurchaseUnit: json['itemsPerPurchaseUnit'] as num?,
      purchaseUnitsPerOuterPack: json['purchaseUnitsPerOuterPack'] as num?,
      allowDecimalQuantity: json['allowDecimalQuantity'] as bool? ?? false,
      unitConversions: (json['unitConversions'] as List<dynamic>?)
              ?.map((e) => ProductUnitConversionResponseDto.fromJson(
                  Map<String, dynamic>.from(e as Map)))
              .toList() ??
          const [],
    );
  }
}
