import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../../../../../core/network/api_endpoints.dart';
import '../../../../../core/network/media_url_resolver.dart';
import '../models/online_store_dtos.dart';

class OnlineStoreRemoteDatasource {
  const OnlineStoreRemoteDatasource(this._dio);

  final Dio _dio;

  Future<OnlineStoreOverviewDto> getOverview() async {
    final response = await _dio.get<dynamic>(
      ApiEndpoints.tenantAdminOnlineStoreOverview,
    );
    return OnlineStoreOverviewDto.fromJson(_payload(response));
  }

  Future<OnlineStoreReadinessDto> getReadiness() async {
    final response = await _dio.get<dynamic>(
      ApiEndpoints.tenantAdminOnlineStoreReadiness,
    );
    return OnlineStoreReadinessDto.fromJson(_payload(response));
  }

  Future<OnlineStoreActivationDto> getActivation() async {
    final response = await _dio.get<dynamic>(
      ApiEndpoints.tenantAdminOnlineStoreActivation,
    );
    return OnlineStoreActivationDto.fromJson(_payload(response));
  }

  Future<OnlineStoreActivationDto> updateActivation(bool setupEnabled) async {
    final response = await _dio.put<dynamic>(
      ApiEndpoints.tenantAdminOnlineStoreActivation,
      data: {'setupEnabled': setupEnabled},
    );
    return OnlineStoreActivationDto.fromJson(_payload(response));
  }

  Future<OnlineStoreIdentityDto> getIdentity() async {
    final response = await _dio.get<dynamic>(
      ApiEndpoints.tenantAdminOnlineStoreIdentity,
    );
    return OnlineStoreIdentityDto.fromJson(_payload(response));
  }

  Future<OnlineStoreCheckoutRulesDto> getCheckoutRules() async {
    final response = await _dio.get<dynamic>(
      ApiEndpoints.tenantAdminOnlineStoreCheckoutRules,
    );
    return OnlineStoreCheckoutRulesDto.fromJson(_payload(response));
  }

  Future<OnlineStoreIdentityDto> updateIdentity({
    required String storeName,
    required String businessDisplayName,
    String? storeDescription,
    String? storeEmail,
    String? storePhone,
    String? supportTagline,
  }) async {
    final response = await _dio.put<dynamic>(
      ApiEndpoints.tenantAdminOnlineStoreIdentity,
      data: {
        'storeName': storeName,
        'businessDisplayName': businessDisplayName,
        'storeDescription': storeDescription,
        'storeEmail': storeEmail,
        'storePhone': storePhone,
        'supportTagline': supportTagline,
      },
    );
    return OnlineStoreIdentityDto.fromJson(_payload(response));
  }

  Future<OnlineStoreUrlDomainDto> getUrlDomain() async {
    final response = await _dio.get<dynamic>(
      ApiEndpoints.tenantAdminOnlineStoreUrlDomain,
    );
    return OnlineStoreUrlDomainDto.fromJson(_payload(response));
  }

  Future<OnlineStoreUrlDomainDto> updateUrl(String storeSlug) async {
    final response = await _dio.put<dynamic>(
      ApiEndpoints.tenantAdminOnlineStoreUrl,
      data: {'storeSlug': storeSlug},
    );
    return OnlineStoreUrlDomainDto.fromJson(_payload(response));
  }

  Future<List<OnlineStoreDomainDto>> listDomains() async {
    final response = await _dio.get<dynamic>(
      ApiEndpoints.tenantAdminOnlineStoreDomains,
    );
    return _payloadList(response, OnlineStoreDomainDto.fromJson);
  }

  Future<OnlineStoreDomainTokenDto> createDomain({
    required String domainName,
    required String domainType,
    required bool isPrimary,
  }) async {
    final response = await _dio.post<dynamic>(
      ApiEndpoints.tenantAdminOnlineStoreDomains,
      data: {
        'domainName': domainName,
        'domainType': domainType,
        'isPrimary': isPrimary,
      },
    );
    return OnlineStoreDomainTokenDto.fromJson(_payload(response));
  }

