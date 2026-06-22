import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/auth_unauthorized_interceptor.dart';
import '../../../../core/network/dio_provider.dart';
import '../../domain/entities/auth_session.dart';
import 'session_provider.dart';

/// Clears expired sessions and signs the user out when protected APIs return 401.
final authNetworkGuardProvider = Provider<void>((ref) {
  final dio = ref.watch(appDioProvider);

  final interceptor = AuthUnauthorizedInterceptor(() async {
    final session = ref.read(authSessionProvider);
    if (session == null) {
      return;
    }

    await ref.read(authSessionProvider.notifier).clear();
  });

  dio.interceptors.add(interceptor);
  ref.onDispose(() => dio.interceptors.remove(interceptor));

  Timer? expiryTimer;

  void scheduleExpiryCheck(AuthSession? session) {
    expiryTimer?.cancel();
    expiryTimer = null;

    if (session == null || !session.isAuthenticated) {
      if (session != null && session.accessToken.isNotEmpty && session.isExpired) {
        unawaited(ref.read(authSessionProvider.notifier).clear());
      }
      return;
    }

    final expiry = session.effectiveExpiresAt;
    if (expiry == null) {
      return;
    }

    final remaining = expiry.difference(DateTime.now().toUtc());
    if (remaining.isNegative) {
      unawaited(ref.read(authSessionProvider.notifier).clear());
      return;
    }

    expiryTimer = Timer(remaining, () {
      unawaited(ref.read(authSessionProvider.notifier).clear());
    });
  }

  scheduleExpiryCheck(ref.read(authSessionProvider));

  ref.listen<AuthSession?>(authSessionProvider, (previous, next) {
    scheduleExpiryCheck(next);
  });

  ref.onDispose(() => expiryTimer?.cancel());
});
