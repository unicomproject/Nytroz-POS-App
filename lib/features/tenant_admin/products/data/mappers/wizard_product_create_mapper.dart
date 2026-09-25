import '../dtos/save_product_draft_request_dto.dart';
import '../dtos/barcode_sku_dtos.dart';
import '../dtos/pricing_tax_dtos.dart';
import '../../domain/entities/add_product_wizard_state.dart';
import '../../domain/entities/product_wizard_capabilities.dart';
import '../../domain/entities/variant_configuration_state.dart';
import '../../presentation/utils/barcode_type.dart';
import '../../presentation/utils/variant_pricing.dart';

/// Builds the final Step 7 wizard-create payload from [AddProductWizardState].
class WizardProductCreateMapper {
  const WizardProductCreateMapper._();

  static Map<String, dynamic> toWizardCreateJson(
    AddProductWizardState state, {
    String? idempotencyKey,
    ProductWizardCapabilities? capabilities,
  }) {
    final structure = state.productStructure.toUpperCase();
    final isVariant = structure == 'VARIANT';
    final includeTracking =
        capabilities == null || capabilities.canUseAdvancedInventoryTracking;
    final includeMedia =
        capabilities == null || capabilities.canManageProductMedia;
    final includeVariant =
        isVariant && (capabilities == null || capabilities.canManageVariants);
    final includeCost = capabilities == null || capabilities.canViewProductCost;
    final includeChannels =
        capabilities == null || capabilities.canManageProductChannels;

    return {
      'productName': state.productName.trim(),
      if (state.internalCode.trim().isNotEmpty)
        'productCode': state.internalCode.trim(),
      'categoryId': state.categoryId,
      if (state.brandId != null && state.brandId!.isNotEmpty)
        'brandId': state.brandId,
      if (state.shortDescription.trim().isNotEmpty)
        'shortDescription': state.shortDescription.trim(),
      if (state.longDescription.trim().isNotEmpty)
        'longDescription': state.longDescription.trim(),
      'desiredPublishActive': state.desiredPublishActive,
      'posSellable': includeChannels ? state.posSellable : true,
      'allowOnlineSale': includeChannels ? state.allowOnlineSale : false,
      'trackInventory': state.trackInventory,
      'batchTracking': includeTracking ? state.batchTracking : false,
      'expiryTracking': includeTracking ? state.expiryTracking : false,
      'serialTracking': includeTracking ? state.serialTracking : false,
      'productStructure': structure,
      if (!isVariant) ..._simpleUnits(state),
      if (includeVariant)
        'variantConfiguration': _variantConfiguration(state).toJson(),
      'barcodeSkuConfiguration': _barcodeSku(state, isVariant).toJson(),
      'pricingTax':
          _pricingTax(state, includeCost: includeCost).toWizardCreateJson(),
      if (includeMedia && state.stagedMediaAssets.isNotEmpty)
        'stagedMediaAssetIds': state.stagedMediaAssets
            .map((m) => m.mediaAssetId)
            .where((id) => id.isNotEmpty)
            .toList(),
      if (includeTracking && state.batchTracking && state.initialBatchNumber.trim().isNotEmpty)
        'initialBatchNumber': state.initialBatchNumber.trim(),
      if (includeTracking && state.expiryTracking && state.initialExpiryDate != null)
        'initialExpiryDate': _dateOnly(state.initialExpiryDate!),
      if (includeTracking && state.serialTracking && state.initialSerialNumber.trim().isNotEmpty)
        'initialSerialNumber': state.initialSerialNumber.trim(),
      if (state.confirmClearIncompatibleInitialTracking)
        'confirmClearIncompatibleInitialTracking': true,
      if (includeTracking &&
          state.initialTrackingAssignedVariantId != null &&
          _isValidGuid(state.initialTrackingAssignedVariantId!))
        'initialTrackingAssignedVariantId':
            state.initialTrackingAssignedVariantId,
      if (includeTracking && state.trackInventory && state.openingStockDrafts.isNotEmpty)
        'quantityDraft': {
          'stockOwners': state.openingStockDrafts.values
              .map((draft) => draft.toJson())
              .toList(),
        },
      if (idempotencyKey != null && idempotencyKey.isNotEmpty)
        'idempotencyKey': idempotencyKey,
      if (state.scanStepState.categoryResolution != null &&
          state.scanStepState.categoryResolution!.provider.trim().isNotEmpty &&
          state.scanStepState.categoryResolution!.externalCategoryKey != null &&
          state.scanStepState.categoryResolution!.externalCategoryKey!.trim().isNotEmpty)
        'externalCategoryMappingContext': {
          'provider': state.scanStepState.categoryResolution!.provider.trim(),
          'externalCategoryKey':
              state.scanStepState.categoryResolution!.externalCategoryKey!.trim(),
          if (state.scanStepState.categoryResolution!.externalCategoryName != null &&
              state.scanStepState.categoryResolution!.externalCategoryName!.trim().isNotEmpty)
            'externalCategoryName':
                state.scanStepState.categoryResolution!.externalCategoryName!.trim(),
        },
      if (state.scanStepState.brandResolution != null &&
          state.scanStepState.brandResolution!.provider.trim().isNotEmpty &&
          state.scanStepState.brandResolution!.externalBrandKey != null &&
          state.scanStepState.brandResolution!.externalBrandKey!.trim().isNotEmpty)
        'externalBrandMappingContext': {
          'provider': state.scanStepState.brandResolution!.provider.trim(),
          'externalBrandKey':
              state.scanStepState.brandResolution!.externalBrandKey!.trim(),
          if (state.scanStepState.brandResolution!.externalBrandName != null &&
              state.scanStepState.brandResolution!.externalBrandName!.trim().isNotEmpty)
            'externalBrandName':
                state.scanStepState.brandResolution!.externalBrandName!.trim(),
        },
    };
  }

