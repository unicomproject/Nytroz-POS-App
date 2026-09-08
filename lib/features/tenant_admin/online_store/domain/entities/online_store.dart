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
    this.domain = const OnlineStoreDomainSummary(),
    this.branding = const OnlineStoreSectionSummary(),
    this.contactSupport = const OnlineStoreSectionSummary(),
    this.clickCollect = const OnlineStoreClickCollectSummary(),
    this.catalog = const OnlineStoreCatalogOverview(),
    this.policies = const OnlineStorePolicySummary(),
    this.customerAccountMode = 'REGISTRATION_REQUIRED',
    this.emailVerificationRequired = true,
    this.paymentMode = 'PAY_AT_PICKUP',
    this.notificationsStatus = 'NOT_READY',
    this.nextActions = const [],
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
  final OnlineStoreDomainSummary domain;
  final OnlineStoreSectionSummary branding;
  final OnlineStoreSectionSummary contactSupport;
  final OnlineStoreClickCollectSummary clickCollect;
  final OnlineStoreCatalogOverview catalog;
  final OnlineStorePolicySummary policies;
  final String customerAccountMode;
  final bool emailVerificationRequired;
  final String paymentMode;
  final String notificationsStatus;
  final List<OnlineStoreNextAction> nextActions;
}

class OnlineStoreDomainSummary {
  const OnlineStoreDomainSummary({
    this.configured = false,
    this.domain,
    this.dnsStatus,
    this.sslStatus,
    this.isPrimary = false,
  });

  final bool configured;
  final String? domain;
  final String? dnsStatus;
  final String? sslStatus;
  final bool isPrimary;
}

class OnlineStoreSectionSummary {
  const OnlineStoreSectionSummary({this.status = 'INCOMPLETE'});

  final String status;
}

class OnlineStoreClickCollectSummary {
  const OnlineStoreClickCollectSummary({
    this.enabled = false,
    this.eligibleOutletCount = 0,
    this.status = 'INCOMPLETE',
  });

  final bool enabled;
  final int eligibleOutletCount;
  final String status;
}

class OnlineStoreCatalogOverview {
  const OnlineStoreCatalogOverview({
    this.totalProducts = 0,
    this.onlineVisibleProducts = 0,
  });

  final int totalProducts;
  final int onlineVisibleProducts;
}

class OnlineStorePolicySummary {
  const OnlineStorePolicySummary({
    this.requiredCount = 0,
    this.publishedRequiredCount = 0,
    this.status = 'INCOMPLETE',
  });

  final int requiredCount;
  final int publishedRequiredCount;
  final String status;
}

class OnlineStoreNextAction {
  const OnlineStoreNextAction({
    required this.code,
    required this.step,
    required this.blocking,
  });

  final String code;
  final int step;
  final bool blocking;
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
    this.releaseScope = 'CLICK_COLLECT_ONLY',
    this.checkoutMode = 'REGISTRATION_REQUIRED',
    this.emailVerificationRequired = true,
    this.paymentMode = 'PAY_AT_PICKUP',
    this.notificationsStatus = 'NOT_READY',
    this.privateUntilPublished = true,
    this.readiness = const [],
  });

  final bool setupEnabled;
  final String storeStatus;
  final String channelStatus;
  final String visibility;
  final List<OnlineStoreEntitlement> entitlements;
  final String releaseScope;
  final String checkoutMode;
  final bool emailVerificationRequired;
  final String paymentMode;
  final String notificationsStatus;
  final bool privateUntilPublished;
  final List<OnlineStoreActivationReadinessItem> readiness;
}

class OnlineStoreActivationReadinessItem {
  const OnlineStoreActivationReadinessItem({
    required this.code,
    required this.label,
    required this.status,
    required this.message,
  });

  final String code;
  final String label;
  final String status;
  final String message;
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

class OnlineStoreCheckoutRules {
  const OnlineStoreCheckoutRules({
    required this.release,
    required this.customerAccount,
    required this.guestCheckout,
    required this.emailVerification,
    required this.fulfilment,
    required this.payment,
  });

  final String release;
  final OnlineStoreCustomerAccountRule customerAccount;
  final OnlineStoreGuestCheckoutRule guestCheckout;
  final OnlineStoreEmailVerificationRule emailVerification;
  final OnlineStoreFulfilmentRule fulfilment;
  final OnlineStorePaymentRule payment;
}

class OnlineStoreCustomerAccountRule {
  const OnlineStoreCustomerAccountRule({
    required this.registrationRequired,
    required this.mode,
    required this.label,
  });

  final bool registrationRequired;
  final String mode;
  final String label;
}

class OnlineStoreGuestCheckoutRule {
  const OnlineStoreGuestCheckoutRule({
    required this.available,
    required this.mode,
    required this.label,
  });

  final bool available;
  final String mode;
  final String label;
}

class OnlineStoreEmailVerificationRule {
  const OnlineStoreEmailVerificationRule({
    required this.required,
    required this.mode,
    required this.label,
  });

  final bool required;
  final String mode;
  final String label;
}

class OnlineStoreFulfilmentRule {
  const OnlineStoreFulfilmentRule({
    required this.mode,
    required this.label,
    required this.featureEnabled,
    required this.configured,
  });

  final String mode;
  final String label;
  final bool featureEnabled;
  final bool configured;
}

class OnlineStorePaymentRule {
  const OnlineStorePaymentRule({
    required this.mode,
    required this.label,
  });

  final String mode;
  final String label;
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

class OnlineStoreDomainToken {
  const OnlineStoreDomainToken({
    required this.domainId,
    required this.domainName,
    required this.verificationToken,
  });

  final String domainId;
  final String domainName;
  final String verificationToken;
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
    this.logoImageUrl,
    this.faviconImageUrl,
  });

  final String? logoMediaAssetId;
  final String? faviconMediaAssetId;
  final String? logoImageUrl;
  final String? faviconImageUrl;
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
