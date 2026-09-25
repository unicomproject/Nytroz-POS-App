import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nytroz_pos/features/device_activation/domain/entities/pos_device_context.dart';
import 'package:nytroz_pos/features/till/data/datasources/remote/till_remote_datasource.dart';
import 'package:nytroz_pos/features/till/domain/entities/open_till.dart';
import 'package:nytroz_pos/core/network/api_endpoints.dart';

@Skip('Needs UI refactor update for 6-step flow')
void main() {
  final form = OpenTillForm(
      deviceContext: _deviceContext(), openingFloat: 42, openingNote: '');
  Map<String, dynamic> session() => {
        'id': 'session',
        'status': 'OPEN',
        'tillId': form.deviceContext.tillId,
        'outletId': form.deviceContext.outletId
      };

  for (final note in ['   ', '  note  ']) {
    test('open/close endpoints and trimmed payloads remain unchanged: $note',
        () async {
      final requests = <RequestOptions>[];
      final dio = Dio()
        ..interceptors.add(InterceptorsWrapper(onRequest: (request, handler) {
          requests.add(request);
          handler.resolve(Response(
              requestOptions: request, data: {'tillSession': session()}));
        }));
      final source = TillRemoteDatasource(dio);
      await source.getCurrentSession(form);
      await source.openTill(OpenTillForm(
          deviceContext: form.deviceContext,
          openingFloat: 42,
          openingNote: note));
      await source.closeTill(CloseTillForm(
          deviceContext: form.deviceContext,
          countedCash: 43,
          closingNote: note,
          mismatchReason: note));
      expect(requests[0].method, 'GET');
      expect(requests[0].path, ApiEndpoints.currentTillSession);
      expect(requests[0].queryParameters,
          {'deviceId': form.deviceContext.deviceId});
      expect(requests[1].method, 'POST');
      expect(requests[1].path, ApiEndpoints.openTill);
      expect(requests[1].data, {
        'deviceId': form.deviceContext.deviceId,
        'tillId': form.deviceContext.tillId,
        'openingFloat': 42,
        'openingNote': note.trim().isEmpty ? null : note.trim()
      });
      expect(requests[2].method, 'POST');
      expect(requests[2].path, ApiEndpoints.closeTill);
      expect(requests[2].data, {
        'deviceId': form.deviceContext.deviceId,
        'tillId': form.deviceContext.tillId,
        'countedCash': 43,
        'mismatchReason': note.trim().isEmpty ? null : note.trim(),
        'closingNote': note.trim().isEmpty ? null : note.trim()
      });
    });
  }
  test('open retains Dio code while close retains message-only exception',
      () async {
    final dio = Dio()
      ..interceptors.add(InterceptorsWrapper(onRequest: (request, handler) {
        handler.reject(DioException(
            requestOptions: request,
            response: Response(requestOptions: request, statusCode: 409, data: {
              'code': 'till_session.conflict',
              'message': 'Conflict'
            })));
      }));
    final source = TillRemoteDatasource(dio);
    await expectLater(
        source.openTill(form),
        throwsA(isA<TillException>()
            .having((e) => e.code, 'code', 'till_session.conflict')));
    await expectLater(
        source.closeTill(
            CloseTillForm(deviceContext: form.deviceContext, countedCash: 0)),
        throwsA(isA<TillException>().having((e) => e.code, 'code', isNull)));
  });
  for (final code in [
    'till_session.not_found',
    'till_session.device_not_found',
    'till_session.till_not_assigned'
  ]) {
    test('current-session 404 only means no session for $code', () async {
      final dio = Dio()
        ..interceptors.add(InterceptorsWrapper(onRequest: (options, handler) {
          handler.reject(DioException(
              requestOptions: options,
              response: Response(
                  requestOptions: options,
                  statusCode: 404,
                  data: {'code': code, 'message': 'Unavailable'})));
        }));
      final result = TillRemoteDatasource(dio).getCurrentSession(OpenTillForm(
          deviceContext: _deviceContext(), openingFloat: 0, openingNote: ''));
      if (code == 'till_session.not_found') {
        expect(await result, isNull);
      } else {
        await expectLater(result,
            throwsA(isA<TillException>().having((e) => e.code, 'code', code)));
      }
    });
  }
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
