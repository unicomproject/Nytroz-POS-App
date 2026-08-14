class OnlineStoreSetupStepDto {
  const OnlineStoreSetupStepDto({
    required this.stepNumber,
    required this.code,
    required this.label,
    required this.status,
    required this.blockingReasons,
  });

  factory OnlineStoreSetupStepDto.fromJson(Map<String, dynamic> json) {
    return OnlineStoreSetupStepDto(
      stepNumber: _int(json, 'stepNumber'),
      code: _string(json, 'code'),
      label: _string(json, 'label'),
      status: _string(json, 'status'),
      blockingReasons: _stringList(json['blockingReasons']),
    );
  }

  final int stepNumber;
  final String code;
  final String label;
  final String status;
  final List<String> blockingReasons;
}

class OnlineStoreReadinessDto {
  const OnlineStoreReadinessDto({
    required this.canPublish,
    required this.blockingReasons,
    required this.steps,
  });

  factory OnlineStoreReadinessDto.fromJson(Map<String, dynamic> json) {
    return OnlineStoreReadinessDto(
      canPublish: _bool(json, 'canPublish'),
      blockingReasons: _stringList(json['blockingReasons']),
      steps: _list(json['steps'], OnlineStoreSetupStepDto.fromJson),
    );
  }

  final bool canPublish;
  final List<String> blockingReasons;
  final List<OnlineStoreSetupStepDto> steps;
}

class OnlineStoreOverviewDto {
  const OnlineStoreOverviewDto({
    required this.salesChannelId,
    required this.storeStatus,
    required this.channelStatus,
    required this.setupEnabled,
    required this.visibility,
    required this.completedSteps,
    required this.totalSteps,
    required this.setupProgressPercent,
    required this.steps,
    required this.readiness,
    this.storeSlug,
    this.hostedUrl,
  });

  factory OnlineStoreOverviewDto.fromJson(Map<String, dynamic> json) {
    return OnlineStoreOverviewDto(
      salesChannelId: _string(json, 'salesChannelId'),
      storeStatus: _string(json, 'storeStatus'),
      channelStatus: _string(json, 'channelStatus'),
      setupEnabled: _bool(json, 'setupEnabled'),
      visibility: _string(json, 'visibility'),
      storeSlug: _nullableString(json, 'storeSlug'),
      hostedUrl: _nullableString(json, 'hostedUrl'),
      completedSteps: _int(json, 'completedSteps'),
      totalSteps: _int(json, 'totalSteps'),
      setupProgressPercent: _int(json, 'setupProgressPercent'),
      steps: _list(json['steps'], OnlineStoreSetupStepDto.fromJson),
      readiness: OnlineStoreReadinessDto.fromJson(_map(json['readiness'])),
    );
  }

  final String salesChannelId;
  final String storeStatus;
  final String channelStatus;
  final bool setupEnabled;
  final String visibility;
  final String? storeSlug;
  final String? hostedUrl;
  final int completedSteps;
  final int totalSteps;
  final int setupProgressPercent;
  final List<OnlineStoreSetupStepDto> steps;
  final OnlineStoreReadinessDto readiness;
}

class OnlineStoreEntitlementDto {
  const OnlineStoreEntitlementDto({
    required this.featureCode,
    required this.status,
  });

  factory OnlineStoreEntitlementDto.fromJson(Map<String, dynamic> json) {
    return OnlineStoreEntitlementDto(
      featureCode: _string(json, 'featureCode'),
      status: _string(json, 'status'),
    );
  }

  final String featureCode;
  final String status;
}

class OnlineStoreActivationDto {
  const OnlineStoreActivationDto({
    required this.setupEnabled,
    required this.storeStatus,
    required this.channelStatus,
    required this.visibility,
    required this.entitlements,
  });

  factory OnlineStoreActivationDto.fromJson(Map<String, dynamic> json) {
    return OnlineStoreActivationDto(
      setupEnabled: _bool(json, 'setupEnabled'),
      storeStatus: _string(json, 'storeStatus'),
      channelStatus: _string(json, 'channelStatus'),
      visibility: _string(json, 'visibility'),
      entitlements: _list(
        json['entitlements'],
        OnlineStoreEntitlementDto.fromJson,
      ),
    );
  }

  final bool setupEnabled;
  final String storeStatus;
  final String channelStatus;
  final String visibility;
  final List<OnlineStoreEntitlementDto> entitlements;
}

class OnlineStoreIdentityDto {
  const OnlineStoreIdentityDto({
    required this.salesChannelId,
    required this.storeName,
    required this.businessDisplayName,
    required this.currencyCode,
    required this.timezone,
    this.storeDescription,
    this.storeEmail,
    this.storePhone,
    this.supportTagline,
  });

