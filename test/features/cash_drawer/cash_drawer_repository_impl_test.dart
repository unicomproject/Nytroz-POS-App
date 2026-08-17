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
    expect(summary.currencyCode, 'USD');
  });

  test('maps cash in movement types from backend catalog', () async {
    final dio = Dio()..httpClientAdapter = _CashDrawerAdapter();
    final repository =
        CashDrawerRepositoryImpl(CashDrawerRemoteDatasource(dio));
    final types = await repository.getCashInMovementTypes();
    expect(types.map((t) => t.name), containsAll(['Float Added', 'Store Top-Up']));
    expect(types.any((t) => t.movementTypeId == 'tenant-custom-1'), isTrue);
  });

  test('create cash in posts canonical payload without client financial authority',
      () async {
    final adapter = _CashDrawerAdapter();
    final dio = Dio()..httpClientAdapter = adapter;
    final repository =
        CashDrawerRepositoryImpl(CashDrawerRemoteDatasource(dio));
    final movement = await repository.createCashInMovement(
      requestId: '00000000-0000-4000-8000-000000000001',
      deviceId: 'device-1',
      movementTypeId: 'type-float',
      amount: 250,
      note: 'Additional float',
    );
    expect(movement.id, 'backend-1');
    expect(movement.type, CashMovementType.cashIn);
    expect(movement.direction, 'IN');
    expect(movement.currencyCode, 'USD');
    expect(movement.id.startsWith('local-'), isFalse);

    final body = adapter.lastPostBody!;
    expect(body['requestId'], '00000000-0000-4000-8000-000000000001');
    expect(body['deviceId'], 'device-1');
    expect(body['movementTypeId'], 'type-float');
    expect(body['amount'], 250);
    expect(body['note'], 'Additional float');
    expect(body.containsKey('managerPin'), isFalse);
    expect(body.containsKey('tenantId'), isFalse);
    expect(body.containsKey('outletId'), isFalse);
    expect(body.containsKey('tillId'), isFalse);
    expect(body.containsKey('tillSessionId'), isFalse);
    expect(body.containsKey('currencyCode'), isFalse);
    expect(body.containsKey('currentExpectedCash'), isFalse);
    expect(body.containsKey('movementNumber'), isFalse);
  });

  test('maps cash drop OUT movement types from backend catalog', () async {
    final dio = Dio()..httpClientAdapter = _CashDrawerAdapter();
    final repository =
        CashDrawerRepositoryImpl(CashDrawerRemoteDatasource(dio));
    final types = await repository.getCashDropMovementTypes();
    expect(types.map((t) => t.name), contains('Safe Drop'));
    expect(types.every((t) => t.direction == 'OUT'), isTrue);
  });

  test('create cash drop posts canonical payload without manager PIN', () async {
    final adapter = _CashDrawerAdapter();
    final dio = Dio()..httpClientAdapter = adapter;
    final repository =
        CashDrawerRepositoryImpl(CashDrawerRemoteDatasource(dio));
    final movement = await repository.createCashDropMovement(
      requestId: '00000000-0000-4000-8000-000000000099',
      deviceId: 'device-1',
      movementTypeId: 'type-drop',
      amount: 100,
      note: 'Safe drop',
    );
    expect(movement.direction, 'OUT');
    expect(movement.type, CashMovementType.cashDrop);
    final body = adapter.lastPostBody!;
    expect(body['movementTypeId'], 'type-drop');
    expect(body.containsKey('managerPin'), isFalse);
    expect(body.containsKey('direction'), isFalse);
    expect(body.containsKey('tillSessionId'), isFalse);
  });
}

class _CashDrawerAdapter implements HttpClientAdapter {
  Map<String, dynamic>? lastPostBody;

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(RequestOptions options,
      Stream<List<int>>? requestStream, Future<void>? cancelFuture) async {
    if (options.path.contains('cash-movement-types')) {
      final direction = options.queryParameters['direction']?.toString() ?? 'IN';
      final data = direction == 'OUT'
          ? [
              {
                'movementTypeId': 'type-drop',
                'code': 'CASH_DROP',
                'name': 'Safe Drop',
                'direction': 'OUT',
                'requiresReason': false,
                'affectsExpectedCash': true,
              },
            ]
          : [
              {
                'movementTypeId': 'type-float',
                'code': 'FLOAT_ADDED',
                'name': 'Float Added',
                'direction': 'IN',
                'requiresReason': false,
                'affectsExpectedCash': true,
              },
              {
                'movementTypeId': 'tenant-custom-1',
                'code': 'STORE_TOP_UP',
                'name': 'Store Top-Up',
                'direction': 'IN',
                'requiresReason': true,
                'affectsExpectedCash': true,
              },
            ];
      return ResponseBody.fromString(jsonEncode({'data': data}), 200, headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType]
      });
    }

    if (options.method == 'POST') {
      final raw = await requestStream?.fold<List<int>>(
            <int>[],
            (previous, element) => previous..addAll(element),
          ) ??
          const <int>[];
      lastPostBody = jsonDecode(utf8.decode(raw)) as Map<String, dynamic>;
      final isDrop = lastPostBody!['movementTypeId'] == 'type-drop';
      final data = {
        'movementId': 'backend-1',
        'movementType': isDrop ? 'CASH_DROP' : 'CASH_IN',
        'direction': isDrop ? 'OUT' : 'IN',
        'amount': lastPostBody!['amount'],
        'currencyCode': 'USD',
        'reason': lastPostBody!['note'],
        'reference': null,
        'performedBy': 'Kavin',
        'performedAt': '2026-08-13T09:00:00Z',
      };
      return ResponseBody.fromString(jsonEncode({'data': data}), 200, headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType]
      });
    }

    final data = {
      'tillSessionId': 'session-1',
      'tillId': 'till-1',
      'tillName': 'Till 01',
      'status': 'OPEN',
      'currencyCode': 'USD',
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
