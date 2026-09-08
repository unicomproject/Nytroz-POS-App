import '../../domain/entities/online_store.dart';
import '../models/online_store_dtos.dart';

extension OnlineStoreStepMapper on OnlineStoreSetupStepDto {
  OnlineStoreStep toEntity() => OnlineStoreStep(
        stepNumber: stepNumber,
        code: code,
        label: label,
        status: status,
        blockingReasons: blockingReasons,
      );
}

extension OnlineStoreReadinessMapper on OnlineStoreReadinessDto {
  OnlineStoreReadiness toEntity() => OnlineStoreReadiness(
        canPublish: canPublish,
        blockingReasons: blockingReasons,
        steps: steps.map((step) => step.toEntity()).toList(growable: false),
      );
}

extension OnlineStoreOverviewMapper on OnlineStoreOverviewDto {
  OnlineStoreOverview toEntity() => OnlineStoreOverview(
        salesChannelId: salesChannelId,
        storeStatus: storeStatus,
        channelStatus: channelStatus,
        setupEnabled: setupEnabled,
        visibility: visibility,
        storeSlug: storeSlug,
        hostedUrl: hostedUrl,
        completedSteps: completedSteps,
        totalSteps: totalSteps,
        setupProgressPercent: setupProgressPercent,
        steps: steps.map((step) => step.toEntity()).toList(growable: false),
        readiness: readiness.toEntity(),
        domain: OnlineStoreDomainSummary(
          configured: domain.configured,
          domain: domain.domain,
          dnsStatus: domain.dnsStatus,
          sslStatus: domain.sslStatus,
          isPrimary: domain.isPrimary,
        ),
        branding: OnlineStoreSectionSummary(status: branding.status),
        contactSupport:
            OnlineStoreSectionSummary(status: contactSupport.status),
        clickCollect: OnlineStoreClickCollectSummary(
          enabled: clickCollect.enabled,
          eligibleOutletCount: clickCollect.eligibleOutletCount,
          status: clickCollect.status,
        ),
        catalog: OnlineStoreCatalogOverview(
          totalProducts: catalog.totalProducts,
          onlineVisibleProducts: catalog.onlineVisibleProducts,
        ),
        policies: OnlineStorePolicySummary(
          requiredCount: policies.requiredCount,
          publishedRequiredCount: policies.publishedRequiredCount,
          status: policies.status,
        ),
        customerAccountMode: customerAccountMode,
        emailVerificationRequired: emailVerificationRequired,
        paymentMode: paymentMode,
        notificationsStatus: notificationsStatus,
        nextActions: nextActions
            .map(
              (item) => OnlineStoreNextAction(
                code: item.code,
                step: item.step,
                blocking: item.blocking,
              ),
            )
            .toList(growable: false),
      );
}

extension OnlineStoreActivationMapper on OnlineStoreActivationDto {
  OnlineStoreActivation toEntity() => OnlineStoreActivation(
        setupEnabled: setupEnabled,
        storeStatus: storeStatus,
        channelStatus: channelStatus,
        visibility: visibility,
        releaseScope: releaseScope,
        checkoutMode: checkoutMode,
        emailVerificationRequired: emailVerificationRequired,
        paymentMode: paymentMode,
        notificationsStatus: notificationsStatus,
        privateUntilPublished: privateUntilPublished,
        entitlements: entitlements
            .map(
              (item) => OnlineStoreEntitlement(
                featureCode: item.featureCode,
                status: item.status,
              ),
            )
            .toList(growable: false),
        readiness: readiness
            .map(
              (item) => OnlineStoreActivationReadinessItem(
                code: item.code,
                label: item.label,
                status: item.status,
                message: item.message,
              ),
            )
            .toList(growable: false),
      );
}

extension OnlineStoreIdentityMapper on OnlineStoreIdentityDto {
  OnlineStoreIdentity toEntity() => OnlineStoreIdentity(
        salesChannelId: salesChannelId,
        storeName: storeName,
        businessDisplayName: businessDisplayName,
        storeDescription: storeDescription,
        storeEmail: storeEmail,
        storePhone: storePhone,
        supportTagline: supportTagline,
        currencyCode: currencyCode,
        timezone: timezone,
      );
}

extension OnlineStoreCheckoutRulesMapper on OnlineStoreCheckoutRulesDto {
  OnlineStoreCheckoutRules toEntity() => OnlineStoreCheckoutRules(
        release: release,
        customerAccount: OnlineStoreCustomerAccountRule(
          registrationRequired: customerAccount.registrationRequired,
          mode: customerAccount.mode,
          label: customerAccount.label,
        ),
        guestCheckout: OnlineStoreGuestCheckoutRule(
          available: guestCheckout.available,
          mode: guestCheckout.mode,
          label: guestCheckout.label,
        ),
        emailVerification: OnlineStoreEmailVerificationRule(
          required: emailVerification.required,
          mode: emailVerification.mode,
          label: emailVerification.label,
        ),
        fulfilment: OnlineStoreFulfilmentRule(
          mode: fulfilment.mode,
          label: fulfilment.label,
          featureEnabled: fulfilment.featureEnabled,
          configured: fulfilment.configured,
        ),
        payment: OnlineStorePaymentRule(
          mode: payment.mode,
          label: payment.label,
        ),
      );
}