  factory OnlineStoreIdentityDto.fromJson(Map<String, dynamic> json) {
    return OnlineStoreIdentityDto(
      salesChannelId: _string(json, 'salesChannelId'),
      storeName: _string(json, 'storeName'),
      businessDisplayName: _string(json, 'businessDisplayName'),
      storeDescription: _nullableString(json, 'storeDescription'),
      storeEmail: _nullableString(json, 'storeEmail'),
      storePhone: _nullableString(json, 'storePhone'),
      supportTagline: _nullableString(json, 'supportTagline'),
      currencyCode: _string(json, 'currencyCode'),
      timezone: _string(json, 'timezone'),
    );
  }

  final String salesChannelId;
  final String storeName;
  final String businessDisplayName;
  final String? storeDescription;
  final String? storeEmail;
  final String? storePhone;
  final String? supportTagline;
  final String currencyCode;
  final String timezone;
}

class OnlineStoreDomainDto {
  const OnlineStoreDomainDto({
    required this.id,
    required this.domainType,
    required this.domainName,
    required this.isPrimary,
    required this.verificationStatus,
    required this.sslStatus,
    required this.status,
    this.verifiedAt,
    this.sslIssuedAt,
    this.sslExpiresAt,
  });

  factory OnlineStoreDomainDto.fromJson(Map<String, dynamic> json) {
    return OnlineStoreDomainDto(
      id: _string(json, 'id'),
      domainType: _string(json, 'domainType'),
      domainName: _string(json, 'domainName'),
      isPrimary: _bool(json, 'isPrimary'),
      verificationStatus: _string(json, 'verificationStatus'),
      verifiedAt: _date(json, 'verifiedAt'),
      sslStatus: _string(json, 'sslStatus'),
      sslIssuedAt: _date(json, 'sslIssuedAt'),
      sslExpiresAt: _date(json, 'sslExpiresAt'),
      status: _string(json, 'status'),
    );
  }

  final String id;
  final String domainType;
  final String domainName;
  final bool isPrimary;
  final String verificationStatus;
  final DateTime? verifiedAt;
  final String sslStatus;
  final DateTime? sslIssuedAt;
  final DateTime? sslExpiresAt;
  final String status;
}

class OnlineStoreUrlDomainDto {
  const OnlineStoreUrlDomainDto({
    required this.domains,
    this.storeSlug,
    this.hostedUrl,
  });

  factory OnlineStoreUrlDomainDto.fromJson(Map<String, dynamic> json) {
    return OnlineStoreUrlDomainDto(
      storeSlug: _nullableString(json, 'storeSlug'),
      hostedUrl: _nullableString(json, 'hostedUrl'),
      domains: _list(json['domains'], OnlineStoreDomainDto.fromJson),
    );
  }

  final String? storeSlug;
  final String? hostedUrl;
  final List<OnlineStoreDomainDto> domains;
}

class OnlineStoreBrandingDto {
  const OnlineStoreBrandingDto({
    required this.primaryColor,
    required this.secondaryColor,
    required this.banners,
    this.logoMediaAssetId,
    this.faviconMediaAssetId,
  });

  factory OnlineStoreBrandingDto.fromJson(Map<String, dynamic> json) {
    return OnlineStoreBrandingDto(
      logoMediaAssetId: _nullableString(json, 'logoMediaAssetId'),
      faviconMediaAssetId: _nullableString(json, 'faviconMediaAssetId'),
      primaryColor: _string(json, 'primaryColor'),
      secondaryColor: _string(json, 'secondaryColor'),
      banners: _list(json['banners'], OnlineStoreBannerDto.fromJson),
    );
  }

  final String? logoMediaAssetId;
  final String? faviconMediaAssetId;
  final String primaryColor;
  final String secondaryColor;
  final List<OnlineStoreBannerDto> banners;
}

class OnlineStoreMediaDto {
  const OnlineStoreMediaDto({
    required this.mediaAssetId,
    required this.purpose,
    required this.fileName,
    required this.mimeType,
    required this.fileSizeBytes,
    this.publicUrl,
    this.widthPx,
    this.heightPx,
  });

  factory OnlineStoreMediaDto.fromJson(Map<String, dynamic> json) {
    return OnlineStoreMediaDto(
      mediaAssetId: _string(json, 'mediaAssetId'),
      purpose: _string(json, 'purpose'),
      publicUrl: _nullableString(json, 'publicUrl'),
      fileName: _string(json, 'fileName'),
      mimeType: _string(json, 'mimeType'),
      fileSizeBytes: _int(json, 'fileSizeBytes'),
      widthPx: _nullableInt(json, 'widthPx'),
      heightPx: _nullableInt(json, 'heightPx'),
    );
  }

  final String mediaAssetId;
  final String purpose;
  final String? publicUrl;
  final String fileName;
  final String mimeType;
  final int fileSizeBytes;
  final int? widthPx;
  final int? heightPx;
}

