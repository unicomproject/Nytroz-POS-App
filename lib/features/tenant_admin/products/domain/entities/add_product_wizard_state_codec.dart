import '../../data/models/step5_barcode_dtos.dart';
import 'add_product_wizard_state.dart';
import 'staged_product_image.dart';
import 'step4_variant_configuration_state.dart';
import 'step5_barcode_sku_state.dart';

/// JSON codec for persisting [AddProductWizardState] in a local draft snapshot.
///
/// Intentionally omits:
/// - [AddProductWizardState.createOptions] (reloaded on resume)
/// - image [Uint8List] bytes (too large; mediaAssetId/url preserved when present)
/// - transient UI flags (isSubmitting, fieldErrors, pageError, etc.)
class AddProductWizardStateCodec {
  const AddProductWizardStateCodec._();

  static Map<String, dynamic> toJson(AddProductWizardState state) {
    return {
      'currentStep': state.currentStep,
      'targetSetupStep': state.targetSetupStep,
      'lastCompletedSetupStep': state.lastCompletedSetupStep,
      'productId': state.productId,
      'localDraftId': state.localDraftId,
      'status': state.status,
      'rowVersion': state.rowVersion,
      'productName': state.productName,
      'internalCode': state.internalCode,
      'categoryId': state.categoryId,
      'brandId': state.brandId,
      'shortDescription': state.shortDescription,
      'longDescription': state.longDescription,
      'productStructure': state.productStructure,
      'productStructureConfirmed': state.productStructureConfirmed,
      'batchTracking': state.batchTracking,
      'expiryTracking': state.expiryTracking,
      'serialTracking': state.serialTracking,
      'desiredPublishActive': state.desiredPublishActive,
      'posSellable': state.posSellable,
      'trackInventory': state.trackInventory,
      'allowOnlineSale': state.allowOnlineSale,
      'unitModel': state.unitModel,
      'productUnitId': state.productUnitId,
      'baseUnitId': state.baseUnitId,
      'baseUnitName': state.baseUnitName,
      'sellingUnitId': state.sellingUnitId,
      'sellingUnitName': state.sellingUnitName,
      'purchaseUnitId': state.purchaseUnitId,
      'purchaseUnitName': state.purchaseUnitName,
      'outerPackUnitId': state.outerPackUnitId,
      'outerPackUnitName': state.outerPackUnitName,
      'itemsPerPurchaseUnit': state.itemsPerPurchaseUnit,
      'purchaseUnitsPerOuterPack': state.purchaseUnitsPerOuterPack,
      'allowDecimalQuantity': state.allowDecimalQuantity,
      'unitConversions':
          state.unitConversions.map(_unitConversionToJson).toList(),
      'stagedMediaAssets':
          state.stagedMediaAssets.map(_stagedImageToJson).toList(),
      'productImages': state.productImages.map(_wizardImageToJson).toList(),
      'primaryImageId': state.primaryImageId,
      'inventoryMethod': state.inventoryMethod,
      'componentCount': state.componentCount,
      'componentsConfigured': state.componentsConfigured,
      'step4State': _step4ToJson(state.step4State),
      'step5State': _step5ToJson(state.step5State),
      'costPrice': state.costPrice,
      'standardSellingPrice': state.standardSellingPrice,
      'discountPrice': state.discountPrice,
      'taxId': state.taxId,
      'taxName': state.taxName,
      'taxRate': state.taxRate,
      'taxExclusive': state.taxExclusive,
    };
  }

