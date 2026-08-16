import 'step5_barcode_dtos.dart';
import 'step6_pricing_tax_dtos.dart';

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

  // Step 4 — Variant Configuration
  final VariantConfigurationResponseDto? variantConfiguration;

  // Step 5 — Barcode & SKU
  final BarcodeSkuConfigurationDto? barcodeSkuConfiguration;

  // Step 6 — Pricing & Tax
  final PricingTaxConfigurationResponseDto? pricingTaxConfiguration;

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
    this.variantConfiguration,
    this.barcodeSkuConfiguration,
    this.pricingTaxConfiguration,
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
      variantConfiguration: json['variantConfiguration'] != null
          ? VariantConfigurationResponseDto.fromJson(
              json['variantConfiguration'] as Map<String, dynamic>)
          : null,
      barcodeSkuConfiguration: json['barcodeSkuConfiguration'] != null
          ? BarcodeSkuConfigurationDto.fromJson(
              json['barcodeSkuConfiguration'] as Map<String, dynamic>)
          : null,
      pricingTaxConfiguration: json['pricingTaxConfiguration'] != null
          ? PricingTaxConfigurationResponseDto.fromJson(
              json['pricingTaxConfiguration'] as Map<String, dynamic>)
          : null,
    );
  }
}

class VariantConfigurationResponseDto {
  final List<VariantConfigurationOptionResponseDto> options;
  final List<VariantConfigurationVariantResponseDto> variants;
  final List<VariantConfigurationDeletedCombinationResponseDto>
      deletedCombinations;

  const VariantConfigurationResponseDto({
    this.options = const [],
    this.variants = const [],
    this.deletedCombinations = const [],
  });

