import 'dart:typed_data';

import '../../domain/entities/online_store.dart';
import '../../domain/repositories/online_store_repository.dart';
import '../datasources/online_store_remote_datasource.dart';
import '../mappers/online_store_mapper.dart';

class OnlineStoreRepositoryImpl implements OnlineStoreRepository {
  const OnlineStoreRepositoryImpl(this._remote);

  final OnlineStoreRemoteDatasource _remote;

  @override
  Future<OnlineStoreOverview> getOverview() async {
    return (await _remote.getOverview()).toEntity();
  }

  @override
  Future<OnlineStoreReadiness> getReadiness() async {
    return (await _remote.getReadiness()).toEntity();
  }

  @override
  Future<OnlineStoreActivation> getActivation() async {
    return (await _remote.getActivation()).toEntity();
  }

  @override
  Future<OnlineStoreActivation> updateActivation(bool setupEnabled) async {
    return (await _remote.updateActivation(setupEnabled)).toEntity();
  }

  @override
  Future<OnlineStoreIdentity> getIdentity() async {
    return (await _remote.getIdentity()).toEntity();
  }

  @override
  Future<OnlineStoreCheckoutRules> getCheckoutRules() async {
    return (await _remote.getCheckoutRules()).toEntity();
  }

  @override
  Future<OnlineStoreIdentity> updateIdentity({
    required String storeName,
    required String businessDisplayName,
    String? storeDescription,
    String? storeEmail,
    String? storePhone,
    String? supportTagline,
  }) async {
    return (await _remote.updateIdentity(
      storeName: storeName,
      businessDisplayName: businessDisplayName,
      storeDescription: storeDescription,
      storeEmail: storeEmail,
      storePhone: storePhone,
      supportTagline: supportTagline,
    ))
        .toEntity();
  }

  @override
  Future<OnlineStoreUrlDomain> getUrlDomain() async {
    return (await _remote.getUrlDomain()).toEntity();
  }

  @override
  Future<OnlineStoreUrlDomain> updateUrl(String storeSlug) async {
    return (await _remote.updateUrl(storeSlug)).toEntity();
  }

  @override
  Future<List<OnlineStoreDomain>> listDomains() async {
    final dtos = await _remote.listDomains();
    return dtos.map((item) => item.toEntity()).toList(growable: false);
  }

  @override
  Future<OnlineStoreDomainToken> createDomain(
      {required String domainName,
      required String domainType,
      required bool isPrimary}) async {
    return (await _remote.createDomain(
      domainName: domainName,
      domainType: domainType,
      isPrimary: isPrimary,
    ))
        .toEntity();
  }

  @override
  Future<OnlineStoreDomain> verifyDomain(String domainId, String token) async =>
      (await _remote.verifyDomain(domainId, token)).toEntity();

  @override
  Future<OnlineStoreDomainToken> rotateDomainToken(String domainId) async =>
      (await _remote.rotateDomainToken(domainId)).toEntity();

  @override
  Future<OnlineStoreDomain> refreshDomainStatus(String domainId) async =>
      (await _remote.getDomainStatus(domainId)).toEntity();

  @override
  Future<OnlineStoreDomain> provisionDomainSsl(String domainId) async =>
      (await _remote.provisionDomainSsl(domainId)).toEntity();

  @override
  Future<OnlineStoreDomain> setPrimaryDomain(String domainId) async =>
      (await _remote.setPrimaryDomain(domainId)).toEntity();

  @override
  Future<void> deleteDomain(String domainId) => _remote.deleteDomain(domainId);

  @override
  Future<OnlineStoreBranding> getBranding() async {
    return (await _remote.getBranding()).toEntity();
  }

  @override
  Future<OnlineStoreBranding> updateBranding({
    String? logoMediaAssetId,
    String? faviconMediaAssetId,
    required String primaryColor,
    required String secondaryColor,
  }) async {
    return (await _remote.updateBranding(
      logoMediaAssetId: logoMediaAssetId,
      faviconMediaAssetId: faviconMediaAssetId,
      primaryColor: primaryColor,
      secondaryColor: secondaryColor,
    ))
        .toEntity();
  }

  @override
  Future<OnlineStoreMedia> uploadMedia({
    required String purpose,
    required Uint8List bytes,
    required String fileName,
    required String mimeType,
    void Function(int sent, int total)? onProgress,
  }) async {
    return (await _remote.uploadMedia(
      purpose: purpose,
      bytes: bytes,
      fileName: fileName,
      mimeType: mimeType,
      onProgress: onProgress,
    ))
        .toEntity();
  }

  @override
  Future<void> deleteMedia(String mediaAssetId) {
    return _remote.deleteMedia(mediaAssetId);
  }

  @override
  Future<List<OnlineStoreBanner>> listBanners() async {
    final dtos = await _remote.listBanners();
    return dtos.map((item) => item.toEntity()).toList(growable: false);
  }

  @override
  Future<OnlineStoreBanner> saveBanner(
          {String? id, required Map<String, dynamic> data}) async =>
      (await _remote.upsertBanner(id: id, data: data)).toEntity();

