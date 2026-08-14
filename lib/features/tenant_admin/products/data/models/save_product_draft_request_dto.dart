import 'step5_barcode_dtos.dart';

class SaveProductDraftRequestDto {
  final String? productName;
  final String? shortName;
  final String? productCode;
  final String? categoryId;
  final String? brandId;
  final String? shortDescription;
  final String? longDescription;
  final bool desiredPublishActive;
  final bool posSellable;
  final bool trackInventory;
  final bool allowOnlineSale;
  final int currentSetupStep;
  final bool advanceStep;
  final int? expectedRowVersion;
  final List<String>? stagedMediaAssetIds;
  final String? productStructure;
  final bool? batchTracking;
  final bool? expiryTracking;
  final bool? serialTracking;

  final String? wizardAction;

  // Step 3 — Units & Pack Conversion
  final String? unitModel;
  final String? productUnitId;
  final String? baseUnitId;
  final String? sellingUnitId;
  final String? purchaseUnitId;
  final String? outerPackUnitId;
  final num? itemsPerPurchaseUnit;
  final num? purchaseUnitsPerOuterPack;
  final bool allowDecimalQuantity;

  // Step 4 — Variant Configuration
  final VariantConfigurationDto? variantConfiguration;

  // Step 5 — Barcode & SKU
  final String? baseSku;
  final String? parentProductBarcode;
  final List<Step5VariantIdentifierDto>? variantIdentifiers;
  final List<Step5AdditionalBarcodeDto>? additionalBarcodes;

  const SaveProductDraftRequestDto({
    this.productName,
    this.shortName,
    this.productCode,
    this.categoryId,
    this.brandId,
    this.shortDescription,
    this.longDescription,
    this.desiredPublishActive = true,
    this.posSellable = true,
    this.trackInventory = true,
    this.allowOnlineSale = true,
    this.productStructure,
    this.batchTracking,
    this.expiryTracking,
    this.serialTracking,
    this.currentSetupStep = 1,
    this.advanceStep = false,
    this.wizardAction,
    this.expectedRowVersion,
    this.stagedMediaAssetIds,
    this.unitModel,
    this.productUnitId,
    this.baseUnitId,
    this.sellingUnitId,
    this.purchaseUnitId,
    this.outerPackUnitId,
    this.itemsPerPurchaseUnit,
    this.purchaseUnitsPerOuterPack,
    this.allowDecimalQuantity = false,
    this.variantConfiguration,
    this.baseSku,
    this.parentProductBarcode,
    this.variantIdentifiers,
    this.additionalBarcodes,
  });

  Map<String, dynamic> toJson() {
    return {
      'productName': productName,
      'shortName': shortName,
      'productCode': productCode,
      'categoryId': categoryId,
      'brandId': brandId,
      'shortDescription': shortDescription,
      'longDescription': longDescription,
      'desiredPublishActive': desiredPublishActive,
      'posSellable': posSellable,
      'trackInventory': trackInventory,
      'allowOnlineSale': allowOnlineSale,
      if (productStructure != null) 'productStructure': productStructure,
      if (batchTracking != null) 'batchTracking': batchTracking,
      if (expiryTracking != null) 'expiryTracking': expiryTracking,
      if (serialTracking != null) 'serialTracking': serialTracking,
      'currentSetupStep': currentSetupStep,
      'advanceStep': advanceStep,
      if (wizardAction != null) 'wizardAction': wizardAction,
      'expectedRowVersion': expectedRowVersion,
      'stagedMediaAssetIds': stagedMediaAssetIds,
      if (unitModel != null) 'unitModel': unitModel,
      if (productUnitId != null) 'productUnitId': productUnitId,
      if (baseUnitId != null) 'baseUnitId': baseUnitId,
      if (sellingUnitId != null) 'sellingUnitId': sellingUnitId,
      if (purchaseUnitId != null) 'purchaseUnitId': purchaseUnitId,
      if (outerPackUnitId != null) 'outerPackUnitId': outerPackUnitId,
      if (itemsPerPurchaseUnit != null)
        'itemsPerPurchaseUnit': itemsPerPurchaseUnit,
      if (purchaseUnitsPerOuterPack != null)
        'purchaseUnitsPerOuterPack': purchaseUnitsPerOuterPack,
      'allowDecimalQuantity': allowDecimalQuantity,
      if (variantConfiguration != null)
        'variantConfiguration': variantConfiguration!.toJson(),
      if (baseSku != null) 'baseSku': baseSku,
      if (parentProductBarcode != null)
        'parentProductBarcode': parentProductBarcode,
      if (variantIdentifiers != null)
        'variantIdentifiers':
            variantIdentifiers!.map((e) => e.toJson()).toList(),
      if (additionalBarcodes != null)
        'additionalBarcodes':
            additionalBarcodes!.map((e) => e.toJson()).toList(),
    };
  }
}

