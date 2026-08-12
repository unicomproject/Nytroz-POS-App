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
    };
  }
}
