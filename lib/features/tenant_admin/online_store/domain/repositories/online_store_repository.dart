import 'dart:typed_data';

import '../entities/online_store.dart';

abstract class OnlineStoreRepository {
  Future<OnlineStoreOverview> getOverview();
  Future<OnlineStoreReadiness> getReadiness();
  Future<OnlineStoreActivation> getActivation();
  Future<OnlineStoreActivation> updateActivation(bool setupEnabled);
  Future<OnlineStoreIdentity> getIdentity();
  Future<OnlineStoreCheckoutRules> getCheckoutRules();
  Future<OnlineStoreIdentity> updateIdentity({
    required String storeName,
    required String businessDisplayName,
    String? storeDescription,
    String? storeEmail,
    String? storePhone,
    String? supportTagline,
  });
  Future<OnlineStoreUrlDomain> getUrlDomain();
  Future<OnlineStoreUrlDomain> updateUrl(String storeSlug);
  Future<List<OnlineStoreDomain>> listDomains();
  Future<OnlineStoreDomainToken> createDomain({
    required String domainName,
    required String domainType,
    required bool isPrimary,
  });
  Future<OnlineStoreDomain> verifyDomain(String domainId, String token);
  Future<OnlineStoreDomainToken> rotateDomainToken(String domainId);
  Future<OnlineStoreDomain> refreshDomainStatus(String domainId);
  Future<OnlineStoreDomain> provisionDomainSsl(String domainId);
  Future<OnlineStoreDomain> setPrimaryDomain(String domainId);
  Future<void> deleteDomain(String domainId);
  Future<OnlineStoreBranding> getBranding();
  Future<OnlineStoreBranding> updateBranding({
    String? logoMediaAssetId,
    String? faviconMediaAssetId,
    required String primaryColor,
    required String secondaryColor,
  });
  Future<OnlineStoreMedia> uploadMedia({
    required String purpose,
    required Uint8List bytes,
    required String fileName,
    required String mimeType,
    void Function(int sent, int total)? onProgress,
  });
  Future<void> deleteMedia(String mediaAssetId);
  Future<List<OnlineStoreBanner>> listBanners();
  Future<OnlineStoreBanner> saveBanner({
    String? id,
    required Map<String, dynamic> data,
  });
  Future<OnlineStoreBanner> updateBannerStatus(String id, String status);
  Future<List<OnlineStoreBanner>> reorderBanners(
    List<Map<String, dynamic>> items,
  );
  Future<void> deleteBanner(String id);
  Future<OnlineStoreSupport> getSupport();
  Future<OnlineStoreSupport> updateSupport({
    String? email,
    String? phone,
    String? whatsapp,
    String? helpUrl,
    required bool contactUsEnabled,
    String? supportHours,
    String? businessAddress,
  });
  Future<OnlineStoreClickCollect> getClickCollect();
  Future<OnlineStoreClickCollect> updateClickCollect(bool enabled);
  Future<List<OnlineStoreCollectionOutlet>> listClickCollectOutlets();
  Future<List<OnlineStoreCollectionOutlet>> addClickCollectOutlets(
    Map<String, dynamic> data,
  );
  Future<OnlineStoreCollectionOutlet> updateClickCollectOutlet(
    String outletId,
    Map<String, dynamic> data,
  );
  Future<void> deleteClickCollectOutlet(String outletId);
  Future<List<OnlineStoreCollectionOutlet>> bulkApplyClickCollect(
    Map<String, dynamic> data,
  );
  Future<OnlineStoreCatalogSummary> getCatalogSummary();
  Future<OnlineStoreCatalogProductList> listCatalogProducts({
    int pageNumber,
    int pageSize,
    String? search,
  });
  Future<List<OnlineStorePolicy>> listPolicies();
  Future<OnlineStoreCatalogProduct> updateProductVisibility(
    String productId,
    Map<String, dynamic> data,
  );
  Future<OnlineStoreCatalogProduct> updateVariantVisibility(
    String productId,
    String variantId,
    Map<String, dynamic> data,
  );
  Future<List<OnlineStoreCatalogProduct>> bulkUpdateProductVisibility(
    Map<String, dynamic> data,
  );
  Future<OnlineStorePolicy> getPolicy(String type);
  Future<OnlineStorePolicy> savePolicy(
    String type,
    Map<String, dynamic> data,
  );
  Future<OnlineStorePolicy> publishPolicy(String type);
  Future<List<OnlineStorePolicy>> listPolicyVersions(String type);
  Future<OnlineStorePolicy> archivePolicy(String type);
  Future<OnlineStorePublishResult> publish(String idempotencyKey);
}
