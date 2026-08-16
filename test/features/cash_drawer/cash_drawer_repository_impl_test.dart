import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nytroz_pos/features/cash_drawer/data/datasources/cash_drawer_remote_datasource.dart';
import 'package:nytroz_pos/features/cash_drawer/data/repositories/cash_drawer_repository_impl.dart';
import 'package:nytroz_pos/features/cash_drawer/domain/entities/cash_movement.dart';

void main() {
  test('maps authoritative summary response', () async {
    final dio = Dio()..httpClientAdapter = _CashDrawerAdapter();
    final repository =
        CashDrawerRepositoryImpl(CashDrawerRemoteDatasource(dio));
    final summary = await repository.getSummary('device-1');
    expect(summary.tillSessionId, 'session-1');
    expect(summary.currentExpectedCash, 1225);
    expect(summary.cashRefunds, 100);
  });

  test('create movement uses backend id instead of local fake id', () async {
    final dio = Dio()..httpClientAdapter = _CashDrawerAdapter();
    final repository =
        CashDrawerRepositoryImpl(CashDrawerRemoteDatasource(dio));
    final movement = await repository.createMovement(
      requestId: '00000000-0000-4000-8000-000000000001',
      deviceId: 'device-1',
      tillSessionId: 'session-1',
      type: CashMovementType.cashIn,
      amount: 250,
      reason: 'Float top-up',
    );
    expect(movement.id, 'backend-1');
    expect(movement.type, CashMovementType.cashIn);
    expect(movement.id.startsWith('local-'), isFalse);
  });
}

class _CashDrawerAdapter implements HttpClientAdapter {
  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(RequestOptions options,
      Stream<List<int>>? requestStream, Future<void>? cancelFuture) async {
    final data = options.method == 'POST'
        ? {
            'movementId': 'backend-1',
            'movementType': 'CASH_IN',
            'direction': 'IN',
            'amount': 250,
            'currencyCode': 'LKR',
            'reason': 'Float top-up',
            'reference': null,
            'performedBy': 'Kavin',
            'performedAt': '2026-08-13T09:00:00Z',
          }
        : {
            'tillSessionId': 'session-1',
            'tillId': 'till-1',
            'tillName': 'Till 01',
            'status': 'OPEN',
            'currencyCode': 'LKR',
            'openingCash': 1000,
            'cashSales': 500,
            'cashRefunds': 100,
            'cashIn': 50,
            'cashOut': 25,
            'cashDrops': 200,
            'currentExpectedCash': 1225,
            'openedBy': 'Kavin',
            'openedAt': '2026-08-13T08:00:00Z',
          };
    return ResponseBody.fromString(jsonEncode({'data': data}), 200, headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType]
    });
  }
}
