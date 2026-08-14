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
  Future<OnlineStorePublishResult> publish(String idempotencyKey) async {
    return (await _remote.publish(idempotencyKey)).toEntity();
  }
}
