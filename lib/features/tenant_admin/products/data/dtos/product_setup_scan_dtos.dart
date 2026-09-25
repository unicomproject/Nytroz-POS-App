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
    this.externalCategoryKey,
    this.externalCategoryName,
    this.externalCategoryHierarchy,
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
  final String? externalCategoryKey;
  final String? externalCategoryName;
  final List<String>? externalCategoryHierarchy;

  factory ExternalProductSuggestionDto.fromJson(Map<String, dynamic> json) {
    final hierarchyRaw = json['externalCategoryHierarchy'];
    List<String>? hierarchy;
    if (hierarchyRaw is List) {
      hierarchy = hierarchyRaw.map((e) => e.toString()).toList();
    }

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
      externalCategoryKey: json['externalCategoryKey']?.toString(),
      externalCategoryName: json['externalCategoryName']?.toString(),
      externalCategoryHierarchy: hierarchy,
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
        if (identifierStandard != null)
          'identifierStandard': identifierStandard,
        if (externalCategoryKey != null)
          'externalCategoryKey': externalCategoryKey,
        if (externalCategoryName != null)
          'externalCategoryName': externalCategoryName,
        if (externalCategoryHierarchy != null)
          'externalCategoryHierarchy': externalCategoryHierarchy,
      };
}

class TenantCategoryCandidateDto {
  const TenantCategoryCandidateDto({
    required this.id,
    required this.name,
    required this.code,
    this.matchType,
  });

  final String id;
  final String name;
  final String code;
  final String? matchType;

  factory TenantCategoryCandidateDto.fromJson(Map<String, dynamic> json) {
    return TenantCategoryCandidateDto(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      code: json['code']?.toString() ?? '',
      matchType: json['matchType']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'code': code,
        if (matchType != null) 'matchType': matchType,
      };
}

class TenantCategoryResolutionDto {
  const TenantCategoryResolutionDto({
    required this.provider,
    this.externalCategoryKey,
    this.externalCategoryName,
    this.mappedCategory,
    this.suggestions = const [],
  });

  final String provider;
  final String? externalCategoryKey;
  final String? externalCategoryName;
  final TenantCategoryCandidateDto? mappedCategory;
  final List<TenantCategoryCandidateDto> suggestions;

  factory TenantCategoryResolutionDto.fromJson(Map<String, dynamic> json) {
    final mapped = json['mappedCategory'];
    final suggestionsRaw = json['suggestions'];
    final suggestions = <TenantCategoryCandidateDto>[];
    if (suggestionsRaw is List) {
      for (final item in suggestionsRaw) {
        if (item is Map<String, dynamic>) {
          suggestions.add(TenantCategoryCandidateDto.fromJson(item));
        }
      }
    }

    return TenantCategoryResolutionDto(
      provider: json['provider']?.toString() ?? '',
      externalCategoryKey: json['externalCategoryKey']?.toString(),
      externalCategoryName: json['externalCategoryName']?.toString(),
      mappedCategory: mapped is Map<String, dynamic>
          ? TenantCategoryCandidateDto.fromJson(mapped)
          : null,
      suggestions: suggestions,
    );
  }

  Map<String, dynamic> toJson() => {
        'provider': provider,
        if (externalCategoryKey != null)
          'externalCategoryKey': externalCategoryKey,
        if (externalCategoryName != null)
          'externalCategoryName': externalCategoryName,
        if (mappedCategory != null)
          'mappedCategory': mappedCategory!.toJson(),
        'suggestions': suggestions.map((s) => s.toJson()).toList(),
      };
}

class TenantBrandCandidateDto {
  const TenantBrandCandidateDto({
    required this.id,
    required this.name,
    required this.code,
    this.matchType,
  });

  final String id;
  final String name;
  final String code;
  final String? matchType;

  factory TenantBrandCandidateDto.fromJson(Map<String, dynamic> json) {
    return TenantBrandCandidateDto(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      code: json['code']?.toString() ?? '',
      matchType: json['matchType']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'code': code,
        if (matchType != null) 'matchType': matchType,
      };
}

class TenantBrandResolutionDto {
  const TenantBrandResolutionDto({
    required this.provider,
    this.externalBrandKey,
    this.externalBrandName,
    this.mappedBrand,
    this.suggestions = const [],
  });