class OnlineStoreBannerDto {
  const OnlineStoreBannerDto({
    required this.id,
    required this.bannerType,
    required this.title,
    required this.sortOrder,
    required this.status,
    this.subtitle,
    this.imageMediaAssetId,
    this.imageUrl,
    this.actionText,
    this.actionUrl,
  });

  factory OnlineStoreBannerDto.fromJson(Map<String, dynamic> json) {
    return OnlineStoreBannerDto(
      id: _string(json, 'id'),
      bannerType: _string(json, 'bannerType'),
      title: _string(json, 'title'),
      subtitle: _nullableString(json, 'subtitle'),
      imageMediaAssetId: _nullableString(json, 'imageMediaAssetId'),
      imageUrl: _nullableString(json, 'imageUrl'),
      actionText: _nullableString(json, 'actionText'),
      actionUrl: _nullableString(json, 'actionUrl'),
      sortOrder: _int(json, 'sortOrder'),
      status: _string(json, 'status'),
    );
  }

  final String id;
  final String bannerType;
  final String title;
  final String? subtitle;
  final String? imageMediaAssetId;
  final String? imageUrl;
  final String? actionText;
  final String? actionUrl;
  final int sortOrder;
  final String status;
}

class OnlineStoreSupportDto {
  const OnlineStoreSupportDto({
    required this.contactUsEnabled,
    this.email,
    this.phone,
    this.whatsapp,
    this.helpUrl,
    this.supportHours,
    this.businessAddress,
  });

  factory OnlineStoreSupportDto.fromJson(Map<String, dynamic> json) {
    return OnlineStoreSupportDto(
      email: _nullableString(json, 'email'),
      phone: _nullableString(json, 'phone'),
      whatsapp: _nullableString(json, 'whatsapp'),
      helpUrl: _nullableString(json, 'helpUrl'),
      contactUsEnabled: _bool(json, 'contactUsEnabled'),
      supportHours: _nullableString(json, 'supportHours'),
      businessAddress: _nullableString(json, 'businessAddress'),
    );
  }

  final String? email;
  final String? phone;
  final String? whatsapp;
  final String? helpUrl;
  final bool contactUsEnabled;
  final String? supportHours;
  final String? businessAddress;
}

class OnlineStoreClickCollectDto {
  const OnlineStoreClickCollectDto({
    required this.enabled,
    required this.outletCount,
    required this.outlets,
  });

  factory OnlineStoreClickCollectDto.fromJson(Map<String, dynamic> json) {
    return OnlineStoreClickCollectDto(
      enabled: _bool(json, 'enabled'),
      outletCount: _int(json, 'outletCount'),
      outlets: _list(json['outlets'], OnlineStoreCollectionOutletDto.fromJson),
    );
  }

  final bool enabled;
  final int outletCount;
  final List<OnlineStoreCollectionOutletDto> outlets;
}

class OnlineStoreCollectionOutletDto {
  const OnlineStoreCollectionOutletDto({
    required this.outletId,
    required this.outletName,
    required this.outletStatus,
    required this.businessHoursConfigured,
    required this.status,
    this.preparationLeadMinutes,
    this.pickupWindowMinutes,
    this.cutoffTime,
  });

  factory OnlineStoreCollectionOutletDto.fromJson(Map<String, dynamic> json) {
    return OnlineStoreCollectionOutletDto(
      outletId: _string(json, 'outletId'),
      outletName: _string(json, 'outletName'),
      outletStatus: _string(json, 'outletStatus'),
      businessHoursConfigured: _bool(json, 'businessHoursConfigured'),
      preparationLeadMinutes: _nullableInt(json, 'preparationLeadMinutes'),
      pickupWindowMinutes: _nullableInt(json, 'pickupWindowMinutes'),
      cutoffTime: _nullableString(json, 'cutoffTime'),
      status: _string(json, 'status'),
    );
  }

  final String outletId;
  final String outletName;
  final String outletStatus;
  final bool businessHoursConfigured;
  final int? preparationLeadMinutes;
  final int? pickupWindowMinutes;
  final String? cutoffTime;
  final String status;
}

class OnlineStoreCatalogSummaryDto {
  const OnlineStoreCatalogSummaryDto({
    required this.totalProducts,
    required this.visibleOnline,
    required this.notVisible,
    required this.orderable,
    required this.lowStockProducts,
    required this.outOfStockProducts,
  });

  factory OnlineStoreCatalogSummaryDto.fromJson(Map<String, dynamic> json) {
    return OnlineStoreCatalogSummaryDto(
      totalProducts: _int(json, 'totalProducts'),
      visibleOnline: _int(json, 'visibleOnline'),
      notVisible: _int(json, 'notVisible'),
      orderable: _int(json, 'orderable'),
      lowStockProducts: _int(json, 'lowStockProducts'),
      outOfStockProducts: _int(json, 'outOfStockProducts'),
    );
  }

