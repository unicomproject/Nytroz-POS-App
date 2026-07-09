import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Web secure storage can throw [OperationError] when encrypted entries are
/// unreadable (origin change, private mode, stale keys). Treat as missing data.
class AppSecureStorage {
  const AppSecureStorage(this._storage);

  final FlutterSecureStorage _storage;

  Future<String?> read(String key) async {
    try {
      return await _storage.read(key: key);
    } catch (error, stackTrace) {
      _logStorageFailure('read', key, error, stackTrace);
      await _deleteSilently(key);
      return null;
    }
  }

  Future<void> write(String key, String value) async {
    try {
      await _storage.write(key: key, value: value);
    } catch (error, stackTrace) {
      _logStorageFailure('write', key, error, stackTrace);
    }
  }

  Future<void> delete(String key) async {
    try {
      await _storage.delete(key: key);
    } catch (error, stackTrace) {
      _logStorageFailure('delete', key, error, stackTrace);
    }
  }

  Future<void> deleteAll() async {
    try {
      await _storage.deleteAll();
    } catch (error, stackTrace) {
      _logStorageFailure('deleteAll', '*', error, stackTrace);
    }
  }

  Future<void> _deleteSilently(String key) async {
    try {
      await _storage.delete(key: key);
    } catch (_) {
      // Ignore cleanup failures for corrupt entries.
    }
  }

  void _logStorageFailure(
    String operation,
    String key,
    Object error,
    StackTrace stackTrace,
  ) {
    assert(() {
      // ignore: avoid_print
      print(
        'Secure storage $operation failed for key=$key on ${kIsWeb ? 'web' : 'native'}: $error',
      );
      return true;
    }());
  }
}
