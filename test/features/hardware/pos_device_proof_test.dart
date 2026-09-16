import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nytroz_pos/core/network/pos_device_proof_interceptor.dart';
import 'package:nytroz_pos/features/device_activation/data/device_fingerprint.dart';

void main() {
  test('device proof is high entropy and does not reuse build identity', () {
    final first = createDeviceProofFingerprint();
    expect(RegExp(r'^pos-device-v2-[0-9a-f]{64}$').hasMatch(first), isTrue);
    expect(createDeviceProofFingerprint(), isNot(first));
  });

  for (final entry in {
    '/api/v1/pos/hardware/tests': true,
    '/api/v1/devices/current': true,
    '/api/v1/tenant-admin/hardware-devices': false,
    'https://different.example/api/v1/pos/hardware/tests': false,
  }.entries) {
    test('proof is scoped to origin and runtime endpoint: ${entry.key}',
        () async {
      final proof = 'pos-device-v2-${'a' * 64}';
      final dio = Dio(BaseOptions(baseUrl: 'https://api.example'));
      dio.interceptors.add(PosDeviceProofInterceptor(
          () async => proof, Uri.parse('https://api.example')));
      dio.interceptors.add(InterceptorsWrapper(onRequest: (options, handler) {
        expect(options.headers['X-Pos-Device-Proof'],
            entry.value ? proof : isNull);
        if (entry.value) expect(options.followRedirects, isFalse);
        handler.resolve(Response(requestOptions: options, statusCode: 200));
      }));
      await dio.get(entry.key);
    });
  }
}
