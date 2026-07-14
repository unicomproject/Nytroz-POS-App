import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_provider.dart';
import '../../../../core/storage/secure_storage_provider.dart';
import '../../data/datasources/auth_session_storage.dart';
import '../../domain/entities/auth_session.dart';

class AuthSessionNotifier extends StateNotifier<AuthSession?> {
  AuthSessionNotifier(
    this._storage, {
    void Function()? onHydrated,
  })  : _onHydrated = onHydrated,
        super(null) {
    _restoreSession();
  }

  final AuthSessionStorage _storage;
  final void Function()? _onHydrated;

  Future<void> setSession(AuthSession session) async {
    state = session;
    developer.log(
      'Auth session set in memory. userId=${session.userId}, accessTokenPresent=${session.accessToken.isNotEmpty}',
      name: 'auth.session',
    );
    await _storage.save(session);
  }

  Future<void> clear() async {
    await _storage.clear();
    state = null;
  }

  Future<void> _restoreSession() async {
    try {
      final session = await _storage.read();
      if (session == null) {
        return;
      }

      state = session;
      developer.log(
        'Auth session restored into memory. userId=${session.userId}',
        name: 'auth.session',
      );
    } catch (error, stackTrace) {
      developer.log(
        'Auth session restore failed.',
        name: 'auth.session',
        error: error,
        stackTrace: stackTrace,
      );
    } finally {
      _onHydrated?.call();
    }
  }
}

final authSessionHydratedProvider = StateProvider<bool>((ref) => false);

final authSessionStorageProvider = Provider<AuthSessionStorage>((ref) {
  return AuthSessionStorage(ref.watch(secureStorageProvider));
});

final authSessionProvider =
    StateNotifierProvider<AuthSessionNotifier, AuthSession?>(
  (ref) => AuthSessionNotifier(
    ref.watch(authSessionStorageProvider),
    onHydrated: () {
      ref.read(authSessionHydratedProvider.notifier).state = true;
      developer.log(
        'Auth session hydration finished.',
        name: 'auth.session',
      );
    },
  ),
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
