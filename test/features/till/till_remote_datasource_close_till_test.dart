import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nytroz_pos/features/device_activation/domain/entities/pos_device_context.dart';
import 'package:nytroz_pos/features/till/data/datasources/till_remote_datasource.dart';
import 'package:nytroz_pos/features/till/domain/entities/open_till.dart';

void main() {
  test('closeTill request contains only backend-supported fields', () async {
    Map<String, dynamic>? capturedPayload;
    final dio = Dio(
      BaseOptions(baseUrl: 'http://localhost'),
    )..interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            capturedPayload = Map<String, dynamic>.from(options.data as Map);
            handler.resolve(
              Response<Map<String, dynamic>>(
                requestOptions: options,
                statusCode: 200,
                data: {
                  'data': {
                    'tillSession': {
                      'id': 'session-1',
                      'outletId': 'outlet-1',
                      'tillId': 'till-1',
                      'openingFloat': 0,
                      'expectedCash': 100,
                      'countedCash': 90,
                      'cashDifference': -10,
                      'status': 'closed',
                      'openedAt': '2026-07-13T08:00:00Z',
                      'closedAt': '2026-07-13T10:00:00Z',
                      'closingNote': 'End of shift',
                    },
                  },
                },
              ),
            );
          },
        ),
      );
    final datasource = TillRemoteDatasource(dio);

    final result = await datasource.closeTill(
      CloseTillForm(
        deviceContext: _deviceContext(),
        countedCash: 90,
        mismatchReason: 'Cash short',
        closingNote: 'End of shift',
      ),
    );

    expect(capturedPayload, isNotNull);
    expect(capturedPayload!.keys.toSet(), {
      'deviceId',
      'tillId',
      'countedCash',
      'mismatchReason',
      'closingNote',
    });
    expect(capturedPayload!.containsKey('managerPin'), isFalse);
    expect(capturedPayload!.containsKey('pin'), isFalse);
    expect(capturedPayload!.containsKey('expectedCash'), isFalse);
    expect(result.outletId, 'outlet-1');
  });

  test('current session maps backend financial and display fields', () async {
    final dio = Dio(BaseOptions(baseUrl: 'http://localhost'))
      ..interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) => handler.resolve(
            Response<Map<String, dynamic>>(
              requestOptions: options,
              statusCode: 200,
              data: {
                'data': {
                  'tillSession': {
                    'id': 'session-1',
                    'outletId': 'outlet-1',
                    'tillId': 'till-1',
                    'openedDeviceId': 'device-1',
                    'openingFloat': 25,
                    'expectedCash': 125,
                    'currencyCode': 'USD',
                    'tillName': 'Backend Till',
                    'openedByName': 'Backend Cashier',
                    'status': 'open',
                    'openedAt': '2026-07-13T08:00:00Z',
                  },
                },
              },
            ),
          ),
        ),
      );

    final result = await TillRemoteDatasource(dio).getCurrentSession(
      OpenTillForm(
        deviceContext: _deviceContext(),
        openingFloat: 0,
        openingNote: '',
      ),
    );

    expect(result, isNotNull);
    expect(result!.currencyCode, 'USD');
    expect(result.expectedCash, 125);
    expect(result.tillName, 'Backend Till');
    expect(result.openedByName, 'Backend Cashier');
  });
}

PosDeviceContext _deviceContext() {
  return PosDeviceContext(
    deviceId: 'device-1',
    deviceCode: 'POS-01',
    deviceName: 'Front POS',
    deviceType: 'fixed_pos_tablet',
    platform: 'web',
    deviceFingerprint: 'pos-web-test',
    isTrusted: true,
    tenantId: 'tenant-1',
    outletId: 'outlet-1',
    outletName: 'Main Outlet',
    tillId: 'till-1',
    tillCode: 'FRONT-01',
    tillName: 'Front Till',
    pairedAt: DateTime.utc(2026, 7, 13),
  );
}
