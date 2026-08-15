import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nytroz_pos/features/tenant_admin/inventory/data/constants/inventory_api_paths.dart';
import 'package:nytroz_pos/features/tenant_admin/inventory/data/datasources/inventory_remote_datasource.dart';
import 'package:nytroz_pos/features/tenant_admin/inventory/data/models/current_stock_dtos.dart';

void main() {
  group('InventoryRemoteDatasource', () {
    test('uses inventory base route and query parameters', () async {
      final dio = Dio();
      final adapter = _RecordingAdapter();
      dio.httpClientAdapter = adapter;

      final datasource = InventoryRemoteDatasource(dio);
      await datasource.getCurrentStock(
        const CurrentStockQueryDto(
          search: 'espresso',
          stockStatus: 'LOW_STOCK',
          page: 2,
          pageSize: 25,
        ),
      );

      expect(adapter.lastPath, InventoryApiPaths.currentStock);
      expect(adapter.lastQueryParameters?['search'], 'espresso');
      expect(adapter.lastQueryParameters?['stockStatus'], 'LOW_STOCK');
      expect(adapter.lastQueryParameters?['page'], 2);
      expect(adapter.lastQueryParameters?['pageSize'], 25);
    });

    test('parses wrapped API payload', () async {
      final dio = Dio();
      dio.httpClientAdapter = _StaticAdapter({
        'data': {
          'items': [],
          'page': 1,
          'pageSize': 50,
          'totalCount': 0,
        },
      });

      final datasource = InventoryRemoteDatasource(dio);
      final result = await datasource.getCurrentStock(
        const CurrentStockQueryDto(),
      );

      expect(result.totalCount, 0);
    });
  });
}

class _RecordingAdapter implements HttpClientAdapter {
  String? lastPath;
  Map<String, dynamic>? lastQueryParameters;

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    lastPath = options.path;
    lastQueryParameters = Map<String, dynamic>.from(options.queryParameters);

    return ResponseBody.fromString(
      '{"data":{"items":[],"page":1,"pageSize":50,"totalCount":0}}',
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }
}

class _StaticAdapter implements HttpClientAdapter {
  _StaticAdapter(this.payload);

  final Map<String, dynamic> payload;

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return ResponseBody.fromString(
      jsonEncode({'data': payload['data']}),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }
}