  final String provider;
  final String? externalBrandKey;
  final String? externalBrandName;
  final TenantBrandCandidateDto? mappedBrand;
  final List<TenantBrandCandidateDto> suggestions;

  factory TenantBrandResolutionDto.fromJson(Map<String, dynamic> json) {
    final mapped = json['mappedBrand'];
    final suggestionsRaw = json['suggestions'];
    final suggestions = <TenantBrandCandidateDto>[];
    if (suggestionsRaw is List) {
      for (final item in suggestionsRaw) {
        if (item is Map<String, dynamic>) {
          suggestions.add(TenantBrandCandidateDto.fromJson(item));
        }
      }
    }

    return TenantBrandResolutionDto(
      provider: json['provider']?.toString() ?? '',
      externalBrandKey: json['externalBrandKey']?.toString(),
      externalBrandName: json['externalBrandName']?.toString(),
      mappedBrand: mapped is Map<String, dynamic>
          ? TenantBrandCandidateDto.fromJson(mapped)
          : null,
      suggestions: suggestions,
    );
  }

  Map<String, dynamic> toJson() => {
        'provider': provider,
        if (externalBrandKey != null) 'externalBrandKey': externalBrandKey,
        if (externalBrandName != null) 'externalBrandName': externalBrandName,
        if (mappedBrand != null) 'mappedBrand': mappedBrand!.toJson(),
        'suggestions': suggestions.map((s) => s.toJson()).toList(),
      };
}

class ExternalLookupProductBarcodeResponseDto {
  const ExternalLookupProductBarcodeResponseDto({
    required this.status,
    this.suggestion,
    this.sourceReference,
    required this.retryAllowed,
    this.categoryResolution,
    this.brandResolution,
  });

  final String status;
  final ExternalProductSuggestionDto? suggestion;
  final String? sourceReference;
  final bool retryAllowed;
  final TenantCategoryResolutionDto? categoryResolution;
  final TenantBrandResolutionDto? brandResolution;

  bool get isFound => status == 'FOUND';
  bool get isNoMatch => status == 'NO_MATCH';
  bool get isTemporaryFailure => status == 'TEMPORARY_FAILURE';

  factory ExternalLookupProductBarcodeResponseDto.fromJson(
    Map<String, dynamic> json,
  ) {
    final suggestion = json['suggestion'];
    final resolution = json['categoryResolution'];
    final brandResolution = json['brandResolution'];
    return ExternalLookupProductBarcodeResponseDto(
      status: json['status']?.toString() ?? 'NO_MATCH',
      suggestion: suggestion is Map<String, dynamic>
          ? ExternalProductSuggestionDto.fromJson(suggestion)
          : null,
      sourceReference: json['sourceReference']?.toString(),
      retryAllowed: json['retryAllowed'] as bool? ?? false,
      categoryResolution: resolution is Map<String, dynamic>
          ? TenantCategoryResolutionDto.fromJson(resolution)
          : null,
      brandResolution: brandResolution is Map<String, dynamic>
          ? TenantBrandResolutionDto.fromJson(brandResolution)
          : null,
    );
  }
}

class GenerateSkuCandidateRequestDto {
  const GenerateSkuCandidateRequestDto({
    required this.purpose,
    required this.categoryId,
    required this.mode,
    this.productId,
    this.expectedRowVersion,
    this.productName,
  });

  final String purpose;
  final String categoryId;
  final String mode;
  final String? productId;
  final int? expectedRowVersion;
  final String? productName;

  Map<String, dynamic> toJson() => {
        'purpose': purpose,
        'categoryId': categoryId,
        'mode': mode,
        if (productId != null) 'productId': productId,
        if (expectedRowVersion != null)
          'expectedRowVersion': expectedRowVersion,
        if (productName != null) 'productName': productName,
      };
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
        if (candidateIdentifier != null)
          'candidateIdentifier': candidateIdentifier,
        if (identifierStandard != null)
          'identifierStandard': identifierStandard,
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
