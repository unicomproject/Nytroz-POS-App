import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nytroz_pos/core/network/api_endpoints.dart';
import 'package:nytroz_pos/features/cart/data/datasources/pos_discount_remote_datasource.dart';
import 'package:nytroz_pos/features/sale/domain/entities/pos_checkout_summary.dart';

void main() {
  test('manual order apply omits policy and target variant ids', () async {
    final adapter = _CapturingAdapter();
    final dio = Dio(BaseOptions(baseUrl: 'http://localhost'))
      ..httpClientAdapter = adapter;
    final datasource = PosDiscountRemoteDatasource(dio);

    await datasource.apply(
      deviceId: 'device-1',
      discountSource: 'MANUAL',
      scope: 'ORDER',
      calculationMethod: 'PERCENTAGE',
      requestedValue: 10,
      lines: const [
        PosCheckoutLineRequest(variantId: 'variant-1', quantity: 1)
      ],
      idempotencyKey: 'idem-1',
    );

    expect(adapter.lastPath, ApiEndpoints.posDiscountApply);
    expect(adapter.lastBody['discountSource'], 'MANUAL');
    expect(adapter.lastBody['scope'], 'ORDER');
    expect(adapter.lastBody, isNot(contains('discountId')));
    expect(adapter.lastBody, isNot(contains('targetVariantId')));
  });

  test('manual item apply sends backend variant id', () async {
    final adapter = _CapturingAdapter();
    final dio = Dio(BaseOptions(baseUrl: 'http://localhost'))
      ..httpClientAdapter = adapter;
    final datasource = PosDiscountRemoteDatasource(dio);

    await datasource.apply(
      deviceId: 'device-1',
      discountSource: 'MANUAL',
      scope: 'LINE',
      calculationMethod: 'FIXED_AMOUNT',
      requestedValue: 100,
      targetVariantId: 'backend-variant-1',
      lines: const [
        PosCheckoutLineRequest(variantId: 'backend-variant-1', quantity: 2),
      ],
      idempotencyKey: 'idem-2',
    );

    expect(adapter.lastBody['discountSource'], 'MANUAL');
    expect(adapter.lastBody['scope'], 'LINE');
    expect(adapter.lastBody['targetVariantId'], 'backend-variant-1');
    expect(adapter.lastBody, isNot(contains('discountId')));
  });

  test('predefined item catalog requests LINE scope and variant id', () async {
    final adapter = _CapturingAdapter(
      responseJson: {
        'data': {
          'authority': {
            'maxPercentage': 10,
            'maxFixedAmount': 1000,
            'currencyCode': 'LKR',
          },
          'discounts': <Map<String, Object?>>[],
        },
      },
    );
    final dio = Dio(BaseOptions(baseUrl: 'http://localhost'))
      ..httpClientAdapter = adapter;
    final datasource = PosDiscountRemoteDatasource(dio);

    await datasource.getDiscounts(
      deviceId: 'device-1',
      scope: 'LINE',
      variantId: 'backend-variant-1',
      quantity: 1,
      cartSubtotal: 1000,
    );

    expect(adapter.lastPath, ApiEndpoints.posDiscounts);
    expect(adapter.lastQuery['scope'], 'LINE');
    expect(adapter.lastQuery['variantId'], 'backend-variant-1');
  });
}

class _CapturingAdapter implements HttpClientAdapter {
  _CapturingAdapter({
    Map<String, Object?>? responseJson,
  }) : _responseJson = responseJson ??
            {
              'data': {
                'applicationId': 'application-1',
                'discountId': 'discount-1',
                'applied': true,
                'status': 'approved',
                'subtotal': 1000,
                'discountAmount': 100,
                'totalAfterDiscount': 900,
                'requiresManagerApproval': false,
                'cartHash': 'hash',
                'messages': <String>[],
              },
            };

  final Map<String, Object?> _responseJson;
  String? lastPath;
  Map<String, dynamic> lastBody = const {};
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
    lastBody = options.data is Map
        ? Map<String, dynamic>.from(options.data as Map)
        : const {};

    return ResponseBody.fromString(
      jsonEncode(_responseJson),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }
}