  static AddProductWizardState fromJson(Map<String, dynamic> json) {
    return AddProductWizardState(
      currentStep: (json['currentStep'] as num?)?.toInt() ?? 1,
      targetSetupStep: (json['targetSetupStep'] as num?)?.toInt(),
      lastCompletedSetupStep:
          (json['lastCompletedSetupStep'] as num?)?.toInt(),
      productId: json['productId']?.toString(),
      localDraftId: json['localDraftId']?.toString(),
      status: json['status']?.toString() ?? 'DRAFT',
      rowVersion: (json['rowVersion'] as num?)?.toInt() ?? 0,
      productName: json['productName']?.toString() ?? '',
      internalCode: json['internalCode']?.toString() ?? '',
      categoryId: json['categoryId']?.toString(),
      brandId: json['brandId']?.toString(),
      shortDescription: json['shortDescription']?.toString() ?? '',
      longDescription: json['longDescription']?.toString() ?? '',
      productStructure: json['productStructure']?.toString() ?? 'SIMPLE',
      productStructureConfirmed:
          json['productStructureConfirmed'] as bool? ?? false,
      batchTracking: json['batchTracking'] as bool? ?? false,
      expiryTracking: json['expiryTracking'] as bool? ?? false,
      serialTracking: json['serialTracking'] as bool? ?? false,
      desiredPublishActive: json['desiredPublishActive'] as bool? ?? true,
      posSellable: json['posSellable'] as bool? ?? true,
      trackInventory: json['trackInventory'] as bool? ?? true,
      allowOnlineSale: json['allowOnlineSale'] as bool? ?? true,
      unitModel: json['unitModel']?.toString() ?? 'SINGLE_UNIT',
      productUnitId: json['productUnitId']?.toString(),
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
              ?.map((e) => _unitConversionFromJson(
                  Map<String, dynamic>.from(e as Map)))
              .toList() ??
          const [],
      stagedMediaAssets: (json['stagedMediaAssets'] as List<dynamic>?)
              ?.map((e) =>
                  _stagedImageFromJson(Map<String, dynamic>.from(e as Map)))
              .toList() ??
          const [],
      productImages: (json['productImages'] as List<dynamic>?)
              ?.map((e) =>
                  _wizardImageFromJson(Map<String, dynamic>.from(e as Map)))
              .toList() ??
          const [],
      primaryImageId: json['primaryImageId']?.toString(),
      inventoryMethod: json['inventoryMethod']?.toString(),
      componentCount: (json['componentCount'] as num?)?.toInt() ?? 0,
      componentsConfigured: json['componentsConfigured'] as bool? ?? false,
      step4State: _step4FromJson(
        Map<String, dynamic>.from(json['step4State'] as Map? ?? {}),
      ),
      step5State: _step5FromJson(
        Map<String, dynamic>.from(json['step5State'] as Map? ?? {}),
      ),
      costPrice: json['costPrice'] as num?,
      standardSellingPrice: json['standardSellingPrice'] as num?,
      discountPrice: json['discountPrice'] as num?,
      taxId: json['taxId']?.toString(),
      taxName: json['taxName']?.toString(),
      taxRate: json['taxRate'] as num?,
      taxExclusive: json['taxExclusive'] as bool? ?? true,
      isDirty: false,
      isSubmitting: false,
      isSavingDraft: false,
      isLoadingOptions: false,
      createOptions: null,
    );
  }

  static Map<String, dynamic> _unitConversionToJson(
      ProductUnitConversionItem item) {
    return {
      'uomId': item.uomId,
      'uomCode': item.uomCode,
      'uomName': item.uomName,
      'unitLevel': item.unitLevel,
      'conversionToBaseFactor': item.conversionToBaseFactor,
      'isBaseUnit': item.isBaseUnit,
      'isSellingUnit': item.isSellingUnit,
      'isPurchaseUnit': item.isPurchaseUnit,
      'isOuterPackUnit': item.isOuterPackUnit,
    };
  }

  static ProductUnitConversionItem _unitConversionFromJson(
      Map<String, dynamic> json) {
    return ProductUnitConversionItem(
      uomId: json['uomId']?.toString() ?? '',
      uomCode: json['uomCode']?.toString() ?? '',
      uomName: json['uomName']?.toString() ?? '',
      unitLevel: json['unitLevel']?.toString() ?? '',
      conversionToBaseFactor: json['conversionToBaseFactor'] as num? ?? 1,
      isBaseUnit: json['isBaseUnit'] as bool? ?? false,
      isSellingUnit: json['isSellingUnit'] as bool? ?? false,
      isPurchaseUnit: json['isPurchaseUnit'] as bool? ?? false,
      isOuterPackUnit: json['isOuterPackUnit'] as bool? ?? false,
    );
  }