  Future<OnlineStoreDomainDto> verifyDomain(
    String domainId,
    String verificationToken,
  ) async {
    final response = await _dio.post<dynamic>(
      ApiEndpoints.tenantAdminOnlineStoreDomainVerify(domainId),
      data: {'verificationToken': verificationToken},
    );
    return OnlineStoreDomainDto.fromJson(_payload(response));
  }

  Future<OnlineStoreDomainTokenDto> rotateDomainToken(String domainId) async {
    final response = await _dio.post<dynamic>(
      ApiEndpoints.tenantAdminOnlineStoreDomainRotateToken(domainId),
    );
    return OnlineStoreDomainTokenDto.fromJson(_payload(response));
  }

  Future<OnlineStoreDomainDto> getDomainStatus(String domainId) async {
    final response = await _dio.get<dynamic>(
      ApiEndpoints.tenantAdminOnlineStoreDomainStatus(domainId),
    );
    return OnlineStoreDomainDto.fromJson(_payload(response));
  }

  Future<OnlineStoreDomainDto> provisionDomainSsl(String domainId) async {
    final response = await _dio.post<dynamic>(
      ApiEndpoints.tenantAdminOnlineStoreDomainProvisionSsl(domainId),
    );
    return OnlineStoreDomainDto.fromJson(_payload(response));
  }

  Future<OnlineStoreDomainDto> setPrimaryDomain(String domainId) async {
    final response = await _dio.post<dynamic>(
      ApiEndpoints.tenantAdminOnlineStoreDomainSetPrimary(domainId),
    );
    return OnlineStoreDomainDto.fromJson(_payload(response));
  }

  Future<void> deleteDomain(String domainId) async {
    await _dio.delete<dynamic>(
      ApiEndpoints.tenantAdminOnlineStoreDomain(domainId),
    );
  }

  Future<OnlineStoreBrandingDto> getBranding() async {
    final response = await _dio.get<dynamic>(
      ApiEndpoints.tenantAdminOnlineStoreBranding,
    );
    return OnlineStoreBrandingDto.fromJson(
      _resolveBrandingMediaUrls(_payload(response)),
    );
  }

  Future<OnlineStoreBrandingDto> updateBranding({
    String? logoMediaAssetId,
    String? faviconMediaAssetId,
    required String primaryColor,
    required String secondaryColor,
  }) async {
    final response = await _dio.put<dynamic>(
      ApiEndpoints.tenantAdminOnlineStoreBranding,
      data: {
        'logoMediaAssetId': logoMediaAssetId,
        'faviconMediaAssetId': faviconMediaAssetId,
        'primaryColor': primaryColor,
        'secondaryColor': secondaryColor,
      },
    );
    return OnlineStoreBrandingDto.fromJson(
      _resolveBrandingMediaUrls(_payload(response)),
    );
  }

  Future<OnlineStoreMediaDto> uploadMedia({
    required String purpose,
    required Uint8List bytes,
    required String fileName,
    required String mimeType,
    void Function(int sent, int total)? onProgress,
  }) async {
    final response = await _dio.post<dynamic>(
      ApiEndpoints.tenantAdminOnlineStoreMedia(_backendMediaPurpose(purpose)),
      data: FormData.fromMap({
        'file': MultipartFile.fromBytes(
          bytes,
          filename: fileName,
          contentType: DioMediaType.parse(mimeType),
        ),
      }),
      onSendProgress: onProgress,
    );
    final payload = _payload(response);
    payload['publicUrl'] = _resolveMediaUrl(payload['publicUrl']);
    return OnlineStoreMediaDto.fromJson(payload);
  }

  Future<void> deleteMedia(String mediaAssetId) async {
    await _dio.delete<dynamic>(
      ApiEndpoints.tenantAdminOnlineStoreMediaAsset(mediaAssetId),
    );
  }

