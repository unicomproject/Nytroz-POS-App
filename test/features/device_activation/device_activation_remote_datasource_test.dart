import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nytroz_pos/core/network/api_endpoints.dart';
import 'package:nytroz_pos/features/device_activation/data/datasources/device_activation_remote_datasource.dart';
import 'package:nytroz_pos/features/device_activation/domain/entities/pos_device_context.dart';

void main() {
  const form = DeviceActivationForm(
    activationCode: 'TILL-TEST',
    deviceName: 'Test POS',
    deviceFingerprint: 'fingerprint-test',
    deviceType: 'fixed_pos_tablet',
    platform: 'android',
    appVersion: 'dev',
  );

  for (final testCase in <({int status, String expected, String? code})>[
    (
      status: 401,
      expected: 'Your session has expired. Please sign in again.',
      code: null,
    ),
    (
      status: 403,
      expected: 'You do not have permission to activate this device.',
      code: 'device_context.permission_denied',
    ),
    (
      status: 409,
      expected: 'This activation code has already been used.',
      code: 'device_context.activation_code_used',
    ),
    (
      status: 500,
      expected: 'Device activation is temporarily unavailable. Try again.',
      code: null,
    ),
  ]) {
    test('maps ${testCase.status} activation failure safely', () async {
      final dio = Dio(BaseOptions(baseUrl: 'https://test.local'))
        ..httpClientAdapter = _ActivationAdapter(
          status: testCase.status,
          code: testCase.code,
        );
      final datasource = DeviceActivationRemoteDatasource(dio);

      await expectLater(
        datasource.activateDevice(form),
        throwsA(
          isA<DeviceActivationException>().having(
            (error) => error.message,
            'message',
            testCase.expected,
          ),
        ),
      );
    });
  }

  test('maps validation response and preserves safe API message', () async {
    final dio = Dio(BaseOptions(baseUrl: 'https://test.local'))
      ..httpClientAdapter = _ActivationAdapter(
        status: 422,
        message: 'Activation code is invalid.',
      );
    final datasource = DeviceActivationRemoteDatasource(dio);

    await expectLater(
      datasource.activateDevice(form),
      throwsA(
        isA<DeviceActivationException>().having(
          (error) => error.message,
          'message',
          'Activation code is invalid.',
        ),
      ),
    );
  });

  test('submits through canonical endpoint without logging contract changes',
      () async {
    final adapter = _ActivationAdapter(status: 200);
    final dio = Dio(BaseOptions(baseUrl: 'https://test.local'))
      ..httpClientAdapter = adapter;
    final datasource = DeviceActivationRemoteDatasource(dio);

    final result = await datasource.activateDevice(form);

    expect(adapter.lastPath, ApiEndpoints.activateDevice);
    expect(adapter.lastBody['activationCode'], form.activationCode);
    expect(result.tenantSlug, 'arenasports');
    expect(result.isTrusted, isTrue);
  });
}

class _ActivationAdapter implements HttpClientAdapter {
  _ActivationAdapter({required this.status, this.code, this.message});

  final int status;
  final String? code;
  final String? message;
  String? lastPath;
  Map<String, dynamic> lastBody = const {};

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    lastPath = options.path;
    lastBody = options.data is Map
        ? Map<String, dynamic>.from(options.data as Map)
        : const {};
    final body = status == 200
        ? {
            'data': {
              'tenantId': 'tenant-1',
              'tenantSlug': 'arenasports',
              'device': {
                'id': 'device-1',
                'deviceCode': 'POS-01',
                'deviceName': 'Test POS',
                'deviceType': 'fixed_pos_tablet',
                'platform': 'android',
                'isTrusted': true,
                'outletId': 'outlet-1',
                'tillId': 'till-1',
              },
              'outlet': {'id': 'outlet-1', 'name': 'Main Outlet'},
              'till': {'id': 'till-1', 'code': 'T01', 'name': 'Till 01'},
            },
          }
        : {
            if (code != null) 'errorCode': code,
            if (message != null) 'message': message,
          };

    return ResponseBody.fromString(
      jsonEncode(body),
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }
}