  factory VariantConfigurationResponseDto.fromJson(Map<String, dynamic> json) {
    return VariantConfigurationResponseDto(
      options: (json['options'] as List<dynamic>?)
              ?.map((e) => VariantConfigurationOptionResponseDto.fromJson(
                  e as Map<String, dynamic>))
              .toList() ??
          const [],
      variants: (json['variants'] as List<dynamic>?)
              ?.map((e) => VariantConfigurationVariantResponseDto.fromJson(
                  e as Map<String, dynamic>))
              .toList() ??
          const [],
      deletedCombinations: (json['excludedCombinationHashes'] as List<dynamic>?)
              ?.map((e) =>
                  VariantConfigurationDeletedCombinationResponseDto.fromJson(
                      e as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }
}

class VariantConfigurationOptionResponseDto {
  final String sourceOptionTemplateId;
  final String? productOptionId;
  final String? optionName;
  final int sortOrder;
  final List<VariantConfigurationOptionValueResponseDto> values;

  const VariantConfigurationOptionResponseDto({
    required this.sourceOptionTemplateId,
    this.productOptionId,
    this.optionName,
    this.sortOrder = 0,
    this.values = const [],
  });

  factory VariantConfigurationOptionResponseDto.fromJson(
      Map<String, dynamic> json) {
    return VariantConfigurationOptionResponseDto(
      sourceOptionTemplateId: json['sourceOptionTemplateId']?.toString() ?? '',
      productOptionId: json['productOptionId']?.toString(),
      optionName: json['optionName']?.toString(),
      sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
      values: (json['values'] as List<dynamic>?)
              ?.map((e) => VariantConfigurationOptionValueResponseDto.fromJson(
                  e as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }
}

class VariantConfigurationOptionValueResponseDto {
  final String sourceOptionTemplateValueId;
  final String? productOptionValueId;
  final String? valueName;
  final int sortOrder;
  final String? imageMediaAssetId;

  const VariantConfigurationOptionValueResponseDto({
    required this.sourceOptionTemplateValueId,
    this.productOptionValueId,
    this.valueName,
    this.sortOrder = 0,
    this.imageMediaAssetId,
  });

  factory VariantConfigurationOptionValueResponseDto.fromJson(
      Map<String, dynamic> json) {
    return VariantConfigurationOptionValueResponseDto(
      sourceOptionTemplateValueId:
          json['sourceOptionTemplateValueId']?.toString() ?? '',
      productOptionValueId: json['productOptionValueId']?.toString(),
      valueName: json['valueName']?.toString(),
      sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
      imageMediaAssetId: json['imageMediaAssetId']?.toString(),
    );
  }
}

class VariantConfigurationVariantResponseDto {
  final String clientCombinationKey;
  final String? productVariantId;
  final List<VariantConfigurationSelectedValueResponseDto> selectedValues;
  final String combinationLabel;
  final String? displayLabel;
  final bool includeVariant;
  final String? exactImageMediaAssetId;
  final String? optionCombinationHash;

  const VariantConfigurationVariantResponseDto({
    required this.clientCombinationKey,
    this.productVariantId,
    this.selectedValues = const [],
    required this.combinationLabel,
    this.displayLabel,
    this.includeVariant = true,
    this.exactImageMediaAssetId,
    this.optionCombinationHash,
  });

  factory VariantConfigurationVariantResponseDto.fromJson(
      Map<String, dynamic> json) {
    return VariantConfigurationVariantResponseDto(
      clientCombinationKey: json['clientCombinationKey']?.toString() ?? '',
      productVariantId: json['productVariantId']?.toString(),
      selectedValues: (json['selectedValues'] as List<dynamic>?)
              ?.map((e) =>
                  VariantConfigurationSelectedValueResponseDto.fromJson(
                      e as Map<String, dynamic>))
              .toList() ??
          const [],
      combinationLabel: json['combinationLabel']?.toString() ?? '',
      displayLabel: json['displayLabel']?.toString(),
      includeVariant: json['includeVariant'] as bool? ?? true,
      exactImageMediaAssetId: json['exactImageMediaAssetId']?.toString(),
      optionCombinationHash: json['optionCombinationHash']?.toString(),
    );
  }
}

class VariantConfigurationSelectedValueResponseDto {
  final String sourceOptionTemplateId;
  final String sourceOptionTemplateValueId;
  final String? optionName;
  final String? valueName;

  const VariantConfigurationSelectedValueResponseDto({
    required this.sourceOptionTemplateId,
    required this.sourceOptionTemplateValueId,
    this.optionName,
    this.valueName,
  });

  factory VariantConfigurationSelectedValueResponseDto.fromJson(
      Map<String, dynamic> json) {
    return VariantConfigurationSelectedValueResponseDto(
      sourceOptionTemplateId: json['sourceOptionTemplateId']?.toString() ?? '',
      sourceOptionTemplateValueId:
          json['sourceOptionTemplateValueId']?.toString() ?? '',
      optionName: json['optionName']?.toString(),
      valueName: json['valueName']?.toString(),
    );
  }
}

class VariantConfigurationDeletedCombinationResponseDto {
  final String clientCombinationKey;
  final String? productVariantId;
  final String? optionCombinationHash;
  final List<VariantConfigurationSelectedValueResponseDto> selectedValues;

  const VariantConfigurationDeletedCombinationResponseDto({
    required this.clientCombinationKey,
    this.productVariantId,
    this.optionCombinationHash,
    this.selectedValues = const [],
  });

  factory VariantConfigurationDeletedCombinationResponseDto.fromJson(
      Map<String, dynamic> json) {
    return VariantConfigurationDeletedCombinationResponseDto(
      clientCombinationKey: json['clientCombinationKey']?.toString() ?? '',
      productVariantId: json['productVariantId']?.toString(),
      optionCombinationHash: json['optionCombinationHash']?.toString(),
      selectedValues: (json['selectedValues'] as List<dynamic>?)
              ?.map((e) =>
                  VariantConfigurationSelectedValueResponseDto.fromJson(
                      e as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }
}