  Future<List<OnlineStoreBannerDto>> listBanners() async {
    final response = await _dio.get<dynamic>(
      ApiEndpoints.tenantAdminOnlineStoreBanners,
    );
    return _payloadList(
      response,
      (json) => OnlineStoreBannerDto.fromJson(_resolveBannerMediaUrl(json)),
    );
  }

  Future<OnlineStoreBannerDto> getBanner(String id) async {
    final response = await _dio.get<dynamic>(
      ApiEndpoints.tenantAdminOnlineStoreBanner(id),
    );
    return OnlineStoreBannerDto.fromJson(
      _resolveBannerMediaUrl(_payload(response)),
    );
  }

  Future<OnlineStoreBannerDto> upsertBanner({
    String? id,
    required Map<String, dynamic> data,
  }) async {
    final response = id == null
        ? await _dio.post<dynamic>(
            ApiEndpoints.tenantAdminOnlineStoreBanners,
            data: data,
          )
        : await _dio.put<dynamic>(
            ApiEndpoints.tenantAdminOnlineStoreBanner(id),
            data: data,
          );
    return OnlineStoreBannerDto.fromJson(
      _resolveBannerMediaUrl(_payload(response)),
    );
  }

  Future<OnlineStoreBannerDto> updateBannerStatus(
    String id,
    String status,
  ) async {
    final response = await _dio.patch<dynamic>(
      ApiEndpoints.tenantAdminOnlineStoreBannerStatus(id),
      data: {'status': status},
    );
    return OnlineStoreBannerDto.fromJson(
      _resolveBannerMediaUrl(_payload(response)),
    );
  }

  Future<List<OnlineStoreBannerDto>> reorderBanners(
    List<Map<String, dynamic>> items,
  ) async {
    final response = await _dio.put<dynamic>(
      ApiEndpoints.tenantAdminOnlineStoreBannerOrder,
      data: {'items': items},
    );
    return _payloadList(
      response,
      (json) => OnlineStoreBannerDto.fromJson(_resolveBannerMediaUrl(json)),
    );
  }

  Future<void> deleteBanner(String id) async {
    await _dio.delete<dynamic>(ApiEndpoints.tenantAdminOnlineStoreBanner(id));
  }

  Future<OnlineStoreSupportDto> getSupport() async {
    final response = await _dio.get<dynamic>(
      ApiEndpoints.tenantAdminOnlineStoreSupport,
    );
    return OnlineStoreSupportDto.fromJson(_payload(response));
  }

  Future<OnlineStoreSupportDto> updateSupport({
    String? email,
    String? phone,
    String? whatsapp,
    String? helpUrl,
    required bool contactUsEnabled,
    String? supportHours,
    String? businessAddress,
  }) async {
    final response = await _dio.put<dynamic>(
      ApiEndpoints.tenantAdminOnlineStoreSupport,
      data: {
        'email': email,
        'phone': phone,
        'whatsapp': whatsapp,
        'helpUrl': helpUrl,
        'contactUsEnabled': contactUsEnabled,
        'supportHours': supportHours,
        'businessAddress': businessAddress,
      },
    );
    return OnlineStoreSupportDto.fromJson(_payload(response));
  }

  Future<OnlineStoreClickCollectDto> getClickCollect() async {
    final response = await _dio.get<dynamic>(
      ApiEndpoints.tenantAdminOnlineStoreClickCollect,
    );
    return OnlineStoreClickCollectDto.fromJson(_payload(response));
  }

  Future<OnlineStoreClickCollectDto> updateClickCollect(bool enabled) async {
    final response = await _dio.put<dynamic>(
      ApiEndpoints.tenantAdminOnlineStoreClickCollect,
      data: {'enabled': enabled},
    );
    return OnlineStoreClickCollectDto.fromJson(_payload(response));
  }

  Future<List<OnlineStoreCollectionOutletDto>> listClickCollectOutlets() async {
    final response = await _dio.get<dynamic>(
      ApiEndpoints.tenantAdminOnlineStoreClickCollectOutlets,
    );
    return _payloadList(response, OnlineStoreCollectionOutletDto.fromJson);
  }

