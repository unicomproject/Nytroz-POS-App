import 'dart:convert';
import 'dart:developer' as developer;

import '../../../../core/storage/app_secure_storage.dart';
import '../../domain/entities/open_till.dart';

class TillSessionStorage {
  const TillSessionStorage(this._storage);

  static const _tillSessionKey = 'pos.tillSession';

  final AppSecureStorage _storage;

  Future<void> save(TillSession session) async {
    await _storage.write(
      _tillSessionKey,
      jsonEncode(session.toJson()),
    );
    developer.log(
      'Till session stored. sessionId=${session.sessionId}, status=${session.status}',
      name: 'pos.session',
    );
  }

  Future<TillSession?> read() async {
    final value = await _storage.read(_tillSessionKey);
    developer.log(
      'Till session retrieved. present=${value != null}',
      name: 'pos.session',
    );

    if (value == null || value.trim().isEmpty) {
      return null;
    }

    final decoded = jsonDecode(value);
    if (decoded is! Map<String, dynamic>) {
      return null;
    }

    final session = TillSession.fromJson(decoded);
    if (session.sessionId.trim().isEmpty || session.status != 'open') {
      return null;
    }

    return session;
  }

  Future<void> clear() async {
    await _storage.delete(_tillSessionKey);
    developer.log('Till session cleared.', name: 'pos.session');
  }
}