  static SaveProductDraftRequestDto toWizardDraftDto(
    AddProductWizardState state, {
    String? wizardAction,
    bool advanceStep = false,
  }) {
    final structure = state.productStructure.toUpperCase();
    final isVariant = structure == 'VARIANT';
    final baseSku = state.step5State.baseSku.trim();
    final shouldApplyAutoSku = isVariant && baseSku.isNotEmpty;

    return SaveProductDraftRequestDto(
      productName: state.productName.trim(),
      productCode: state.internalCode.trim(),
      categoryId: state.categoryId,
      brandId: state.brandId,
      shortDescription: state.shortDescription.trim(),
      longDescription: state.longDescription.trim(),
      desiredPublishActive: state.desiredPublishActive,
      posSellable: state.posSellable,
      allowOnlineSale: state.allowOnlineSale,
      trackInventory: state.trackInventory,
      trackingMethod: state.trackingMethod,
      batchTracking: state.batchTracking,
      expiryTracking: state.expiryTracking,
      serialTracking: state.serialTracking,
      productStructure: structure,
      currentSetupStep: state.currentStep,
      advanceStep: advanceStep,
      wizardAction: wizardAction,
      expectedRowVersion: state.rowVersion,
      stagedMediaAssetIds: state.stagedMediaAssets
          .map((m) => m.mediaAssetId)
          .where((id) => id.isNotEmpty)
          .toList(),
      unitModel: state.unitModel,
      productUnitId: state.productUnitId,
      baseUnitId: state.baseUnitId ?? state.productUnitId,
      sellingUnitId: state.sellingUnitId,
      purchaseUnitId: state.purchaseUnitId,
      outerPackUnitId: state.outerPackUnitId,
      itemsPerPurchaseUnit: state.itemsPerPurchaseUnit,
      purchaseUnitsPerOuterPack: state.purchaseUnitsPerOuterPack,
      allowDecimalQuantity: state.allowDecimalQuantity,
      variantConfiguration:
          isVariant ? _variantConfiguration(state) : null,
      barcodeSkuConfiguration: _barcodeSku(state, isVariant),
      pricingTaxConfiguration: _pricingTax(state),
      initialBatchNumber: state.batchTracking ? state.initialBatchNumber.trim() : '',
      initialExpiryDate: state.expiryTracking ? state.initialExpiryDate : null,
      initialSerialNumber: state.serialTracking ? state.initialSerialNumber.trim() : '',
      confirmClearIncompatibleInitialTracking:
          state.confirmClearIncompatibleInitialTracking,
      initialTrackingAssignedVariantId: state.initialTrackingAssignedVariantId,
      applyCompositeStep3Identifiers: false,
      autoSkuBase: null,
    );
  }

