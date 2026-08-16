class OnlineStoreStep {
  const OnlineStoreStep({
    required this.stepNumber,
    required this.code,
    required this.label,
    required this.status,
    required this.blockingReasons,
  });

  final int stepNumber;
  final String code;
  final String label;
  final String status;
  final List<String> blockingReasons;
}

class OnlineStoreReadiness {
  const OnlineStoreReadiness({
    required this.canPublish,
    required this.blockingReasons,
    required this.steps,
  });

  final bool canPublish;
  final List<String> blockingReasons;
  final List<OnlineStoreStep> steps;
}

class OnlineStoreOverview {
  const OnlineStoreOverview({
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
  final List<OnlineStoreStep> steps;
  final OnlineStoreReadiness readiness;
}

class OnlineStoreEntitlement {
  const OnlineStoreEntitlement({
    required this.featureCode,
    required this.status,
  });

  final String featureCode;
  final String status;
}

class OnlineStoreActivation {
  const OnlineStoreActivation({
    required this.setupEnabled,
    required this.storeStatus,
    required this.channelStatus,
    required this.visibility,
    required this.entitlements,
  });

  final bool setupEnabled;
  final String storeStatus;
  final String channelStatus;
  final String visibility;
  final List<OnlineStoreEntitlement> entitlements;
}

class OnlineStoreIdentity {
  const OnlineStoreIdentity({
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

class OnlineStoreDomain {
  const OnlineStoreDomain({
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

class OnlineStoreUrlDomain {
  const OnlineStoreUrlDomain({
    required this.domains,
    this.storeSlug,
    this.hostedUrl,
  });

  final String? storeSlug;
  final String? hostedUrl;
  final List<OnlineStoreDomain> domains;
}

class OnlineStoreBranding {
  const OnlineStoreBranding({
    required this.primaryColor,
    required this.secondaryColor,
    required this.banners,
    this.logoMediaAssetId,
    this.faviconMediaAssetId,
  });

  final String? logoMediaAssetId;
  final String? faviconMediaAssetId;
  final String primaryColor;
  final String secondaryColor;
  final List<OnlineStoreBanner> banners;
}

class OnlineStoreMedia {
  const OnlineStoreMedia({
    required this.mediaAssetId,
    required this.purpose,
    required this.fileName,
    required this.mimeType,
    required this.fileSizeBytes,
    this.publicUrl,
    this.widthPx,
    this.heightPx,
  });

  final String mediaAssetId;
  final String purpose;
  final String? publicUrl;
  final String fileName;
  final String mimeType;
  final int fileSizeBytes;
  final int? widthPx;
  final int? heightPx;
}

class OnlineStoreBanner {
  const OnlineStoreBanner({
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

class OnlineStoreSupport {
  const OnlineStoreSupport({
    required this.contactUsEnabled,
    this.email,
    this.phone,
    this.whatsapp,
    this.helpUrl,
    this.supportHours,
    this.businessAddress,
  });

  final String? email;
  final String? phone;
  final String? whatsapp;
  final String? helpUrl;
  final bool contactUsEnabled;
  final String? supportHours;
  final String? businessAddress;
}

class OnlineStoreClickCollect {
  const OnlineStoreClickCollect({
    required this.enabled,
    required this.outletCount,
    required this.outlets,
  });

  final bool enabled;
  final int outletCount;
  final List<OnlineStoreCollectionOutlet> outlets;
}

class OnlineStoreCollectionOutlet {
  const OnlineStoreCollectionOutlet({
    required this.outletId,
    required this.outletName,
    required this.outletStatus,
    required this.businessHoursConfigured,
    required this.status,
    this.preparationLeadMinutes,
    this.pickupWindowMinutes,
    this.cutoffTime,
  });

  final String outletId;
  final String outletName;
  final String outletStatus;
  final bool businessHoursConfigured;
  final int? preparationLeadMinutes;
  final int? pickupWindowMinutes;
  final String? cutoffTime;
  final String status;
}

class OnlineStoreCatalogSummary {
  const OnlineStoreCatalogSummary({
    required this.totalProducts,
    required this.visibleOnline,
    required this.notVisible,
    required this.orderable,
    required this.lowStockProducts,
    required this.outOfStockProducts,
  });

  final int totalProducts;
  final int visibleOnline;
  final int notVisible;
  final int orderable;
  final int lowStockProducts;
  final int outOfStockProducts;
}

class OnlineStoreCatalogProductList {
  const OnlineStoreCatalogProductList({
    required this.pageNumber,
    required this.pageSize,
    required this.totalCount,
    required this.items,
  });

  final int pageNumber;
  final int pageSize;
  final int totalCount;
  final List<OnlineStoreCatalogProduct> items;
}

class OnlineStoreCatalogProduct {
  const OnlineStoreCatalogProduct({
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

class OnlineStorePolicy {
  const OnlineStorePolicy({
    required this.id,
    required this.policyType,
    required this.title,
    required this.content,
    required this.version,
    required this.status,
    this.publishedAt,
  });

  final String id;
  final String policyType;
  final String title;
  final String content;
  final String version;
  final String status;
  final DateTime? publishedAt;
}

class OnlineStorePublishResult {
  const OnlineStorePublishResult({
    required this.storeStatus,
    required this.channelStatus,
    required this.publishedAt,
    required this.readiness,
  });

  final String storeStatus;
  final String channelStatus;
  final DateTime publishedAt;
  final OnlineStoreReadiness readiness;
}