  @override
  Future<OnlineStoreBanner> updateBannerStatus(
          String id, String status) async =>
      (await _remote.updateBannerStatus(id, status)).toEntity();

  @override
  Future<List<OnlineStoreBanner>> reorderBanners(
          List<Map<String, dynamic>> items) async =>
      (await _remote.reorderBanners(items))
          .map((item) => item.toEntity())
          .toList(growable: false);

  @override
  Future<void> deleteBanner(String id) => _remote.deleteBanner(id);

  @override
  Future<OnlineStoreSupport> getSupport() async {
    return (await _remote.getSupport()).toEntity();
  }

  @override
  Future<OnlineStoreSupport> updateSupport({
    String? email,
    String? phone,
    String? whatsapp,
    String? helpUrl,
    required bool contactUsEnabled,
    String? supportHours,
    String? businessAddress,
  }) async {
    return (await _remote.updateSupport(
      email: email,
      phone: phone,
      whatsapp: whatsapp,
      helpUrl: helpUrl,
      contactUsEnabled: contactUsEnabled,
      supportHours: supportHours,
      businessAddress: businessAddress,
    ))
        .toEntity();
  }

  @override
  Future<OnlineStoreClickCollect> getClickCollect() async {
    return (await _remote.getClickCollect()).toEntity();
  }

  @override
  Future<OnlineStoreClickCollect> updateClickCollect(bool enabled) async {
    return (await _remote.updateClickCollect(enabled)).toEntity();
  }

  @override
  Future<List<OnlineStoreCollectionOutlet>> listClickCollectOutlets() async {
    final dtos = await _remote.listClickCollectOutlets();
    return dtos.map((item) => item.toEntity()).toList(growable: false);
  }

  @override
  Future<List<OnlineStoreCollectionOutlet>> addClickCollectOutlets(
          Map<String, dynamic> data) async =>
      (await _remote.addClickCollectOutlets(data))
          .map((item) => item.toEntity())
          .toList(growable: false);

  @override
  Future<OnlineStoreCollectionOutlet> updateClickCollectOutlet(
          String outletId, Map<String, dynamic> data) async =>
      (await _remote.upsertClickCollectOutlet(outletId, data)).toEntity();

  @override
  Future<void> deleteClickCollectOutlet(String outletId) =>
      _remote.deleteClickCollectOutlet(outletId);

  @override
  Future<List<OnlineStoreCollectionOutlet>> bulkApplyClickCollect(
          Map<String, dynamic> data) async =>
      (await _remote.bulkApplyClickCollect(data))
          .map((item) => item.toEntity())
          .toList(growable: false);

  @override
  Future<OnlineStoreCatalogSummary> getCatalogSummary() async {
    return (await _remote.getCatalogSummary()).toEntity();
  }

  @override
  Future<OnlineStoreCatalogProductList> listCatalogProducts({
    int pageNumber = 1,
    int pageSize = 20,
    String? search,
  }) async {
    return (await _remote.listCatalogProducts(
      pageNumber: pageNumber,
      pageSize: pageSize,
      search: search,
    ))
        .toEntity();
  }

  @override
  Future<List<OnlineStorePolicy>> listPolicies() async {
    final dtos = await _remote.listPolicies();
    return dtos.map((item) => item.toEntity()).toList(growable: false);
  }

  @override
  Future<OnlineStoreCatalogProduct> updateProductVisibility(
          String productId, Map<String, dynamic> data) async =>
      (await _remote.updateProductVisibility(productId, data)).toEntity();

  @override
  Future<OnlineStoreCatalogProduct> updateVariantVisibility(String productId,
          String variantId, Map<String, dynamic> data) async =>
      (await _remote.updateVariantVisibility(productId, variantId, data))
          .toEntity();

  @override
  Future<List<OnlineStoreCatalogProduct>> bulkUpdateProductVisibility(
          Map<String, dynamic> data) async =>
      (await _remote.bulkUpdateProductVisibility(data))
          .map((item) => item.toEntity())
          .toList(growable: false);

  @override
  Future<OnlineStorePolicy> getPolicy(String type) async =>
      (await _remote.getPolicy(type)).toEntity();

  @override
  Future<OnlineStorePolicy> savePolicy(
          String type, Map<String, dynamic> data) async =>
      (await _remote.upsertPolicy(type, data)).toEntity();

  @override
  Future<OnlineStorePolicy> publishPolicy(String type) async =>
      (await _remote.publishPolicy(type)).toEntity();

  @override
  Future<List<OnlineStorePolicy>> listPolicyVersions(String type) async =>
      (await _remote.listPolicyVersions(type))
          .map((item) => item.toEntity())
          .toList(growable: false);

  @override
  Future<OnlineStorePolicy> archivePolicy(String type) async =>
      (await _remote.archivePolicy(type)).toEntity();

  @override
  Future<OnlineStorePublishResult> publish(String idempotencyKey) async {
    return (await _remote.publish(idempotencyKey)).toEntity();
  }
}
