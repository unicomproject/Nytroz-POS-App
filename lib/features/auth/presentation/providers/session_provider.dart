import 'dart:async';
import 'dart:developer' as developer;

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/dio_provider.dart';
import '../../../../core/storage/secure_storage_provider.dart';
import '../../data/datasources/auth_session_storage.dart';
import '../../data/mappers/auth_mapper.dart';
import '../../domain/entities/auth_session.dart';

class AuthSessionNotifier extends StateNotifier<AuthSession?> {
  AuthSessionNotifier(this._storage) : super(null) {
    _restoreSession();
  }

  final AuthSessionStorage _storage;
  Future<AuthSession?>? _refreshInFlight;

  Future<void> setSession(AuthSession session) async {
    state = session;
    developer.log(
      'Auth session set in memory. userId=${session.userId}, accessTokenPresent=${session.accessToken.isNotEmpty}',
      name: 'auth.session',
    );
    unawaited(
      _storage.save(session).catchError((Object error, StackTrace stackTrace) {
        developer.log(
          'Auth session storage failed after memory update.',
          name: 'auth.storage',
          error: error,
          stackTrace: stackTrace,
        );
      }),
    );
  }

  Future<void> clear() async {
    await _storage.clear();
    state = null;
  }

  Future<AuthSession?> ensureFreshSession(Dio dio) async {
    final current = state;
    if (current == null) {
      return null;
    }

    if (!current.isExpired) {
      dio.options.headers['Authorization'] = 'Bearer ${current.accessToken}';
      return current;
    }

    if (!current.canRefresh) {
      dio.options.headers.remove('Authorization');
      await clear();
      return null;
    }

    return _refreshInFlight ??= _refreshExpiredSession(dio, current);
  }

  Future<AuthSession?> _refreshExpiredSession(
    Dio dio,
    AuthSession expiredSession,
  ) async {
    try {
      developer.log(
        'Access token expired; refreshing before protected API call.',
        name: 'auth.session',
      );
      final response = await dio.post<Map<String, dynamic>>(
        ApiEndpoints.tenantRefresh,
        data: {'refreshToken': expiredSession.refreshToken},
        options: Options(headers: const {'Authorization': null}),
      );
      final refreshed = authSessionFromJson(response.data ?? const {});
      await setSession(refreshed);
      dio.options.headers['Authorization'] = 'Bearer ${refreshed.accessToken}';
      return refreshed;
    } on DioException catch (error, stackTrace) {
      developer.log(
        'Access token refresh failed. status=${error.response?.statusCode ?? 'none'}',
        name: 'auth.session',
        error: error,
        stackTrace: stackTrace,
      );
      if (_isRefreshRejected(error.response?.statusCode)) {
        dio.options.headers.remove('Authorization');
        await clear();
      }
      return null;
    } catch (error, stackTrace) {
      developer.log(
        'Access token refresh failed unexpectedly.',
        name: 'auth.session',
        error: error,
        stackTrace: stackTrace,
      );
      return null;
    } finally {
      _refreshInFlight = null;
    }
  }

  Future<void> _restoreSession() async {
    final session = await _storage.read();
    if (session == null) {
      return;
    }

    state = session;
    developer.log(
      'Auth session restored into memory. userId=${session.userId}',
      name: 'auth.session',
    );
  }
}

final authSessionStorageProvider = Provider<AuthSessionStorage>((ref) {
  return AuthSessionStorage(ref.watch(secureStorageProvider));
});

final authSessionProvider =
    StateNotifierProvider<AuthSessionNotifier, AuthSession?>(
  (ref) => AuthSessionNotifier(ref.watch(authSessionStorageProvider)),
);

final authHeaderSyncProvider = Provider<void>((ref) {
  final dio = ref.watch(appDioProvider);

  void applyHeader(AuthSession? session) {
    if (session == null || !session.isAuthenticated) {
      dio.options.headers.remove('Authorization');
      developer.log(
        'Authorization header removed.',
        name: 'auth.network',
      );
      return;
    }

    dio.options.headers['Authorization'] = 'Bearer ${session.accessToken}';
    developer.log(
      'Authorization Bearer token attached to Dio defaults.',
      name: 'auth.network',
    );
  }

  applyHeader(ref.read(authSessionProvider));

  ref.listen<AuthSession?>(authSessionProvider, (previous, next) {
    applyHeader(next);
  });
});

bool _isRefreshRejected(int? statusCode) =>
    statusCode == 400 || statusCode == 401 || statusCode == 403;
