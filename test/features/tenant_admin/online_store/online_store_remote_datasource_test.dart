import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nytroz_pos/core/network/api_endpoints.dart';
import 'package:nytroz_pos/features/tenant_admin/online_store/data/datasources/online_store_remote_datasource.dart';

void main() {
  test('getOverview unwraps api response envelope', () async {
    final adapter = _RecordingAdapter((options) {
      expect(options.method, 'GET');
      expect(options.path, ApiEndpoints.tenantAdminOnlineStoreOverview);
      return _jsonResponse({
        'data': {
          'salesChannelId': 'channel-1',
          'storeStatus': 'DRAFT',
          'channelStatus': 'INACTIVE',
          'setupEnabled': false,
          'visibility': 'NOT_LIVE',
          'completedSteps': 1,
          'totalSteps': 9,
          'setupProgressPercent': 11,
          'steps': <Map<String, Object>>[],
          'readiness': {
            'canPublish': false,
            'blockingReasons': <String>[],
            'steps': <Map<String, Object>>[],
          },
        },
      });
    });

    final datasource = OnlineStoreRemoteDatasource(_dio(adapter));
    final dto = await datasource.getOverview();

    expect(dto.salesChannelId, 'channel-1');
    expect(dto.totalSteps, 9);
    expect(adapter.requests.single.path,
        ApiEndpoints.tenantAdminOnlineStoreOverview);
  });

  test('getCheckoutRules uses the canonical checkout rules route', () async {
    final adapter = _RecordingAdapter((options) {
      expect(options.method, 'GET');
      expect(
        options.path,
        ApiEndpoints.tenantAdminOnlineStoreCheckoutRules,
      );
      return _jsonResponse({
        'data': {
          'release': 'R1',
          'customerAccount': {
            'registrationRequired': true,
            'mode': 'REGISTRATION_REQUIRED',
            'label': 'Registration required',
          },
          'guestCheckout': {
            'available': false,
            'mode': 'NOT_AVAILABLE',
            'label': 'Not available',
          },
          'emailVerification': {
            'required': true,
            'mode': 'REQUIRED',
            'label': 'Required',
          },
          'fulfilment': {
            'mode': 'CLICK_COLLECT',
            'label': 'Click & Collect',
            'featureEnabled': true,
            'configured': true,
          },
          'payment': {
            'mode': 'PAY_AT_PICKUP',
            'label': 'Pay at Pickup',
          },
        },
      });
    });

    final datasource = OnlineStoreRemoteDatasource(_dio(adapter));
    final dto = await datasource.getCheckoutRules();

    expect(dto.release, 'R1');
    expect(dto.fulfilment.label, 'Click & Collect');
    expect(dto.payment.label, 'Pay at Pickup');
    expect(adapter.requests, hasLength(1));
  });

  test('updateIdentity sends backend request body to canonical route',
      () async {
    final adapter = _RecordingAdapter((options) {
      expect(options.method, 'PUT');
      expect(options.path, ApiEndpoints.tenantAdminOnlineStoreIdentity);
      expect(options.data, {
        'storeName': 'Store',
        'businessDisplayName': 'Store Display',
        'storeDescription': null,
        'storeEmail': 'support@example.com',
        'storePhone': null,
        'supportTagline': 'Help',
      });
      return _jsonResponse({
        'data': {
          'salesChannelId': 'channel-1',
          'storeName': 'Store',
          'businessDisplayName': 'Store Display',
          'currencyCode': 'LKR',
          'timezone': 'Asia/Colombo',
        },
      });
    });

    final datasource = OnlineStoreRemoteDatasource(_dio(adapter));
    final dto = await datasource.updateIdentity(
      storeName: 'Store',
      businessDisplayName: 'Store Display',
      storeEmail: 'support@example.com',
      supportTagline: 'Help',
    );

    expect(dto.businessDisplayName, 'Store Display');
  });

  test('uploadMedia posts multipart file to media purpose endpoint', () async {
    final adapter = _RecordingAdapter((options) {
      expect(options.method, 'POST');
      expect(
        options.path,
        ApiEndpoints.tenantAdminOnlineStoreMedia('ONLINE_STORE_LOGO'),
      );
      expect(options.data, isA<FormData>());
      return _jsonResponse({
        'data': {
          'mediaAssetId': 'media-1',
          'purpose': 'LOGO',
          'fileName': 'logo.png',
          'mimeType': 'image/png',
          'fileSizeBytes': 3,
        },
      });
    });

    final datasource = OnlineStoreRemoteDatasource(_dio(adapter));
    final dto = await datasource.uploadMedia(
      purpose: 'LOGO',
      bytes: Uint8List.fromList([1, 2, 3]),
      fileName: 'logo.png',
      mimeType: 'image/png',
    );

    expect(dto.mediaAssetId, 'media-1');
  });

  test('getBranding preserves backend asset URLs', () async {
    final adapter = _RecordingAdapter((options) {
      expect(options.method, 'GET');
      expect(options.path, ApiEndpoints.tenantAdminOnlineStoreBranding);
      return _jsonResponse({
        'data': {
          'logoMediaAssetId': 'logo-1',
          'faviconMediaAssetId': 'favicon-1',
          'logoImageUrl': 'https://cdn.example.com/logo.png',
          'faviconImageUrl': 'https://cdn.example.com/favicon.ico',
          'primaryColor': '#123456',
          'secondaryColor': '#ABCDEF',
          'banners': <Map<String, Object?>>[],
        },
      });
    });

    final dto = await OnlineStoreRemoteDatasource(_dio(adapter)).getBranding();

    expect(dto.logoImageUrl, 'https://cdn.example.com/logo.png');
    expect(dto.faviconImageUrl, 'https://cdn.example.com/favicon.ico');
  });

  test('getBranding resolves relative branding and banner media URLs',
      () async {
    final adapter = _RecordingAdapter((options) {
      return _jsonResponse({
        'data': {
          'logoMediaAssetId': 'logo-1',
          'faviconMediaAssetId': 'favicon-1',
          'logoImageUrl': '/uploads/images/logo.png',
          'faviconImageUrl': '/uploads/images/favicon.ico',
          'primaryColor': '#123456',
          'secondaryColor': '#ABCDEF',
          'banners': [
            {
              'id': 'banner-1',
              'bannerType': 'HERO',
              'title': 'Offer',
              'imageMediaAssetId': 'banner-media-1',
              'imageUrl': '/uploads/images/banner.png',
              'sortOrder': 0,
              'status': 'ACTIVE',
            },
          ],
        },
      });
    });

    final dto = await OnlineStoreRemoteDatasource(
      _dio(adapter, baseUrl: 'http://127.0.0.1:5052'),
    ).getBranding();

    expect(dto.logoImageUrl, 'http://127.0.0.1:5052/uploads/images/logo.png');
    expect(
      dto.faviconImageUrl,
      'http://127.0.0.1:5052/uploads/images/favicon.ico',
    );
    expect(
      dto.banners.single.imageUrl,
      'http://127.0.0.1:5052/uploads/images/banner.png',
    );
  });

  test('updateBranding sends the exact backend request body', () async {
    final adapter = _RecordingAdapter((options) {
      expect(options.method, 'PUT');
      expect(options.path, ApiEndpoints.tenantAdminOnlineStoreBranding);
      expect(options.data, {
        'logoMediaAssetId': 'logo-2',
        'faviconMediaAssetId': null,
        'primaryColor': '#123456',
        'secondaryColor': '#ABCDEF',
      });
      return _jsonResponse({
        'data': {
          'logoMediaAssetId': 'logo-2',
          'primaryColor': '#123456',
          'secondaryColor': '#ABCDEF',
          'banners': <Map<String, Object?>>[],
        },
      });
    });

    final dto = await OnlineStoreRemoteDatasource(_dio(adapter)).updateBranding(
      logoMediaAssetId: 'logo-2',
      primaryColor: '#123456',
      secondaryColor: '#ABCDEF',
    );

    expect(dto.logoMediaAssetId, 'logo-2');
  });

  test('deleteMedia uses the canonical media asset endpoint', () async {
    final adapter = _RecordingAdapter((options) {
      expect(options.method, 'DELETE');
      expect(
        options.path,
        ApiEndpoints.tenantAdminOnlineStoreMediaAsset('media-1'),
      );
      return ResponseBody.fromString('', 204);
    });

    await OnlineStoreRemoteDatasource(_dio(adapter)).deleteMedia('media-1');

    expect(adapter.requests, hasLength(1));
  });

  test('getSupport maps the complete backend support response', () async {
    final adapter = _RecordingAdapter((options) {
      expect(options.method, 'GET');
      expect(options.path, ApiEndpoints.tenantAdminOnlineStoreSupport);
      return _jsonResponse({
        'data': {
          'email': 'help@example.test',
          'phone': '+94110000000',
          'whatsapp': '+94770000000',
          'helpUrl': 'https://support.example.test',
          'contactUsEnabled': true,
          'supportHours': 'Mon - Fri: 9:00 AM - 6:00 PM',
          'businessAddress': 'Example support address',
        },
      });
    });

    final dto = await OnlineStoreRemoteDatasource(_dio(adapter)).getSupport();

    expect(dto.email, 'help@example.test');
    expect(dto.whatsapp, '+94770000000');
    expect(dto.contactUsEnabled, isTrue);
  });

  test('updateSupport sends exact full replacement contract', () async {
    final adapter = _RecordingAdapter((options) {
      expect(options.method, 'PUT');
      expect(options.path, ApiEndpoints.tenantAdminOnlineStoreSupport);
      expect(options.data, {
        'email': 'help@example.test',
        'phone': '+94 11 000 0000',
        'whatsapp': null,
        'helpUrl': 'https://support.example.test',
        'contactUsEnabled': false,
        'supportHours': 'Mon - Fri: 9:00 AM - 6:00 PM',
        'businessAddress': 'Example support address',
      });
      return _jsonResponse({
        'data': {
          'email': 'help@example.test',
          'phone': '+94110000000',
          'whatsapp': null,
          'helpUrl': 'https://support.example.test',
          'contactUsEnabled': false,
          'supportHours': 'Mon - Fri: 9:00 AM - 6:00 PM',
          'businessAddress': 'Example support address',
        },
      });
    });

    final dto = await OnlineStoreRemoteDatasource(_dio(adapter)).updateSupport(
      email: 'help@example.test',
      phone: '+94 11 000 0000',
      helpUrl: 'https://support.example.test',
      contactUsEnabled: false,
      supportHours: 'Mon - Fri: 9:00 AM - 6:00 PM',
      businessAddress: 'Example support address',
    );

    expect(dto.phone, '+94110000000');
    expect(dto.contactUsEnabled, isFalse);
  });

  test('publish sends Idempotency-Key header to publish endpoint', () async {
    final adapter = _RecordingAdapter((options) {
      expect(options.method, 'POST');
      expect(options.path, ApiEndpoints.tenantAdminOnlineStorePublish);
      expect(options.headers['Idempotency-Key'], 'publish-key');
      return _jsonResponse({
        'data': {
          'storeStatus': 'PUBLISHED',
          'channelStatus': 'ACTIVE',
          'publishedAt': '2026-08-14T09:30:00Z',
          'readiness': {
            'canPublish': true,
            'blockingReasons': <String>[],
            'steps': <Map<String, Object>>[],
          },
        },
      });
    });

    final datasource = OnlineStoreRemoteDatasource(_dio(adapter));
    final dto = await datasource.publish('publish-key');

    expect(dto.storeStatus, 'PUBLISHED');
  });

  test('listCatalogProducts sends server pagination query parameters',
      () async {
    final adapter = _RecordingAdapter((options) {
      expect(options.method, 'GET');
      expect(options.path, ApiEndpoints.tenantAdminOnlineStoreCatalogProducts);
      expect(options.queryParameters, {
        'pageNumber': 2,
        'pageSize': 25,
        'search': 'tea',
      });
      return _jsonResponse({
        'data': {
          'pageNumber': 2,
          'pageSize': 25,
          'totalCount': 0,
          'items': <Map<String, Object>>[],
        },
      });
    });

    final datasource = OnlineStoreRemoteDatasource(_dio(adapter));
    final dto = await datasource.listCatalogProducts(
      pageNumber: 2,
      pageSize: 25,
      search: 'tea',
    );

    expect(dto.pageNumber, 2);
    expect(dto.pageSize, 25);
  });

  test('setPrimaryDomain uses canonical lifecycle endpoint', () async {
    final adapter = _RecordingAdapter((options) {
      expect(options.method, 'POST');
      expect(
        options.path,
        ApiEndpoints.tenantAdminOnlineStoreDomainSetPrimary('domain-1'),
      );
      return _jsonResponse({
        'data': {
          'id': 'domain-1',
          'domainType': 'CUSTOM',
          'domainName': 'store.example.com',
          'isPrimary': true,
          'verificationStatus': 'VERIFIED',
          'sslStatus': 'ACTIVE',
          'status': 'ACTIVE',
        },
      });
    });

    final datasource = OnlineStoreRemoteDatasource(_dio(adapter));
    final dto = await datasource.setPrimaryDomain('domain-1');

    expect(dto.isPrimary, isTrue);
  });

  test('createDomain preserves backend verification token response', () async {
    final adapter = _RecordingAdapter((options) {
      expect(options.method, 'POST');
      expect(options.path, ApiEndpoints.tenantAdminOnlineStoreDomains);
      expect(options.data, {
        'domainName': 'store.example.com',
        'domainType': 'CUSTOM',
        'isPrimary': false,
      });
      return _jsonResponse({
        'data': {
          'domainId': 'domain-1',
          'domainName': 'store.example.com',
          'verificationToken': 'dns-token',
        },
      });
    });

    final datasource = OnlineStoreRemoteDatasource(_dio(adapter));
    final token = await datasource.createDomain(
      domainName: 'store.example.com',
      domainType: 'CUSTOM',
      isPrimary: false,
    );

    expect(token.domainId, 'domain-1');
    expect(token.verificationToken, 'dns-token');
  });

  test('rotateDomainToken uses lifecycle endpoint and returns new token',
      () async {
    final adapter = _RecordingAdapter((options) {
      expect(options.method, 'POST');
      expect(
        options.path,
        ApiEndpoints.tenantAdminOnlineStoreDomainRotateToken('domain-1'),
      );
      return _jsonResponse({
        'data': {
          'domainId': 'domain-1',
          'domainName': 'store.example.com',
          'verificationToken': 'rotated-token',
        },
      });
    });

    final datasource = OnlineStoreRemoteDatasource(_dio(adapter));
    final token = await datasource.rotateDomainToken('domain-1');

    expect(token.verificationToken, 'rotated-token');
  });

  test('product visibility sends backend patch contract', () async {
    final adapter = _RecordingAdapter((options) {
      expect(options.method, 'PATCH');
      expect(
        options.path,
        ApiEndpoints.tenantAdminOnlineStoreCatalogProductVisibility('p-1'),
      );
      expect(options.data, {'isVisible': true});
      return _jsonResponse({
        'data': {
          'productId': 'p-1',
          'productName': 'Tea',
          'isVisible': true,
          'isOrderable': true,
          'status': 'ACTIVE',
        },
      });
    });

    final datasource = OnlineStoreRemoteDatasource(_dio(adapter));
    final dto = await datasource.updateProductVisibility(
      'p-1',
      {'isVisible': true},
    );

    expect(dto.isVisible, isTrue);
  });

  test('policy publish uses canonical policy type route', () async {
    final adapter = _RecordingAdapter((options) {
      expect(options.method, 'POST');
      expect(
        options.path,
        ApiEndpoints.tenantAdminOnlineStorePolicyPublish('COLLECTION'),
      );
      return _jsonResponse({
        'data': {
          'id': 'policy-1',
          'policyType': 'COLLECTION',
          'title': 'Collection Policy',
          'content': 'Collection terms',
          'version': 'v1',
          'status': 'PUBLISHED',
        },
      });
    });

    final datasource = OnlineStoreRemoteDatasource(_dio(adapter));
    final dto = await datasource.publishPolicy('COLLECTION');

    expect(dto.status, 'PUBLISHED');
  });
}

Dio _dio(HttpClientAdapter adapter, {String baseUrl = ''}) =>
    Dio(BaseOptions(baseUrl: baseUrl))..httpClientAdapter = adapter;

ResponseBody _jsonResponse(Map<String, Object?> body) {
  return ResponseBody.fromString(
    jsonEncode(body),
    200,
    headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    },
  );
}

class _RecordingAdapter implements HttpClientAdapter {
  _RecordingAdapter(this._handler);

  final ResponseBody Function(RequestOptions options) _handler;
  final List<RequestOptions> requests = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    return _handler(options);
  }

  @override
  void close({bool force = false}) {}
}
