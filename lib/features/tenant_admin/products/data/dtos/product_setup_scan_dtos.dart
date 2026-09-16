/// Scanner-first Step 1 API DTOs — Tenant Admin Product Setup only.
/// Never call POS by-barcode from these clients.
library;

class ResolveProductBarcodeRequestDto {
  const ResolveProductBarcodeRequestDto({
    required this.barcode,
    this.inputMode = 'SCAN',
    this.reportedSymbology,
  });

  final String barcode;
  final String inputMode;
  final String? reportedSymbology;

  Map<String, dynamic> toJson() => {
        'barcode': barcode,
        'inputMode': inputMode,
        if (reportedSymbology != null && reportedSymbology!.trim().isNotEmpty)
          'reportedSymbology': reportedSymbology,
      };
}

class ResolveProductBarcodeLocalMatchDto {
  const ResolveProductBarcodeLocalMatchDto({
    required this.matchedAt,
    required this.productId,
    this.variantId,
    required this.productName,
    this.variantLabel,
    this.brand,
    this.category,
    this.sku,
    this.sellingPrice,
    this.currency,
    required this.status,
    this.imageUrl,
    required this.canViewProduct,
    required this.canEditProduct,
  });

  final String matchedAt;
  final String productId;
  final String? variantId;
  final String productName;
  final String? variantLabel;
  final String? brand;
  final String? category;
  final String? sku;
  final num? sellingPrice;
  final String? currency;
  final String status;
  final String? imageUrl;
  final bool canViewProduct;
  final bool canEditProduct;

  factory ResolveProductBarcodeLocalMatchDto.fromJson(
    Map<String, dynamic> json,
  ) {
    return ResolveProductBarcodeLocalMatchDto(
      matchedAt: json['matchedAt']?.toString() ?? 'PRODUCT',
      productId: json['productId']?.toString() ?? '',
      variantId: json['variantId']?.toString(),
      productName: json['productName']?.toString() ?? '',
      variantLabel: json['variantLabel']?.toString(),
      brand: json['brand']?.toString(),
      category: json['category']?.toString(),
      sku: json['sku']?.toString(),
      sellingPrice: json['sellingPrice'] as num?,
      currency: json['currency']?.toString(),
      status: json['status']?.toString() ?? '',
      imageUrl: json['imageUrl']?.toString(),
      canViewProduct: json['canViewProduct'] as bool? ?? false,
      canEditProduct: json['canEditProduct'] as bool? ?? false,
    );
  }
}

class ResolveProductBarcodeResponseDto {
  const ResolveProductBarcodeResponseDto({
    required this.outcome,
    this.normalizedBarcode,
    this.identifierStandard,
    this.barcodeType,
    this.invalidReason,
    this.localMatch,
  });

  final String outcome;
  final String? normalizedBarcode;
  final String? identifierStandard;
  final String? barcodeType;
  final String? invalidReason;
  final ResolveProductBarcodeLocalMatchDto? localMatch;

  bool get isValidLocalMatch => outcome == 'VALID_LOCAL_MATCH';
  bool get isValidNoLocalMatch => outcome == 'VALID_NO_LOCAL_MATCH';
  bool get isInvalid => outcome == 'INVALID';

  factory ResolveProductBarcodeResponseDto.fromJson(Map<String, dynamic> json) {
    final match = json['localMatch'];
    return ResolveProductBarcodeResponseDto(
      outcome: json['outcome']?.toString() ?? 'INVALID',
      normalizedBarcode: json['normalizedBarcode']?.toString(),
      identifierStandard: json['identifierStandard']?.toString(),
      barcodeType: json['barcodeType']?.toString(),
      invalidReason: json['invalidReason']?.toString(),
      localMatch: match is Map<String, dynamic>
          ? ResolveProductBarcodeLocalMatchDto.fromJson(match)
          : null,
    );
  }
}

class ExternalProductSuggestionDto {
  const ExternalProductSuggestionDto({
    this.productName,
    this.shortName,
    this.brandText,
    this.categoryText,
    this.unitText,
    this.countryCode,
    this.shortDescription,
    this.longDescription,
    this.imageCandidate,
    this.primaryGtin,
    this.identifierStandard,
  });

  final String? productName;
  final String? shortName;
  final String? brandText;
  final String? categoryText;
  final String? unitText;
  final String? countryCode;
  final String? shortDescription;
  final String? longDescription;
  final String? imageCandidate;
  final String? primaryGtin;
  final String? identifierStandard;

  factory ExternalProductSuggestionDto.fromJson(Map<String, dynamic> json) {
    return ExternalProductSuggestionDto(
      productName: json['productName']?.toString(),
      shortName: json['shortName']?.toString(),
      brandText: json['brandText']?.toString(),
      categoryText: json['categoryText']?.toString(),
      unitText: json['unitText']?.toString(),
      countryCode: json['countryCode']?.toString(),
      shortDescription: json['shortDescription']?.toString(),
      longDescription: json['longDescription']?.toString(),
      imageCandidate: json['imageCandidate']?.toString(),
      primaryGtin: json['primaryGtin']?.toString(),
      identifierStandard: json['identifierStandard']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        if (productName != null) 'productName': productName,
        if (shortName != null) 'shortName': shortName,
        if (brandText != null) 'brandText': brandText,
        if (categoryText != null) 'categoryText': categoryText,
        if (unitText != null) 'unitText': unitText,
        if (countryCode != null) 'countryCode': countryCode,
        if (shortDescription != null) 'shortDescription': shortDescription,
        if (longDescription != null) 'longDescription': longDescription,
        if (imageCandidate != null) 'imageCandidate': imageCandidate,
        if (primaryGtin != null) 'primaryGtin': primaryGtin,
        if (identifierStandard != null) 'identifierStandard': identifierStandard,
      };
}

class ExternalLookupProductBarcodeResponseDto {
  const ExternalLookupProductBarcodeResponseDto({
    required this.status,
    this.suggestion,
    this.sourceReference,
    required this.retryAllowed,
  });

