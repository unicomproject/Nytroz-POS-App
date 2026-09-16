import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../storage/secure_storage_provider.dart';
import 'dio_provider.dart';

class PosDeviceProofInterceptor extends Interceptor {
  PosDeviceProofInterceptor(this.readProof, this.origin);
  final Future<String?> Function() readProof;
  final Uri origin;
  @override
  void onRequest(
      RequestOptions options, RequestInterceptorHandler handler) async {
    final uri = options.uri;
    options.headers
        .removeWhere((key, _) => key.toLowerCase() == 'x-pos-device-proof');
    if (uri.origin == origin.origin &&
        (uri.path.startsWith('/api/v1/pos/') ||
            uri.path == '/api/v1/devices/current')) {
      String? proof;
      try {
        proof = await readProof();
      } catch (_) {
        handler.reject(DioException(
          requestOptions: options,
          message:
              'Secure device credentials are unavailable. Reactivate this POS device.',
        ));
        return;
      }
      if (proof != null &&
          RegExp(r'^pos-device-v2-[0-9a-f]{64}$').hasMatch(proof)) {
        options.headers['X-Pos-Device-Proof'] = proof;
        options.followRedirects = false;
      }
    }
    handler.next(options);
  }
}

final posDeviceProofSyncProvider = Provider<void>((ref) {
  if (kIsWeb) return;
  final dio = ref.watch(appDioProvider);
  final storage = ref.watch(secureStorageProvider);
  final interceptor = PosDeviceProofInterceptor(
      () => storage.read('pos.deviceFingerprint'),
      Uri.parse(dio.options.baseUrl));
  dio.interceptors.add(interceptor);
  ref.onDispose(() => dio.interceptors.remove(interceptor));
});