  static Map<String, dynamic> _stagedImageToJson(StagedProductImage image) {
    return {
      'mediaAssetId': image.mediaAssetId,
      'publicUrl': image.publicUrl,
      'fileName': image.fileName,
      'mimeType': image.mimeType,
      'fileSizeBytes': image.fileSizeBytes,
      'createdAt': image.createdAt.toIso8601String(),
      'status': image.status,
      'isPrimary': image.isPrimary,
      'sortOrder': image.sortOrder,
      // bytes intentionally omitted — not restored from local draft
    };
  }

  static StagedProductImage _stagedImageFromJson(Map<String, dynamic> json) {
    return StagedProductImage(
      mediaAssetId: json['mediaAssetId']?.toString() ?? '',
      publicUrl: json['publicUrl']?.toString(),
      fileName: json['fileName']?.toString() ?? '',
      mimeType: json['mimeType']?.toString() ?? '',
      fileSizeBytes: (json['fileSizeBytes'] as num?)?.toInt() ?? 0,
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.now().toUtc(),
      status: json['status']?.toString() ?? 'STAGED',
      isPrimary: json['isPrimary'] as bool? ?? false,
      sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
      bytes: null,
    );
  }

  static Map<String, dynamic> _wizardImageToJson(ProductWizardImageItem image) {
    return {
      'id': image.id,
      'mediaAssetId': image.mediaAssetId,
      'imageUrl': image.imageUrl,
      'fileName': image.fileName,
      'isPrimary': image.isPrimary,
      'sortOrder': image.sortOrder,
      'isStaged': image.isStaged,
    };
  }

  static ProductWizardImageItem _wizardImageFromJson(
      Map<String, dynamic> json) {
    return ProductWizardImageItem(
      id: json['id']?.toString() ?? '',
      mediaAssetId: json['mediaAssetId']?.toString(),
      imageUrl: json['imageUrl']?.toString() ?? '',
      fileName: json['fileName']?.toString() ?? '',
      isPrimary: json['isPrimary'] as bool? ?? false,
      sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
      isStaged: json['isStaged'] as bool? ?? false,
      bytes: null,
    );
  }

  static Map<String, dynamic> _step4ToJson(Step4VariantConfigurationState s) {
    return {
      'attributeRows': s.attributeRows.map(_attributeToJson).toList(),
      'generatedVariants': s.generatedVariants.map(_variantToJson).toList(),
      'deletedVariants': s.deletedVariants.map(_tombstoneToJson).toList(),
      'expectedRowVersion': s.expectedRowVersion,
    };
  }

  static Step4VariantConfigurationState _step4FromJson(
      Map<String, dynamic> json) {
    return Step4VariantConfigurationState(
      attributeRows: (json['attributeRows'] as List<dynamic>?)
              ?.map((e) =>
                  _attributeFromJson(Map<String, dynamic>.from(e as Map)))
              .toList() ??
          const [],
      generatedVariants: (json['generatedVariants'] as List<dynamic>?)
              ?.map(
                  (e) => _variantFromJson(Map<String, dynamic>.from(e as Map)))
              .toList() ??
          const [],
      deletedVariants: (json['deletedVariants'] as List<dynamic>?)
              ?.map((e) =>
                  _tombstoneFromJson(Map<String, dynamic>.from(e as Map)))
              .toList() ??
          const [],
      expectedRowVersion: (json['expectedRowVersion'] as num?)?.toInt(),
    );
  }

  static Map<String, dynamic> _attributeToJson(AttributeConfigRow row) {
    return {
      'localId': row.localId,
      'templateId': row.templateId,
      'templateName': row.templateName,
      'selectedValues': row.selectedValues.map(_selectedValueToJson).toList(),
    };
  }

  static AttributeConfigRow _attributeFromJson(Map<String, dynamic> json) {
    return AttributeConfigRow(
      localId: json['localId']?.toString(),
      templateId: json['templateId']?.toString(),
      templateName: json['templateName']?.toString(),
      selectedValues: (json['selectedValues'] as List<dynamic>?)
              ?.map((e) => _selectedValueFromJson(
                  Map<String, dynamic>.from(e as Map)))
              .toList() ??
          const [],
    );
  }