  final int totalProducts;
  final int visibleOnline;
  final int notVisible;
  final int orderable;
  final int lowStockProducts;
  final int outOfStockProducts;
}

class OnlineStoreCatalogProductListDto {
  const OnlineStoreCatalogProductListDto({
    required this.pageNumber,
    required this.pageSize,
    required this.totalCount,
    required this.items,
  });

  factory OnlineStoreCatalogProductListDto.fromJson(Map<String, dynamic> json) {
    return OnlineStoreCatalogProductListDto(
      pageNumber: _int(json, 'pageNumber'),
      pageSize: _int(json, 'pageSize'),
      totalCount: _int(json, 'totalCount'),
      items: _list(json['items'], OnlineStoreCatalogProductDto.fromJson),
    );
  }

  final int pageNumber;
  final int pageSize;
  final int totalCount;
  final List<OnlineStoreCatalogProductDto> items;
}

class OnlineStoreCatalogProductDto {
  const OnlineStoreCatalogProductDto({
    required this.productId,
    required this.productName,
    required this.isVisible,
    required this.isOrderable,
    required this.status,
    this.productVariantId,
    this.variantName,
    this.availableFrom,
    this.availableUntil,
  });

  factory OnlineStoreCatalogProductDto.fromJson(Map<String, dynamic> json) {
    return OnlineStoreCatalogProductDto(
      productId: _string(json, 'productId'),
      productVariantId: _nullableString(json, 'productVariantId'),
      productName: _string(json, 'productName'),
      variantName: _nullableString(json, 'variantName'),
      isVisible: _bool(json, 'isVisible'),
      isOrderable: _bool(json, 'isOrderable'),
      availableFrom: _date(json, 'availableFrom'),
      availableUntil: _date(json, 'availableUntil'),
      status: _string(json, 'status'),
    );
  }

  final String productId;
  final String? productVariantId;
  final String productName;
  final String? variantName;
  final bool isVisible;
  final bool isOrderable;
  final DateTime? availableFrom;
  final DateTime? availableUntil;
  final String status;
}

class OnlineStorePolicyDto {
  const OnlineStorePolicyDto({
    required this.id,
    required this.policyType,
    required this.title,
    required this.content,
    required this.version,
    required this.status,
    this.publishedAt,
  });

  factory OnlineStorePolicyDto.fromJson(Map<String, dynamic> json) {
    return OnlineStorePolicyDto(
      id: _string(json, 'id'),
      policyType: _string(json, 'policyType'),
      title: _string(json, 'title'),
      content: _string(json, 'content'),
      version: _string(json, 'version'),
      status: _string(json, 'status'),
      publishedAt: _date(json, 'publishedAt'),
    );
  }

  final String id;
  final String policyType;
  final String title;
  final String content;
  final String version;
  final String status;
  final DateTime? publishedAt;
}

class OnlineStorePublishDto {
  const OnlineStorePublishDto({
    required this.storeStatus,
    required this.channelStatus,
    required this.publishedAt,
    required this.readiness,
  });

  factory OnlineStorePublishDto.fromJson(Map<String, dynamic> json) {
    return OnlineStorePublishDto(
      storeStatus: _string(json, 'storeStatus'),
      channelStatus: _string(json, 'channelStatus'),
      publishedAt:
          _date(json, 'publishedAt') ?? DateTime.fromMillisecondsSinceEpoch(0),
      readiness: OnlineStoreReadinessDto.fromJson(_map(json['readiness'])),
    );
  }

  final String storeStatus;
  final String channelStatus;
  final DateTime publishedAt;
  final OnlineStoreReadinessDto readiness;
}

Map<String, dynamic> _map(dynamic value) {
  if (value is Map<String, dynamic>) {
    return value;
  }
  if (value is Map) {
    return Map<String, dynamic>.from(value);
  }
  return const {};
}

List<T> _list<T>(dynamic value, T Function(Map<String, dynamic>) map) {
  if (value is! List) {
    return const [];
  }
  return [
    for (final item in value)
      if (item is Map) map(Map<String, dynamic>.from(item)),
  ];
}

String _string(Map<String, dynamic> json, String key) =>
    json[key]?.toString() ?? '';

String? _nullableString(Map<String, dynamic> json, String key) {
  final value = json[key]?.toString().trim();
  return value == null || value.isEmpty ? null : value;
}

int _int(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

int? _nullableInt(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString());
}

bool _bool(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is bool) return value;
  return value?.toString().toLowerCase() == 'true';
}

DateTime? _date(Map<String, dynamic> json, String key) {
  return DateTime.tryParse(json[key]?.toString() ?? '');
}

List<String> _stringList(dynamic value) {
  if (value is! List) return const [];
  return value.map((item) => item.toString()).toList(growable: false);
}
