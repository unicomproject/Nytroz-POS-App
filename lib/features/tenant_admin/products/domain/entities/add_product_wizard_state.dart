import 'staged_product_image.dart';
import 'step4_variant_configuration_state.dart';
import 'step5_barcode_sku_state.dart';
import 'tenant_product_create_options.dart';

class ProductUnitConversionItem {
  final String uomId;
  final String uomCode;
  final String uomName;
  final String unitLevel;
  final num conversionToBaseFactor;
  final bool isBaseUnit;
  final bool isSellingUnit;
  final bool isPurchaseUnit;
  final bool isOuterPackUnit;

  const ProductUnitConversionItem({
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
}

class AddProductWizardState {
  final int currentStep; // 1 to 7
  final int? targetSetupStep;
  final int? lastCompletedSetupStep;
  final String? productId;

  /// Frontend-local draft identity (not a backend product id).
  final String? localDraftId;
  final String status;
  final int rowVersion;

  // Step 1 Form Fields
  final String productName;
  final String internalCode;
  final String? categoryId;
  final String? brandId;
  final String shortDescription;
  final String longDescription;

  // Step 2 Form Fields (Canonical cross-step state)
  final String productStructure; // 'SIMPLE', 'VARIANT', 'BUNDLE'
  final bool productStructureConfirmed;
  final bool batchTracking;
  final bool expiryTracking;
  final bool serialTracking;

  // Status & Options Toggles (Canonical cross-step state)
  final bool desiredPublishActive;
  final bool posSellable;
  final bool trackInventory;
  final bool allowOnlineSale;

  // Step 3 Form Fields (Units & Pack Conversion)
  final String unitModel; // 'SINGLE_UNIT', 'MULTIPLE_UNITS'
  final String? productUnitId;
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
  final List<ProductUnitConversionItem> unitConversions;

  // Product Media State
  final List<StagedProductImage> stagedMediaAssets;
  final List<ProductWizardImageItem> productImages;
  final String? primaryImageId;
  final bool isImageManagerOpen;

  // Controller UI & Validation States
  final bool isDirty;
  final bool isSubmitting;
  final bool isSavingDraft;
  final bool isLoadingOptions;
  final String? optionsError;
  final String? pageError;
  final Map<String, String> fieldErrors;

  final String? inventoryMethod;
  final int componentCount;
  final bool componentsConfigured;

  // Options cache
  final TenantProductCreateOptions? createOptions;

  // Step 4 Variant Configuration State
  final Step4VariantConfigurationState step4State;

  // Step 5 Barcode & SKU State
  final Step5BarcodeSkuState step5State;

  // Step 6 Pricing & Tax State
  final num? costPrice;
  final num? standardSellingPrice;
  final num? discountPrice;
  final String? taxId;
  final String? taxName;
  final num? taxRate;
  final bool taxExclusive;

  const AddProductWizardState({
    this.currentStep = 1,
    this.targetSetupStep,
    this.lastCompletedSetupStep,
    this.productId,
    this.localDraftId,
    this.status = 'DRAFT',
    this.rowVersion = 0,
    this.productName = '',
    this.internalCode = '',
    this.categoryId,
    this.brandId,
    this.shortDescription = '',
    this.longDescription = '',
    this.productStructure = 'SIMPLE',
    this.productStructureConfirmed = false,
    this.batchTracking = false,
    this.expiryTracking = false,
    this.serialTracking = false,
    this.desiredPublishActive = true,
    this.posSellable = true,
    this.trackInventory = true,
    this.allowOnlineSale = true,
    this.unitModel = 'SINGLE_UNIT',
    this.productUnitId,
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
    this.stagedMediaAssets = const [],
    this.productImages = const [],
    this.primaryImageId,
    this.isImageManagerOpen = false,
    this.isDirty = false,
    this.isSubmitting = false,
    this.isSavingDraft = false,
    this.isLoadingOptions = false,
    this.optionsError,
    this.pageError,
    this.fieldErrors = const {},
    this.inventoryMethod,
    this.componentCount = 0,
    this.componentsConfigured = false,
    this.createOptions,
    this.step4State = const Step4VariantConfigurationState(),
    this.step5State = const Step5BarcodeSkuState(),
    this.costPrice,
    this.standardSellingPrice,
    this.discountPrice,
    this.taxId,
    this.taxName,
    this.taxRate,
    this.taxExclusive = true,
  });

  bool get isEditMode => productId != null && productId!.isNotEmpty;
  bool get hasImages =>
      productImages.isNotEmpty || stagedMediaAssets.isNotEmpty;

  int get totalImageCount {
    if (isEditMode) {
      return productImages.length;
    }
    return stagedMediaAssets.length;
  }

  AddProductWizardState copyWith({
    int? currentStep,
    int? targetSetupStep,
    bool clearTargetSetupStep = false,
    int? lastCompletedSetupStep,
    String? productId,
    String? localDraftId,
    bool clearLocalDraftId = false,
    String? status,
    int? rowVersion,
    String? productName,
    String? internalCode,
    String? categoryId,
    String? brandId,
    bool clearBrandId = false,
    String? shortDescription,
    String? longDescription,
    String? productStructure,
    bool? productStructureConfirmed,
    bool? batchTracking,
    bool? expiryTracking,
    bool? serialTracking,
    bool? desiredPublishActive,
    bool? posSellable,
    bool? trackInventory,
    bool? allowOnlineSale,
    String? unitModel,
    String? productUnitId,
    bool clearProductUnitId = false,
    String? baseUnitId,
    bool clearBaseUnitId = false,
    String? baseUnitName,
    String? sellingUnitId,
    bool clearSellingUnitId = false,
    String? sellingUnitName,
    String? purchaseUnitId,
    bool clearPurchaseUnitId = false,
    String? purchaseUnitName,
    String? outerPackUnitId,
    bool clearOuterPackUnitId = false,
    String? outerPackUnitName,
    num? itemsPerPurchaseUnit,
    bool clearItemsPerPurchaseUnit = false,
    num? purchaseUnitsPerOuterPack,
    bool clearPurchaseUnitsPerOuterPack = false,
    bool? allowDecimalQuantity,
    List<ProductUnitConversionItem>? unitConversions,
    List<StagedProductImage>? stagedMediaAssets,
    List<ProductWizardImageItem>? productImages,
    String? primaryImageId,
    bool clearPrimaryImageId = false,
    bool? isImageManagerOpen,
    bool? isDirty,
    bool? isSubmitting,
    bool? isSavingDraft,
    bool? isLoadingOptions,
    String? optionsError,
    bool clearOptionsError = false,
    String? pageError,
    bool clearPageError = false,
    Map<String, String>? fieldErrors,
    String? inventoryMethod,
    int? componentCount,
    bool? componentsConfigured,
    TenantProductCreateOptions? createOptions,
    Step4VariantConfigurationState? step4State,
    Step5BarcodeSkuState? step5State,
    num? costPrice,
    bool clearCostPrice = false,
    num? standardSellingPrice,
    bool clearStandardSellingPrice = false,
    num? discountPrice,
    bool clearDiscountPrice = false,
    String? taxId,
    bool clearTaxId = false,
    String? taxName,
    bool clearTaxName = false,
    num? taxRate,
    bool clearTaxRate = false,
    bool? taxExclusive,
  }) {
    return AddProductWizardState(
      currentStep: currentStep ?? this.currentStep,
      targetSetupStep: clearTargetSetupStep
          ? null
          : (targetSetupStep ?? this.targetSetupStep),
      lastCompletedSetupStep:
          lastCompletedSetupStep ?? this.lastCompletedSetupStep,
      productId: productId ?? this.productId,
      localDraftId:
          clearLocalDraftId ? null : (localDraftId ?? this.localDraftId),
      status: status ?? this.status,
      rowVersion: rowVersion ?? this.rowVersion,
      productName: productName ?? this.productName,
      internalCode: internalCode ?? this.internalCode,
      categoryId: categoryId ?? this.categoryId,
      brandId: clearBrandId ? null : (brandId ?? this.brandId),
      shortDescription: shortDescription ?? this.shortDescription,
      longDescription: longDescription ?? this.longDescription,
      productStructure: productStructure ?? this.productStructure,
      productStructureConfirmed:
          productStructureConfirmed ?? this.productStructureConfirmed,
      batchTracking: batchTracking ?? this.batchTracking,
      expiryTracking: expiryTracking ?? this.expiryTracking,
      serialTracking: serialTracking ?? this.serialTracking,
      desiredPublishActive: desiredPublishActive ?? this.desiredPublishActive,
      posSellable: posSellable ?? this.posSellable,
      trackInventory: trackInventory ?? this.trackInventory,
      allowOnlineSale: allowOnlineSale ?? this.allowOnlineSale,
      unitModel: unitModel ?? this.unitModel,
      productUnitId:
          clearProductUnitId ? null : (productUnitId ?? this.productUnitId),
      baseUnitId: clearBaseUnitId ? null : (baseUnitId ?? this.baseUnitId),
      baseUnitName: baseUnitName ?? this.baseUnitName,
      sellingUnitId:
          clearSellingUnitId ? null : (sellingUnitId ?? this.sellingUnitId),
      sellingUnitName: sellingUnitName ?? this.sellingUnitName,
      purchaseUnitId:
          clearPurchaseUnitId ? null : (purchaseUnitId ?? this.purchaseUnitId),
      purchaseUnitName: purchaseUnitName ?? this.purchaseUnitName,
      outerPackUnitId: clearOuterPackUnitId
          ? null
          : (outerPackUnitId ?? this.outerPackUnitId),
      outerPackUnitName: outerPackUnitName ?? this.outerPackUnitName,
      itemsPerPurchaseUnit: clearItemsPerPurchaseUnit
          ? null
          : (itemsPerPurchaseUnit ?? this.itemsPerPurchaseUnit),
      purchaseUnitsPerOuterPack: clearPurchaseUnitsPerOuterPack
          ? null
          : (purchaseUnitsPerOuterPack ?? this.purchaseUnitsPerOuterPack),
      allowDecimalQuantity: allowDecimalQuantity ?? this.allowDecimalQuantity,
      unitConversions: unitConversions ?? this.unitConversions,
      stagedMediaAssets: stagedMediaAssets ?? this.stagedMediaAssets,
      productImages: productImages ?? this.productImages,
      primaryImageId:
          clearPrimaryImageId ? null : (primaryImageId ?? this.primaryImageId),
      isImageManagerOpen: isImageManagerOpen ?? this.isImageManagerOpen,
      isDirty: isDirty ?? this.isDirty,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      isSavingDraft: isSavingDraft ?? this.isSavingDraft,
      isLoadingOptions: isLoadingOptions ?? this.isLoadingOptions,
      optionsError:
          clearOptionsError ? null : (optionsError ?? this.optionsError),
      pageError: clearPageError ? null : (pageError ?? this.pageError),
      fieldErrors: fieldErrors ?? this.fieldErrors,
      inventoryMethod: inventoryMethod ?? this.inventoryMethod,
      componentCount: componentCount ?? this.componentCount,
      componentsConfigured: componentsConfigured ?? this.componentsConfigured,
      createOptions: createOptions ?? this.createOptions,
      step4State: step4State ?? this.step4State,
      step5State: step5State ?? this.step5State,
      costPrice: clearCostPrice ? null : (costPrice ?? this.costPrice),
      standardSellingPrice: clearStandardSellingPrice
          ? null
          : (standardSellingPrice ?? this.standardSellingPrice),
      discountPrice:
          clearDiscountPrice ? null : (discountPrice ?? this.discountPrice),
      taxId: clearTaxId ? null : (taxId ?? this.taxId),
      taxName: clearTaxName ? null : (taxName ?? this.taxName),
      taxRate: clearTaxRate ? null : (taxRate ?? this.taxRate),
      taxExclusive: taxExclusive ?? this.taxExclusive,
    );
  }
}
