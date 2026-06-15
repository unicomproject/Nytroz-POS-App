import 'dart:developer' as developer;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_provider.dart';
import '../../../../core/storage/secure_storage_provider.dart';
import '../../data/datasources/auth_session_storage.dart';
import '../../domain/entities/auth_session.dart';

class AuthSessionNotifier extends StateNotifier<AuthSession?> {
  AuthSessionNotifier(this._storage) : super(null) {
    _restoreSession();
  }

  final AuthSessionStorage _storage;

  Future<void> setSession(AuthSession session) async {
    await _storage.save(session);
    state = session;
    developer.log(
      'Auth session set in memory. userId=${session.userId}, accessTokenPresent=${session.accessToken.isNotEmpty}',
      name: 'auth.session',
    );
  }

  Future<void> clear() async {
    await _storage.clear();
    state = null;
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

  ref.listen<AuthSession?>(authSessionProvider, (previous, next) {
    if (next == null || !next.isAuthenticated) {
      dio.options.headers.remove('Authorization');
      developer.log(
        'Authorization header removed.',
        name: 'auth.network',
      );
      return;
    }

    dio.options.headers['Authorization'] = 'Bearer ${next.accessToken}';
    developer.log(
      'Authorization Bearer token attached to Dio defaults.',
      name: 'auth.network',
    );
  });
});