  final String status;
  final ExternalProductSuggestionDto? suggestion;
  final String? sourceReference;
  final bool retryAllowed;

  bool get isFound => status == 'FOUND';
  bool get isNoMatch => status == 'NO_MATCH';
  bool get isTemporaryFailure => status == 'TEMPORARY_FAILURE';

  factory ExternalLookupProductBarcodeResponseDto.fromJson(
    Map<String, dynamic> json,
  ) {
    final suggestion = json['suggestion'];
    return ExternalLookupProductBarcodeResponseDto(
      status: json['status']?.toString() ?? 'NO_MATCH',
      suggestion: suggestion is Map<String, dynamic>
          ? ExternalProductSuggestionDto.fromJson(suggestion)
          : null,
      sourceReference: json['sourceReference']?.toString(),
      retryAllowed: json['retryAllowed'] as bool? ?? false,
    );
  }
}

class SkuCandidateResponseDto {
  const SkuCandidateResponseDto({
    required this.candidate,
    required this.reserved,
  });

  final String candidate;
  final bool reserved;

  factory SkuCandidateResponseDto.fromJson(Map<String, dynamic> json) {
    return SkuCandidateResponseDto(
      candidate: json['candidate']?.toString() ?? '',
      reserved: json['reserved'] as bool? ?? false,
    );
  }
}

class ProductSetupScanBootstrapRequestDto {
  const ProductSetupScanBootstrapRequestDto({
    required this.acquisitionMode,
    required this.creationAction,
    this.candidateIdentifier,
    this.identifierStandard,
    this.symbologyHint,
    this.noBarcodeReason,
    this.externalLookupStatus,
    this.externalSourceReference,
    this.normalizedPrefill,
    this.generatedSkuCandidate,
  });

  final String acquisitionMode;
  final String creationAction;
  final String? candidateIdentifier;
  final String? identifierStandard;
  final String? symbologyHint;
  final String? noBarcodeReason;
  final String? externalLookupStatus;
  final String? externalSourceReference;
  final ExternalProductSuggestionDto? normalizedPrefill;
  final String? generatedSkuCandidate;

  Map<String, dynamic> toJson() => {
        'acquisitionMode': acquisitionMode,
        'creationAction': creationAction,
        if (candidateIdentifier != null) 'candidateIdentifier': candidateIdentifier,
        if (identifierStandard != null) 'identifierStandard': identifierStandard,
        if (symbologyHint != null) 'symbologyHint': symbologyHint,
        if (noBarcodeReason != null) 'noBarcodeReason': noBarcodeReason,
        if (externalLookupStatus != null)
          'externalLookupStatus': externalLookupStatus,
        if (externalSourceReference != null)
          'externalSourceReference': externalSourceReference,
        if (normalizedPrefill != null)
          'normalizedPrefill': normalizedPrefill!.toJson(),
        if (generatedSkuCandidate != null)
          'generatedSkuCandidate': generatedSkuCandidate,
      };
}

class ProductSetupScanContextDto {
  const ProductSetupScanContextDto({
    required this.acquisitionMode,
    this.candidateIdentifier,
    this.identifierStandard,
    this.symbologyHint,
    this.noBarcodeReason,
    this.externalLookupStatus,
    this.externalSourceReference,
    this.normalizedPrefill,
    this.generatedSkuCandidate,
  });

  final String acquisitionMode;
  final String? candidateIdentifier;
  final String? identifierStandard;
  final String? symbologyHint;
  final String? noBarcodeReason;
  final String? externalLookupStatus;
  final String? externalSourceReference;
  final ExternalProductSuggestionDto? normalizedPrefill;
  final String? generatedSkuCandidate;

  factory ProductSetupScanContextDto.fromJson(Map<String, dynamic> json) {
    final prefill = json['normalizedPrefill'];
    return ProductSetupScanContextDto(
      acquisitionMode: json['acquisitionMode']?.toString() ?? 'LEGACY',
      candidateIdentifier: json['candidateIdentifier']?.toString(),
      identifierStandard: json['identifierStandard']?.toString(),
      symbologyHint: json['symbologyHint']?.toString(),
      noBarcodeReason: json['noBarcodeReason']?.toString(),
      externalLookupStatus: json['externalLookupStatus']?.toString(),
      externalSourceReference: json['externalSourceReference']?.toString(),
      normalizedPrefill: prefill is Map<String, dynamic>
          ? ExternalProductSuggestionDto.fromJson(prefill)
          : null,
      generatedSkuCandidate: json['generatedSkuCandidate']?.toString(),
    );
  }
}