  static Map<String, dynamic> _simpleUnits(AddProductWizardState state) {
    final baseUnit = state.baseUnitId ?? state.productUnitId;
    return {
      'unitModel': state.unitModel,
      if (state.productUnitId != null) 'productUnitId': state.productUnitId,
      if (baseUnit != null) 'baseUnitId': baseUnit,
      if (state.sellingUnitId != null) 'sellingUnitId': state.sellingUnitId,
      if (state.purchaseUnitId != null) 'purchaseUnitId': state.purchaseUnitId,
      if (state.outerPackUnitId != null)
        'outerPackUnitId': state.outerPackUnitId,
      if (state.itemsPerPurchaseUnit != null)
        'itemsPerPurchaseUnit': state.itemsPerPurchaseUnit,
      if (state.purchaseUnitsPerOuterPack != null)
        'purchaseUnitsPerOuterPack': state.purchaseUnitsPerOuterPack,
      'allowDecimalQuantity': state.allowDecimalQuantity,
    };
  }

  static VariantConfigurationDto _variantConfiguration(
      AddProductWizardState state) {
    final options = <VariantConfigurationOptionDto>[];
    for (var i = 0; i < state.step4State.attributeRows.length; i++) {
      final row = state.step4State.attributeRows[i];
      if (!row.isValid) continue;
      final name = row.templateName ?? row.templateId ?? 'Attribute $i';
      options.add(VariantConfigurationOptionDto(
        sourceOptionTemplateId: _guidOrNull(row.templateId),
        optionName: name,
        optionCode: name.toUpperCase().replaceAll(' ', '_'),
        sortOrder: i,
        values: [
          for (var j = 0; j < row.selectedValues.length; j++)
            VariantConfigurationOptionValueDto(
              sourceOptionTemplateValueId:
                  _guidOrNull(row.selectedValues[j].valueId),
              valueName: row.selectedValues[j].valueName,
              valueCode: row.selectedValues[j].valueName
                  .toUpperCase()
                  .replaceAll(' ', '_'),
              sortOrder: j,
            ),
        ],
      ));
    }

    final variants = state.step4State.generatedVariants
        .where((v) => v.isIncluded)
        .map((v) => VariantConfigurationVariantDto(
              clientCombinationKey: v.clientCombinationKey,
              productVariantId: null,
              displayLabel: v.displayLabel ?? v.combinationLabel,
              includeVariant: true,
              exactImageMediaAssetId: v.exactImageMediaAssetId,
              selectedValues: v.selectedValues
                  .map((sv) => VariantConfigurationSelectedValueDto(
                        optionName: _optionNameForValue(state, sv),
                        valueName: sv.valueName,
                        sourceOptionTemplateId: _guidOrNull(sv.templateId),
                        sourceOptionTemplateValueId: _guidOrNull(sv.valueId),
                      ))
                  .toList(),
            ))
        .toList();

    final deleted = state.step4State.deletedVariants
        .map((d) => VariantConfigurationDeletedCombinationDto(
              clientCombinationKey: d.clientCombinationKey,
              productVariantId: d.productVariantId,
              optionCombinationHash: d.optionCombinationHash,
            ))
        .toList();

    return VariantConfigurationDto(
      options: options,
      variants: variants,
      deletedCombinations: deleted,
    );
  }

  static String? _optionNameForValue(
      AddProductWizardState state, SelectedOptionValue value) {
    for (final row in state.step4State.attributeRows) {
      if (row.selectedValues.any((v) => v.valueId == value.valueId)) {
        return row.templateName ?? row.templateId;
      }
    }
    return value.templateId;
  }

