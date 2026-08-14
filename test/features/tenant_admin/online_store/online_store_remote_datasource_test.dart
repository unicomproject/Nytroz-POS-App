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
}

Dio _dio(HttpClientAdapter adapter) => Dio()..httpClientAdapter = adapter;

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