  Future<List<OnlineStoreCollectionOutletDto>> addClickCollectOutlets(
    Map<String, dynamic> data,
  ) async {
    final response = await _dio.post<dynamic>(
      ApiEndpoints.tenantAdminOnlineStoreClickCollectOutlets,
      data: data,
    );
    return _payloadList(response, OnlineStoreCollectionOutletDto.fromJson);
  }

  Future<OnlineStoreCollectionOutletDto> upsertClickCollectOutlet(
    String outletId,
    Map<String, dynamic> data,
  ) async {
    final response = await _dio.put<dynamic>(
      ApiEndpoints.tenantAdminOnlineStoreClickCollectOutlet(outletId),
      data: data,
    );
    return OnlineStoreCollectionOutletDto.fromJson(_payload(response));
  }

  Future<void> deleteClickCollectOutlet(String outletId) async {
    await _dio.delete<dynamic>(
      ApiEndpoints.tenantAdminOnlineStoreClickCollectOutlet(outletId),
    );
  }

  Future<List<OnlineStoreCollectionOutletDto>> bulkApplyClickCollect(
    Map<String, dynamic> data,
  ) async {
    final response = await _dio.post<dynamic>(
      ApiEndpoints.tenantAdminOnlineStoreClickCollectBulkApply,
      data: data,
    );
    return _payloadList(response, OnlineStoreCollectionOutletDto.fromJson);
  }

  Future<OnlineStoreCatalogSummaryDto> getCatalogSummary() async {
    final response = await _dio.get<dynamic>(
      ApiEndpoints.tenantAdminOnlineStoreCatalogSummary,
    );
    return OnlineStoreCatalogSummaryDto.fromJson(_payload(response));
  }

  Future<OnlineStoreCatalogProductListDto> listCatalogProducts({
    int pageNumber = 1,
    int pageSize = 20,
    String? search,
  }) async {
    final response = await _dio.get<dynamic>(
      ApiEndpoints.tenantAdminOnlineStoreCatalogProducts,
      queryParameters: {
        'pageNumber': pageNumber,
        'pageSize': pageSize,
        if (search != null && search.trim().isNotEmpty) 'search': search,
      },
    );
    return OnlineStoreCatalogProductListDto.fromJson(_payload(response));
  }

  Future<OnlineStoreCatalogProductDto> updateProductVisibility(
    String productId,
    Map<String, dynamic> data,
  ) async {
    final response = await _dio.patch<dynamic>(
      ApiEndpoints.tenantAdminOnlineStoreCatalogProductVisibility(productId),
      data: data,
    );
    return OnlineStoreCatalogProductDto.fromJson(_payload(response));
  }

  Future<OnlineStoreCatalogProductDto> updateVariantVisibility(
    String productId,
    String variantId,
    Map<String, dynamic> data,
  ) async {
    final response = await _dio.patch<dynamic>(
      ApiEndpoints.tenantAdminOnlineStoreCatalogVariantVisibility(
        productId,
        variantId,
      ),
      data: data,
    );
    return OnlineStoreCatalogProductDto.fromJson(_payload(response));
  }

  Future<List<OnlineStoreCatalogProductDto>> bulkUpdateProductVisibility(
    Map<String, dynamic> data,
  ) async {
    final response = await _dio.post<dynamic>(
      ApiEndpoints.tenantAdminOnlineStoreCatalogBulkVisibility,
      data: data,
    );
    return _payloadList(response, OnlineStoreCatalogProductDto.fromJson);
  }

  Future<List<OnlineStorePolicyDto>> listPolicies() async {
    final response = await _dio.get<dynamic>(
      ApiEndpoints.tenantAdminOnlineStorePolicies,
    );
    return _payloadList(response, OnlineStorePolicyDto.fromJson);
  }

  Future<OnlineStorePolicyDto> getPolicy(String type) async {
    final response = await _dio.get<dynamic>(
      ApiEndpoints.tenantAdminOnlineStorePolicy(type),
    );
    return OnlineStorePolicyDto.fromJson(_payload(response));
  }