  static BarcodeSkuConfigurationDto _barcodeSku(
      AddProductWizardState state, bool isVariant) {
    if (!isVariant) {
      final sku = state.step5State.baseSku.trim().isNotEmpty
          ? state.step5State.baseSku.trim()
          : state.step5State.assignments
              .where((a) => a.clientCombinationKey == 'SIMPLE_DEFAULT')
              .map((a) => a.sku)
              .firstWhere((s) => s != null && s.trim().isNotEmpty,
                  orElse: () => null);
      final barcode = state.step5State.parentProductBarcode.trim().isNotEmpty
          ? state.step5State.parentProductBarcode.trim()
          : state.step5State.assignments
              .where((a) => a.clientCombinationKey == 'SIMPLE_DEFAULT')
              .map((a) => a.barcode)
              .firstWhere((b) => b != null && b.trim().isNotEmpty,
                  orElse: () => null);

      final existingType = state.step5State.parentBarcodeType ??
          state.step5State.assignments
              .where((a) => a.clientCombinationKey == 'SIMPLE_DEFAULT')
              .map((a) => a.barcodeType)
              .whereType<String>()
              .where((t) => t.trim().isNotEmpty)
              .firstOrNull;
      return BarcodeSkuConfigurationDto(
        identifierTargets: const [],
        assignments: [
          BarcodeSkuAssignmentDto(
            clientCombinationKey: 'SIMPLE_DEFAULT',
            productVariantId: null,
            sku: sku,
            barcode: barcode,
            barcodeType: resolveBarcodeType(
              barcode: barcode,
              existingType: existingType,
            ),
            isAssigned: true,
          ),
        ],
      );
    }

    final includedKeys = state.step4State.generatedVariants
        .where((v) => v.isIncluded)
        .map((v) => v.clientCombinationKey)
        .toSet();

    final assignments = state.step5State.assignments
        .where((a) => includedKeys.contains(a.clientCombinationKey))
        .map((a) => BarcodeSkuAssignmentDto(
              clientCombinationKey: a.clientCombinationKey,
              productVariantId: a.productVariantId,
              displayName: a.displayName,
              sku: a.sku,
              barcode: a.barcode,
              barcodeType: resolveBarcodeType(
                barcode: a.barcode,
                existingType: a.barcodeType,
              ),
              isAssigned: a.isAssigned,
            ))
        .toList();

    return BarcodeSkuConfigurationDto(
      identifierTargets: const [],
      assignments: assignments,
    );
  }

  static PricingTaxConfigurationDto _pricingTax(
    AddProductWizardState state, {
    bool includeCost = true,
  }) {
    final isVariant = state.productStructure.toUpperCase() == 'VARIANT';
    if (isVariant) {
      final snapshot = buildVariantPriceSnapshot(state);
      return PricingTaxConfigurationDto(
        costPrice: includeCost ? state.costPrice : null,
        standardSellingPrice: null,
        discountPrice: null,
        taxId: state.taxId,
        taxExclusive: state.taxExclusive,
        applySameTaxToAllVariants: state.applySameTaxToAllVariants,
        variantPrices: snapshot,
      );
    }

    return PricingTaxConfigurationDto(
      costPrice: includeCost ? state.costPrice : null,
      standardSellingPrice: state.standardSellingPrice,
      discountPrice: state.discountPrice,
      taxId: state.taxId,
      taxExclusive: state.taxExclusive,
    );
  }

  static String _dateOnly(DateTime value) {
    final local = DateTime(value.year, value.month, value.day);
    final y = local.year.toString().padLeft(4, '0');
    final m = local.month.toString().padLeft(2, '0');
    final d = local.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  static String? _guidOrNull(String? value) {
    if (value == null || value.isEmpty) return null;
    final guid = RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
    );
    return guid.hasMatch(value) ? value : null;
  }
}

/// Wire JSON for wizard-create (backend expects taxClassId).
extension WizardCreatePricingJson on PricingTaxConfigurationDto {
  Map<String, dynamic> toWizardCreateJson() {
    return {
      if (costPrice != null) 'costPrice': costPrice,
      if (standardSellingPrice != null)
        'standardSellingPrice': standardSellingPrice,
      if (discountPrice != null) 'discountPrice': discountPrice,
      if (taxId != null) 'taxClassId': taxId,
      'taxExclusive': taxExclusive,
      'applySameTaxToAllVariants': applySameTaxToAllVariants,
      if (variantPrices != null)
        'variantPrices': variantPrices!.map((e) => e.toSnapshotJson()).toList(),
    };
  }
}

// Validates that a string matches UUID/GUID format (xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx).
// Client-side combination keys like "Size:L|Color:Red" will return false.
bool _isValidGuid(String value) {
  if (value.isEmpty) return false;
  final guidRegex = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
  );
  return guidRegex.hasMatch(value);
}