extension OnlineStoreUrlDomainMapper on OnlineStoreUrlDomainDto {
  OnlineStoreUrlDomain toEntity() => OnlineStoreUrlDomain(
        storeSlug: storeSlug,
        hostedUrl: hostedUrl,
        domains: domains.map((item) => item.toEntity()).toList(growable: false),
      );
}

extension OnlineStoreDomainMapper on OnlineStoreDomainDto {
  OnlineStoreDomain toEntity() => OnlineStoreDomain(
        id: id,
        domainType: domainType,
        domainName: domainName,
        isPrimary: isPrimary,
        verificationStatus: verificationStatus,
        verifiedAt: verifiedAt,
        sslStatus: sslStatus,
        sslIssuedAt: sslIssuedAt,
        sslExpiresAt: sslExpiresAt,
        status: status,
      );
}

extension OnlineStoreDomainTokenMapper on OnlineStoreDomainTokenDto {
  OnlineStoreDomainToken toEntity() => OnlineStoreDomainToken(
        domainId: domainId,
        domainName: domainName,
        verificationToken: verificationToken,
      );
}

extension OnlineStoreBrandingMapper on OnlineStoreBrandingDto {
  OnlineStoreBranding toEntity() => OnlineStoreBranding(
        logoMediaAssetId: logoMediaAssetId,
        faviconMediaAssetId: faviconMediaAssetId,
        logoImageUrl: logoImageUrl,
        faviconImageUrl: faviconImageUrl,
        primaryColor: primaryColor,
        secondaryColor: secondaryColor,
        banners: banners.map((item) => item.toEntity()).toList(growable: false),
      );
}

extension OnlineStoreMediaMapper on OnlineStoreMediaDto {
  OnlineStoreMedia toEntity() => OnlineStoreMedia(
        mediaAssetId: mediaAssetId,
        purpose: purpose,
        publicUrl: publicUrl,
        fileName: fileName,
        mimeType: mimeType,
        fileSizeBytes: fileSizeBytes,
        widthPx: widthPx,
        heightPx: heightPx,
      );
}

extension OnlineStoreBannerMapper on OnlineStoreBannerDto {
  OnlineStoreBanner toEntity() => OnlineStoreBanner(
        id: id,
        bannerType: bannerType,
        title: title,
        subtitle: subtitle,
        imageMediaAssetId: imageMediaAssetId,
        imageUrl: imageUrl,
        actionText: actionText,
        actionUrl: actionUrl,
        sortOrder: sortOrder,
        status: status,
      );
}

extension OnlineStoreSupportMapper on OnlineStoreSupportDto {
  OnlineStoreSupport toEntity() => OnlineStoreSupport(
        email: email,
        phone: phone,
        whatsapp: whatsapp,
        helpUrl: helpUrl,
        contactUsEnabled: contactUsEnabled,
        supportHours: supportHours,
        businessAddress: businessAddress,
      );
}

extension OnlineStoreClickCollectMapper on OnlineStoreClickCollectDto {
  OnlineStoreClickCollect toEntity() => OnlineStoreClickCollect(
        enabled: enabled,
        outletCount: outletCount,
        outlets: outlets.map((item) => item.toEntity()).toList(growable: false),
      );
}

extension OnlineStoreCollectionOutletMapper on OnlineStoreCollectionOutletDto {
  OnlineStoreCollectionOutlet toEntity() => OnlineStoreCollectionOutlet(
        outletId: outletId,
        outletName: outletName,
        outletStatus: outletStatus,
        businessHoursConfigured: businessHoursConfigured,
        preparationLeadMinutes: preparationLeadMinutes,
        pickupWindowMinutes: pickupWindowMinutes,
        cutoffTime: cutoffTime,
        status: status,
      );
}

extension OnlineStoreCatalogSummaryMapper on OnlineStoreCatalogSummaryDto {
  OnlineStoreCatalogSummary toEntity() => OnlineStoreCatalogSummary(
        totalProducts: totalProducts,
        visibleOnline: visibleOnline,
        notVisible: notVisible,
        orderable: orderable,
        lowStockProducts: lowStockProducts,
        outOfStockProducts: outOfStockProducts,
      );
}

extension OnlineStoreCatalogProductListMapper
    on OnlineStoreCatalogProductListDto {
  OnlineStoreCatalogProductList toEntity() => OnlineStoreCatalogProductList(
        pageNumber: pageNumber,
        pageSize: pageSize,
        totalCount: totalCount,
        items: items.map((item) => item.toEntity()).toList(growable: false),
      );
}

extension OnlineStoreCatalogProductMapper on OnlineStoreCatalogProductDto {
  OnlineStoreCatalogProduct toEntity() => OnlineStoreCatalogProduct(
        productId: productId,
        productVariantId: productVariantId,
        productName: productName,
        variantName: variantName,
        isVisible: isVisible,
        isOrderable: isOrderable,
        availableFrom: availableFrom,
        availableUntil: availableUntil,
        status: status,
      );
}

extension OnlineStorePolicyMapper on OnlineStorePolicyDto {
  OnlineStorePolicy toEntity() => OnlineStorePolicy(
        id: id,
        policyType: policyType,
        title: title,
        content: content,
        version: version,
        status: status,
        publishedAt: publishedAt,
      );
}

extension OnlineStorePublishMapper on OnlineStorePublishDto {
  OnlineStorePublishResult toEntity() => OnlineStorePublishResult(
        storeStatus: storeStatus,
        channelStatus: channelStatus,
        publishedAt: publishedAt,
        readiness: readiness.toEntity(),
      );
}
