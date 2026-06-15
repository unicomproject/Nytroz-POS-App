import 'dart:convert';
import 'dart:developer' as developer;

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../domain/entities/auth_session.dart';

class AuthSessionStorage {
  const AuthSessionStorage(this._storage);

  static const _sessionKey = 'auth.session';

  final FlutterSecureStorage _storage;

  Future<void> save(AuthSession session) async {
    await _storage.write(
      key: _sessionKey,
      value: jsonEncode(session.toJson()),
    );
    developer.log(
      'Auth session stored securely. accessTokenPresent=${session.accessToken.isNotEmpty}, refreshTokenPresent=${session.refreshToken?.isNotEmpty == true}',
      name: 'auth.storage',
    );
  }

  Future<AuthSession?> read() async {
    final value = await _storage.read(key: _sessionKey);
    developer.log(
      'Auth session retrieved from secure storage. present=${value != null}',
      name: 'auth.storage',
    );

    if (value == null || value.trim().isEmpty) {
      return null;
    }

    final decoded = jsonDecode(value);
    if (decoded is! Map<String, dynamic>) {
      developer.log(
        'Stored auth session had an invalid shape.',
        name: 'auth.storage',
      );
      return null;
    }

    final session = AuthSession.fromJson(decoded);
    if (!session.isAuthenticated) {
      return null;
    }

    return session;
  }

  Future<void> clear() async {
    await _storage.delete(key: _sessionKey);
    developer.log('Auth session cleared.', name: 'auth.storage');
  }
}