  static Map<String, dynamic> _selectedValueToJson(SelectedOptionValue v) {
    return {
      'valueId': v.valueId,
      'templateId': v.templateId,
      'valueName': v.valueName,
      'colourHex': v.colourHex,
    };
  }

  static SelectedOptionValue _selectedValueFromJson(Map<String, dynamic> json) {
    return SelectedOptionValue(
      valueId: json['valueId']?.toString() ?? '',
      templateId: json['templateId']?.toString(),
      valueName: json['valueName']?.toString() ?? '',
      colourHex: json['colourHex']?.toString(),
    );
  }

  static Map<String, dynamic> _variantToJson(GeneratedVariantRow v) {
    return {
      'clientCombinationKey': v.clientCombinationKey,
      'productVariantId': v.productVariantId,
      'combinationLabel': v.combinationLabel,
      'displayLabel': v.displayLabel,
      'isIncluded': v.isIncluded,
      'exactImageMediaAssetId': v.exactImageMediaAssetId,
      'effectiveImageUrl': v.effectiveImageUrl,
      'selectedValues': v.selectedValues.map(_selectedValueToJson).toList(),
      'optionCombinationHash': v.optionCombinationHash,
    };
  }

  static GeneratedVariantRow _variantFromJson(Map<String, dynamic> json) {
    return GeneratedVariantRow(
      clientCombinationKey: json['clientCombinationKey']?.toString() ?? '',
      productVariantId: json['productVariantId']?.toString(),
      combinationLabel: json['combinationLabel']?.toString() ?? '',
      displayLabel: json['displayLabel']?.toString(),
      isIncluded: json['isIncluded'] as bool? ?? true,
      exactImageMediaAssetId: json['exactImageMediaAssetId']?.toString(),
      effectiveImageUrl: json['effectiveImageUrl']?.toString(),
      selectedValues: (json['selectedValues'] as List<dynamic>?)
              ?.map((e) => _selectedValueFromJson(
                  Map<String, dynamic>.from(e as Map)))
              .toList() ??
          const [],
      optionCombinationHash: json['optionCombinationHash']?.toString(),
    );
  }

  static Map<String, dynamic> _tombstoneToJson(DeletedVariantTombstone t) {
    return {
      'clientCombinationKey': t.clientCombinationKey,
      'productVariantId': t.productVariantId,
      'optionCombinationHash': t.optionCombinationHash,
      'selectedValues': t.selectedValues.map(_selectedValueToJson).toList(),
    };
  }

  static DeletedVariantTombstone _tombstoneFromJson(Map<String, dynamic> json) {
    return DeletedVariantTombstone(
      clientCombinationKey: json['clientCombinationKey']?.toString() ?? '',
      productVariantId: json['productVariantId']?.toString(),
      optionCombinationHash: json['optionCombinationHash']?.toString(),
      selectedValues: (json['selectedValues'] as List<dynamic>?)
              ?.map((e) => _selectedValueFromJson(
                  Map<String, dynamic>.from(e as Map)))
              .toList() ??
          const [],
    );
  }

  static Map<String, dynamic> _step5ToJson(Step5BarcodeSkuState s) {
    return {
      'baseSku': s.baseSku,
      'parentProductBarcode': s.parentProductBarcode,
      'identifierTargets':
          s.identifierTargets.map((e) => e.toJson()).toList(),
      'assignments': s.assignments.map((e) => e.toJson()).toList(),
    };
  }

  static Step5BarcodeSkuState _step5FromJson(Map<String, dynamic> json) {
    return Step5BarcodeSkuState(
      baseSku: json['baseSku']?.toString() ?? '',
      parentProductBarcode: json['parentProductBarcode']?.toString() ?? '',
      identifierTargets: (json['identifierTargets'] as List<dynamic>?)
              ?.map((e) => Step5IdentifierTargetDto.fromJson(
                  Map<String, dynamic>.from(e as Map)))
              .toList() ??
          const [],
      assignments: (json['assignments'] as List<dynamic>?)
              ?.map((e) => BarcodeSkuAssignmentDto.fromJson(
                  Map<String, dynamic>.from(e as Map)))
              .toList() ??
          const [],
    );
  }
}
