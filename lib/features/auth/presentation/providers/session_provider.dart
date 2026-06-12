import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/auth_session.dart';

class AuthSessionNotifier extends StateNotifier<AuthSession?> {
  AuthSessionNotifier() : super(null);

  void setSession(AuthSession session) {
    state = session;
  }

  void clear() {
    state = null;
  }
}

final authSessionProvider =
    StateNotifierProvider<AuthSessionNotifier, AuthSession?>(
  (ref) => AuthSessionNotifier(),
);
