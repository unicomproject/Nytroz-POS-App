import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Web secure storage can throw [OperationError] when encrypted entries are
/// unreadable (origin change, private mode, stale keys). Treat as missing data.
class AppSecureStorage {
  const AppSecureStorage(this._storage);

  static Future<void> _operationQueue = Future<void>.value();

  final FlutterSecureStorage _storage;

  Future<String?> read(String key) => _runSerialized(() async {
    try {
      return await _storage.read(key: key);
    } catch (error, stackTrace) {
      _logStorageFailure('read', key, error, stackTrace);
      await _deleteSilently(key);
      return null;
    }
  });

  Future<void> write(String key, String value) => _runSerialized(() async {
    try {
      await _storage.write(key: key, value: value);
    } catch (error, stackTrace) {
      _logStorageFailure('write', key, error, stackTrace);
    }
  });

  Future<void> delete(String key) => _runSerialized(() async {
    try {
      await _storage.delete(key: key);
    } catch (error, stackTrace) {
      _logStorageFailure('delete', key, error, stackTrace);
    }
  });

  Future<void> deleteAll() => _runSerialized(() async {
    try {
      await _storage.deleteAll();
    } catch (error, stackTrace) {
      _logStorageFailure('deleteAll', '*', error, stackTrace);
    }
  });

  Future<T> _runSerialized<T>(Future<T> Function() operation) {
    final result = Completer<T>();
    _operationQueue = _operationQueue.then((_) async {
      try {
        result.complete(await operation());
      } catch (error, stackTrace) {
        result.completeError(error, stackTrace);
      }
    });
    return result.future;
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