  Future<OnlineStorePolicyDto> upsertPolicy(
    String type,
    Map<String, dynamic> data,
  ) async {
    final response = await _dio.put<dynamic>(
      ApiEndpoints.tenantAdminOnlineStorePolicy(type),
      data: data,
    );
    return OnlineStorePolicyDto.fromJson(_payload(response));
  }

  Future<OnlineStorePolicyDto> publishPolicy(String type) async {
    final response = await _dio.post<dynamic>(
      ApiEndpoints.tenantAdminOnlineStorePolicyPublish(type),
    );
    return OnlineStorePolicyDto.fromJson(_payload(response));
  }

  Future<List<OnlineStorePolicyDto>> listPolicyVersions(String type) async {
    final response = await _dio.get<dynamic>(
      ApiEndpoints.tenantAdminOnlineStorePolicyVersions(type),
    );
    return _payloadList(response, OnlineStorePolicyDto.fromJson);
  }

  Future<OnlineStorePolicyDto> archivePolicy(String type) async {
    final response = await _dio.post<dynamic>(
      ApiEndpoints.tenantAdminOnlineStorePolicyArchive(type),
    );
    return OnlineStorePolicyDto.fromJson(_payload(response));
  }

  Future<OnlineStorePublishDto> publish(String idempotencyKey) async {
    final response = await _dio.post<dynamic>(
      ApiEndpoints.tenantAdminOnlineStorePublish,
      options: Options(headers: {'Idempotency-Key': idempotencyKey}),
    );
    return OnlineStorePublishDto.fromJson(_payload(response));
  }

  Map<String, dynamic> _payload(Response<dynamic> response) {
    final data = response.data;
    if (data is! Map) {
      return const {};
    }

    final root = Map<String, dynamic>.from(data);
    if (root['data'] is Map) {
      return Map<String, dynamic>.from(root['data'] as Map);
    }
    return root;
  }

  List<T> _payloadList<T>(
    Response<dynamic> response,
    T Function(Map<String, dynamic>) map,
  ) {
    final data = response.data;
    final value = data is Map ? data['data'] : data;
    if (value is! List) {
      return const [];
    }

    return [
      for (final item in value)
        if (item is Map) map(Map<String, dynamic>.from(item)),
    ];
  }

  Map<String, dynamic> _resolveBrandingMediaUrls(
    Map<String, dynamic> payload,
  ) {
    final resolved = Map<String, dynamic>.from(payload);
    resolved['logoImageUrl'] = _resolveMediaUrl(resolved['logoImageUrl']);
    resolved['faviconImageUrl'] = _resolveMediaUrl(resolved['faviconImageUrl']);
    final banners = resolved['banners'];
    if (banners is List) {
      resolved['banners'] = [
        for (final banner in banners)
          if (banner is Map)
            _resolveBannerMediaUrl(Map<String, dynamic>.from(banner)),
      ];
    }
    return resolved;
  }

  Map<String, dynamic> _resolveBannerMediaUrl(Map<String, dynamic> payload) {
    final resolved = Map<String, dynamic>.from(payload);
    resolved['imageUrl'] = _resolveMediaUrl(resolved['imageUrl']);
    return resolved;
  }

  String? _resolveMediaUrl(Object? value) {
    return MediaUrlResolver.resolve(
      value?.toString(),
      apiBaseUrl: _dio.options.baseUrl,
      replaceLoopbackHost: true,
    );
  }
}

String _backendMediaPurpose(String purpose) {
  switch (purpose.trim().toLowerCase()) {
    case 'logo':
    case 'online_store_logo':
      return 'ONLINE_STORE_LOGO';
    case 'favicon':
    case 'online_store_favicon':
      return 'ONLINE_STORE_FAVICON';
    case 'banner':
    case 'storefront_banner':
      return 'STOREFRONT_BANNER';
    default:
      return purpose.trim().toUpperCase();
  }
}
