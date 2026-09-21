import '../../data/dtos/product_setup_scan_dtos.dart';

/// Internal Step 1 panels — never global stepper items.
enum ScanBarcodePanel {
  scanReady,
  validating,
  localMatch,
  noLocalMatch,
  externalLookup,
  externalFound,
  externalNoMatch,
  manualEntry,
  invalid,
  noBarcode,
}

class ScanBarcodeStepState {
  const ScanBarcodeStepState({
    this.panel = ScanBarcodePanel.scanReady,
    this.candidateBarcode = '',
    this.inputMode = 'SCAN',
    this.identifierStandard,
    this.barcodeType,
    this.invalidReason,
    this.localMatch,
    this.externalStatus,
    this.externalSuggestion,
    this.externalSourceReference,
    this.externalRetryAllowed = false,
    this.categoryResolution,
    this.noBarcodeReason,
    this.noBarcodeProductName = '',
    this.noBarcodeCategoryId,
    this.autoGenerateSku = true,
    this.generatedSkuCandidate,
    this.isBusy = false,
    this.lastError,
    this.applyExternalPrefill = true,
  });

  final ScanBarcodePanel panel;
  final String candidateBarcode;
  final String inputMode;
  final String? identifierStandard;
  final String? barcodeType;
  final String? invalidReason;
  final ResolveProductBarcodeLocalMatchDto? localMatch;
  final String? externalStatus;
  final ExternalProductSuggestionDto? externalSuggestion;
  final String? externalSourceReference;
  final bool externalRetryAllowed;
  final TenantCategoryResolutionDto? categoryResolution;
  final String? noBarcodeReason;
  final String noBarcodeProductName;
  final String? noBarcodeCategoryId;
  final bool autoGenerateSku;
  final String? generatedSkuCandidate;
  final bool isBusy;
  final String? lastError;
  final bool applyExternalPrefill;

  ScanBarcodeStepState copyWith({
    ScanBarcodePanel? panel,
    String? candidateBarcode,
    String? inputMode,
    String? identifierStandard,
    bool clearIdentifierStandard = false,
    String? barcodeType,
    bool clearBarcodeType = false,
    String? invalidReason,
    bool clearInvalidReason = false,
    ResolveProductBarcodeLocalMatchDto? localMatch,
    bool clearLocalMatch = false,
    String? externalStatus,
    bool clearExternalStatus = false,
    ExternalProductSuggestionDto? externalSuggestion,
    bool clearExternalSuggestion = false,
    String? externalSourceReference,
    bool clearExternalSourceReference = false,
    bool? externalRetryAllowed,
    TenantCategoryResolutionDto? categoryResolution,
    bool clearCategoryResolution = false,
    String? noBarcodeReason,
    bool clearNoBarcodeReason = false,
    String? noBarcodeProductName,
    String? noBarcodeCategoryId,
    bool clearNoBarcodeCategoryId = false,
    bool? autoGenerateSku,
    String? generatedSkuCandidate,
    bool clearGeneratedSkuCandidate = false,
    bool? isBusy,
    String? lastError,
    bool clearLastError = false,
    bool? applyExternalPrefill,
  }) {
    return ScanBarcodeStepState(
      panel: panel ?? this.panel,
      candidateBarcode: candidateBarcode ?? this.candidateBarcode,
      inputMode: inputMode ?? this.inputMode,
      identifierStandard: clearIdentifierStandard
          ? null
          : (identifierStandard ?? this.identifierStandard),
      barcodeType: clearBarcodeType ? null : (barcodeType ?? this.barcodeType),
      invalidReason:
          clearInvalidReason ? null : (invalidReason ?? this.invalidReason),
      localMatch: clearLocalMatch ? null : (localMatch ?? this.localMatch),
      externalStatus:
          clearExternalStatus ? null : (externalStatus ?? this.externalStatus),
      externalSuggestion: clearExternalSuggestion
          ? null
          : (externalSuggestion ?? this.externalSuggestion),
      externalSourceReference: clearExternalSourceReference
          ? null
          : (externalSourceReference ?? this.externalSourceReference),
      externalRetryAllowed: externalRetryAllowed ?? this.externalRetryAllowed,
      categoryResolution: clearCategoryResolution
          ? null
          : (categoryResolution ?? this.categoryResolution),
      noBarcodeReason: clearNoBarcodeReason
          ? null
          : (noBarcodeReason ?? this.noBarcodeReason),
      noBarcodeProductName: noBarcodeProductName ?? this.noBarcodeProductName,
      noBarcodeCategoryId: clearNoBarcodeCategoryId
          ? null
          : (noBarcodeCategoryId ?? this.noBarcodeCategoryId),
      autoGenerateSku: autoGenerateSku ?? this.autoGenerateSku,
      generatedSkuCandidate: clearGeneratedSkuCandidate
          ? null
          : (generatedSkuCandidate ?? this.generatedSkuCandidate),
      isBusy: isBusy ?? this.isBusy,
      lastError: clearLastError ? null : (lastError ?? this.lastError),
      applyExternalPrefill: applyExternalPrefill ?? this.applyExternalPrefill,
    );
  }
}
