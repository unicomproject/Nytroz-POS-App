import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nytroz_pos/core/network/api_endpoints.dart';
import 'package:nytroz_pos/features/pos/data/datasources/remote/pos_catalog_remote_datasource.dart';

void main() {
  test('product catalog sends exact SKU as the search query', () async {
    final adapter = _CapturingCatalogAdapter();
    final dio = Dio(BaseOptions(baseUrl: 'http://localhost'))
      ..httpClientAdapter = adapter;

    await PosCatalogRemoteDatasource(dio).getProducts(
      deviceId: 'device-1',
      search: '  MER-001-S  ',
    );

    expect(adapter.lastPath, ApiEndpoints.posProducts);
    expect(adapter.lastQuery['deviceId'], 'device-1');
    expect(adapter.lastQuery['search'], 'MER-001-S');
  });

  test('product catalog sends EAN barcode without numeric conversion',
      () async {
    final adapter = _CapturingCatalogAdapter();
    final dio = Dio(BaseOptions(baseUrl: 'http://localhost'))
      ..httpClientAdapter = adapter;

    await PosCatalogRemoteDatasource(dio).getProducts(
      deviceId: 'device-1',
      search: '2000000000114',
    );

    expect(adapter.lastQuery['search'], '2000000000114');
    expect(adapter.lastQuery['search'], isA<String>());
  });

  test('product catalog preserves SKU and barcode from API summaries',
      () async {
    final adapter = _CapturingCatalogAdapter(
      responseJson: {
        'data': [
          {
            'id': 'product-1',
            'variantId': 'variant-1',
            'name': 'Team Jersey',
            'categoryName': 'Apparel',
            'basePrice': 10000,
            'hasVariants': true,
            'stockStatus': 'IN_STOCK',
            'sku': 'MER-001-S',
            'barcode': '2000000000114',
          },
        ],
      },
    );
    final dio = Dio(BaseOptions(baseUrl: 'http://localhost'))
      ..httpClientAdapter = adapter;

    final products = await PosCatalogRemoteDatasource(dio).getProducts(
      deviceId: 'device-1',
      search: 'MER-001-S',
    );

    expect(products.single.sku, 'MER-001-S');
    expect(products.single.barcode, '2000000000114');
    expect(products.single.matches('mer-001-s'), isTrue);
    expect(products.single.matches('2000000000114'), isTrue);
  });

  test('product catalog sends segment=frequently-sold query parameter',
      () async {
    final adapter = _CapturingCatalogAdapter();
    final dio = Dio(BaseOptions(baseUrl: 'http://localhost'))
      ..httpClientAdapter = adapter;

    await PosCatalogRemoteDatasource(dio).getProducts(
      deviceId: 'device-1',
      segment: 'frequently-sold',
    );

    expect(adapter.lastPath, ApiEndpoints.posProducts);
    expect(adapter.lastQuery['deviceId'], 'device-1');
    expect(adapter.lastQuery['segment'], 'frequently-sold');
  });
}

class _CapturingCatalogAdapter implements HttpClientAdapter {
  _CapturingCatalogAdapter({Map<String, Object?>? responseJson})
      : _responseJson =
            responseJson ?? const {'data': <Map<String, Object?>>[]};

  final Map<String, Object?> _responseJson;
  String? lastPath;
  Map<String, dynamic> lastQuery = const {};

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    lastPath = options.path;
    lastQuery = Map<String, dynamic>.from(options.queryParameters);

    return ResponseBody.fromString(
      jsonEncode(_responseJson),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }
}
