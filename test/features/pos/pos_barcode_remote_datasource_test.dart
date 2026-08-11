import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nytroz_pos/core/network/api_endpoints.dart';
import 'package:nytroz_pos/features/pos/data/datasources/remote/pos_barcode_remote_datasource.dart';

void main() {
  test('exact barcode request preserves value, encodes path, and sends device',
      () async {
    final adapter = _BarcodeAdapter();
    final dio = Dio(BaseOptions(baseUrl: 'http://localhost'))
      ..httpClientAdapter = adapter;

    final result = await PosBarcodeRemoteDatasource(dio).getProductByBarcode(
      deviceId: 'device-1',
      barcode: '001234/ABC',
    );

    expect(adapter.path, ApiEndpoints.posProductByBarcode('001234/ABC'));
    expect(adapter.query, {'deviceId': 'device-1'});
    expect(result.barcode, '001234/ABC');
    expect(result.variantId, 'variant-1');
    expect(result.quantityPerScan, 2);
    expect(result.toResolvedSaleItem().stockStatus, 'InStock');
  });
}

class _BarcodeAdapter implements HttpClientAdapter {
  String? path;
  Map<String, dynamic>? query;

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    path = options.path;
    query = Map<String, dynamic>.from(options.queryParameters);
    final barcode = Uri.decodeComponent(options.uri.pathSegments.last);
    return ResponseBody.fromString(
      jsonEncode({
        'data': {
          'productId': 'product-1',
          'variantId': 'variant-1',
          'barcode': barcode,
          'barcodeType': 'CODE128',
          'productName': 'Team Jersey',
          'variantName': 'Blue',
          'sku': 'SKU-1',
          'quantityPerScan': 2,
          'price': 2500,
          'availableQuantity': 10,
          'stockStatus': 'in_stock',
        },
      }),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType]
      },
    );
  }
}
