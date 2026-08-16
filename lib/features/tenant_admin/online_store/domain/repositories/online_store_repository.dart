import 'dart:typed_data';

import '../entities/online_store.dart';

abstract class OnlineStoreRepository {
  Future<OnlineStoreOverview> getOverview();
  Future<OnlineStoreReadiness> getReadiness();
  Future<OnlineStoreActivation> getActivation();
  Future<OnlineStoreActivation> updateActivation(bool setupEnabled);
  Future<OnlineStoreIdentity> getIdentity();
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
  Future<OnlineStoreCatalogSummary> getCatalogSummary();
  Future<OnlineStoreCatalogProductList> listCatalogProducts({
    int pageNumber,
    int pageSize,
    String? search,
  });
  Future<List<OnlineStorePolicy>> listPolicies();
  Future<OnlineStorePublishResult> publish(String idempotencyKey);
}