class VariantConfigurationDto {
  final List<VariantConfigurationOptionDto>? options;
  final List<VariantConfigurationVariantDto>? variants;
  final List<VariantConfigurationDeletedCombinationDto>? deletedCombinations;

  const VariantConfigurationDto({
    this.options,
    this.variants,
    this.deletedCombinations,
  });

  Map<String, dynamic> toJson() {
    return {
      if (options != null) 'options': options!.map((e) => e.toJson()).toList(),
      if (variants != null)
        'variants': variants!.map((e) => e.toJson()).toList(),
      if (deletedCombinations != null)
        'deletedCombinations':
            deletedCombinations!.map((e) => e.toJson()).toList(),
    };
  }
}

class VariantConfigurationOptionDto {
  final String? sourceOptionTemplateId;
  final String? productOptionId;
  final int? sortOrder;
  final List<VariantConfigurationOptionValueDto>? values;

  const VariantConfigurationOptionDto({
    this.sourceOptionTemplateId,
    this.productOptionId,
    this.sortOrder,
    this.values,
  });

  Map<String, dynamic> toJson() {
    return {
      if (sourceOptionTemplateId != null)
        'sourceOptionTemplateId': sourceOptionTemplateId,
      if (productOptionId != null) 'productOptionId': productOptionId,
      if (sortOrder != null) 'sortOrder': sortOrder,
      if (values != null) 'values': values!.map((e) => e.toJson()).toList(),
    };
  }
}

class VariantConfigurationOptionValueDto {
  final String? sourceOptionTemplateValueId;
  final String? productOptionValueId;
  final int? sortOrder;
  final String? imageMediaAssetId;

  const VariantConfigurationOptionValueDto({
    this.sourceOptionTemplateValueId,
    this.productOptionValueId,
    this.sortOrder,
    this.imageMediaAssetId,
  });

  Map<String, dynamic> toJson() {
    return {
      if (sourceOptionTemplateValueId != null)
        'sourceOptionTemplateValueId': sourceOptionTemplateValueId,
      if (productOptionValueId != null)
        'productOptionValueId': productOptionValueId,
      if (sortOrder != null) 'sortOrder': sortOrder,
      if (imageMediaAssetId != null) 'imageMediaAssetId': imageMediaAssetId,
    };
  }
}

class VariantConfigurationVariantDto {
  final String clientCombinationKey;
  final String? productVariantId;
  final List<VariantConfigurationSelectedValueDto>? selectedValues;
  final String? displayLabel;
  final bool includeVariant;
  final String? exactImageMediaAssetId;

  const VariantConfigurationVariantDto({
    required this.clientCombinationKey,
    this.productVariantId,
    this.selectedValues,
    this.displayLabel,
    this.includeVariant = true,
    this.exactImageMediaAssetId,
  });

  Map<String, dynamic> toJson() {
    return {
      'clientCombinationKey': clientCombinationKey,
      if (productVariantId != null) 'productVariantId': productVariantId,
      if (selectedValues != null)
        'selectedValues': selectedValues!.map((e) => e.toJson()).toList(),
      if (displayLabel != null) 'displayLabel': displayLabel,
      'includeVariant': includeVariant,
      if (exactImageMediaAssetId != null)
        'exactImageMediaAssetId': exactImageMediaAssetId,
    };
  }
}

class VariantConfigurationSelectedValueDto {
  final String? sourceOptionTemplateId;
  final String? sourceOptionTemplateValueId;

  const VariantConfigurationSelectedValueDto({
    this.sourceOptionTemplateId,
    this.sourceOptionTemplateValueId,
  });

  Map<String, dynamic> toJson() {
    return {
      if (sourceOptionTemplateId != null)
        'sourceOptionTemplateId': sourceOptionTemplateId,
      if (sourceOptionTemplateValueId != null)
        'sourceOptionTemplateValueId': sourceOptionTemplateValueId,
    };
  }
}

class VariantConfigurationDeletedCombinationDto {
  final String clientCombinationKey;
  final String? productVariantId;
  final String? optionCombinationHash;
  final List<VariantConfigurationSelectedValueDto>? selectedValues;

  const VariantConfigurationDeletedCombinationDto({
    required this.clientCombinationKey,
    this.productVariantId,
    this.optionCombinationHash,
    this.selectedValues,
  });

  Map<String, dynamic> toJson() {
    return {
      'clientCombinationKey': clientCombinationKey,
      if (productVariantId != null) 'productVariantId': productVariantId,
      if (optionCombinationHash != null)
        'optionCombinationHash': optionCombinationHash,
      if (selectedValues != null)
        'selectedValues': selectedValues!.map((e) => e.toJson()).toList(),
    };
  }
}
