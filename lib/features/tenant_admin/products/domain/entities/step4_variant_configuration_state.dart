import 'package:flutter/foundation.dart';

@immutable
class Step4VariantConfigurationState {
  final List<AttributeConfigRow> attributeRows;
  final List<GeneratedVariantRow> generatedVariants;
  final List<DeletedVariantTombstone> deletedVariants;
  final String? selectedVariantIdForEdit;
  final bool isGenerating;
  final bool isSaving;
  final Map<String, String> fieldErrors;
  final int? expectedRowVersion;

  const Step4VariantConfigurationState({
    this.attributeRows = const [],
    this.generatedVariants = const [],
    this.deletedVariants = const [],
    this.selectedVariantIdForEdit,
    this.isGenerating = false,
    this.isSaving = false,
    this.fieldErrors = const {},
    this.expectedRowVersion,
  });

  int get totalGeneratedCount => generatedVariants.length;
  int get includedCount => generatedVariants.where((v) => v.isIncluded).length;
  int get activeAttributeCount => attributeRows.where((r) => r.isValid).length;

  Step4VariantConfigurationState copyWith({
    List<AttributeConfigRow>? attributeRows,
    List<GeneratedVariantRow>? generatedVariants,
    List<DeletedVariantTombstone>? deletedVariants,
    String? selectedVariantIdForEdit,
    bool clearSelectedVariantIdForEdit = false,
    bool? isGenerating,
    bool? isSaving,
    Map<String, String>? fieldErrors,
    int? expectedRowVersion,
  }) {
    return Step4VariantConfigurationState(
      attributeRows: attributeRows ?? this.attributeRows,
      generatedVariants: generatedVariants ?? this.generatedVariants,
      deletedVariants: deletedVariants ?? this.deletedVariants,
      selectedVariantIdForEdit: clearSelectedVariantIdForEdit
          ? null
          : (selectedVariantIdForEdit ?? this.selectedVariantIdForEdit),
      isGenerating: isGenerating ?? this.isGenerating,
      isSaving: isSaving ?? this.isSaving,
      fieldErrors: fieldErrors ?? this.fieldErrors,
      expectedRowVersion: expectedRowVersion ?? this.expectedRowVersion,
    );
  }
}

@immutable
class AttributeConfigRow {
  final String localId;
  final String? templateId;
  final String? templateName;
  final List<SelectedOptionValue> selectedValues;

  AttributeConfigRow({
    String? localId,
    this.templateId,
    this.templateName,
    this.selectedValues = const [],
  }) : localId = localId ?? DateTime.now().microsecondsSinceEpoch.toString();

  bool get isValid => templateId != null && selectedValues.isNotEmpty;

  AttributeConfigRow copyWith({
    String? localId,
    String? templateId,
    String? templateName,
    List<SelectedOptionValue>? selectedValues,
  }) {
    return AttributeConfigRow(
      localId: localId ?? this.localId,
      templateId: templateId ?? this.templateId,
      templateName: templateName ?? this.templateName,
      selectedValues: selectedValues ?? this.selectedValues,
    );
  }
}

@immutable
class SelectedOptionValue {
  final String valueId;
  final String? templateId;
  final String valueName;
  final String? colourHex;

  const SelectedOptionValue({
    required this.valueId,
    this.templateId,
    required this.valueName,
    this.colourHex,
  });
}

@immutable
class GeneratedVariantRow {
  final String clientCombinationKey;
  final String? productVariantId;
  final String combinationLabel;
  final String? displayLabel;
  final bool isIncluded;
  final String? exactImageMediaAssetId;
  final String? effectiveImageUrl;
  final List<SelectedOptionValue> selectedValues;
  final String? optionCombinationHash;

  const GeneratedVariantRow({
    required this.clientCombinationKey,
    this.productVariantId,
    required this.combinationLabel,
    this.displayLabel,
    this.isIncluded = true,
    this.exactImageMediaAssetId,
    this.effectiveImageUrl,
    this.selectedValues = const [],
    this.optionCombinationHash,
  });

  GeneratedVariantRow copyWith({
    String? clientCombinationKey,
    String? productVariantId,
    String? combinationLabel,
    String? displayLabel,
    bool clearDisplayLabel = false,
    bool? isIncluded,
    String? exactImageMediaAssetId,
    bool clearExactImageMediaAssetId = false,
    String? effectiveImageUrl,
    bool clearEffectiveImageUrl = false,
    List<SelectedOptionValue>? selectedValues,
    String? optionCombinationHash,
  }) {
    return GeneratedVariantRow(
      clientCombinationKey: clientCombinationKey ?? this.clientCombinationKey,
      productVariantId: productVariantId ?? this.productVariantId,
      combinationLabel: combinationLabel ?? this.combinationLabel,
      displayLabel:
          clearDisplayLabel ? null : (displayLabel ?? this.displayLabel),
      isIncluded: isIncluded ?? this.isIncluded,
      exactImageMediaAssetId: clearExactImageMediaAssetId
          ? null
          : (exactImageMediaAssetId ?? this.exactImageMediaAssetId),
      effectiveImageUrl: clearEffectiveImageUrl
          ? null
          : (effectiveImageUrl ?? this.effectiveImageUrl),
      selectedValues: selectedValues ?? this.selectedValues,
      optionCombinationHash:
          optionCombinationHash ?? this.optionCombinationHash,
    );
  }
}

@immutable
class DeletedVariantTombstone {
  final String clientCombinationKey;
  final String? productVariantId;
  final String? optionCombinationHash;
  final List<SelectedOptionValue> selectedValues;

  const DeletedVariantTombstone({
    required this.clientCombinationKey,
    this.productVariantId,
    this.optionCombinationHash,
    this.selectedValues = const [],
  });
}
