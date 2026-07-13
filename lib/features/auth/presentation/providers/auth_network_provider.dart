import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/auth_unauthorized_interceptor.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/dio_provider.dart';
import '../../data/mappers/auth_mapper.dart';
import 'session_provider.dart';

/// Rotates tenant tokens once for concurrent 401 responses, retries each failed
/// request once, and clears the local session when refresh is rejected.
final authNetworkGuardProvider = Provider<void>((ref) {
  final dio = ref.watch(appDioProvider);

  final interceptor = AuthUnauthorizedInterceptor(
    dio: dio,
    refreshAccessToken: () async {
      final session = ref.read(authSessionProvider);
      if (session == null || !session.canRefresh) {
        return null;
      }

      final response = await dio.post<Map<String, dynamic>>(
        ApiEndpoints.tenantRefresh,
        data: {'refreshToken': session.refreshToken},
        options: Options(headers: const {'Authorization': null}),
      );
      final refreshed = authSessionFromJson(response.data ?? const {});
      await ref.read(authSessionProvider.notifier).setSession(refreshed);
      return refreshed.accessToken;
    },
    onRefreshRejected: () async {
      if (ref.read(authSessionProvider) != null) {
        await ref.read(authSessionProvider.notifier).clear();
      }
    },
  );

  dio.interceptors.add(interceptor);
  ref.onDispose(() => dio.interceptors.remove(interceptor));
});
