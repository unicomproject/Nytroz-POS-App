import 'dart:convert';
import 'dart:developer' as developer;

import 'package:flutter/foundation.dart' show kIsWeb;

import '../../../../core/storage/app_secure_storage.dart';
import '../../../../core/storage/platform_local_storage.dart';
import '../../domain/entities/pos_device_context.dart';
import '../device_fingerprint.dart';

class DeviceContextStorage {
  const DeviceContextStorage(this._storage);

  static const _deviceContextKey = 'pos.deviceContext';
  static const _deviceFingerprintKey = 'pos.deviceFingerprint';

  final AppSecureStorage _storage;

  Future<String?> readStoredDeviceFingerprint() async {
    final secure = await _readFingerprintFromSecureStorage();
    if (secure != null) {
      return secure;
    }

    return _readFingerprintFromLocalStorage();
  }

  Future<List<String>> readDeviceFingerprintCandidates() async {
    final stored = await readStoredDeviceFingerprint();
    final stable = await createStableDeviceFingerprint();
    final legacy = legacyDeviceFingerprint();

    return uniqueFingerprints([
      if (stored != null) stored,
      stable,
      if (legacy.isNotEmpty) legacy,
    ]);
  }

  Future<String> readOrCreateDeviceFingerprint() async {
    final stored = await readStoredDeviceFingerprint();
    if (stored != null) {
      developer.log(
        'Device fingerprint retrieved. source=storage value=$stored',
        name: 'pos.session',
      );
      await _persistFingerprint(stored);
      return stored;
    }

    final fingerprint = await createStableDeviceFingerprint();

    await _persistFingerprint(fingerprint);
    developer.log(
      'Device fingerprint created. source=stable value=$fingerprint',
      name: 'pos.session',
    );
    return fingerprint;
  }

  Future<void> save(PosDeviceContext context) async {
    final encoded = jsonEncode(context.toJson());
    await _storage.write(_deviceContextKey, encoded);
    if (kIsWeb) {
      await PlatformLocalStorage.write(_deviceContextKey, encoded);
    }

    if (context.deviceFingerprint.trim().isNotEmpty) {
      await _persistFingerprint(context.deviceFingerprint);
    }

    developer.log(
      'Device context stored. deviceId=${context.deviceId}, tillId=${context.tillId}, trusted=${context.isTrusted}',
      name: 'pos.session',
    );
  }

  Future<PosDeviceContext?> read() async {
    final secureContext = await _readContextFromSecureStorage();
    if (secureContext != null) {
      return secureContext;
    }

    return _readContextFromLocalStorage();
  }

  Future<void> clear() async {
    await _storage.delete(_deviceContextKey);
    await _storage.delete(_deviceFingerprintKey);
    if (kIsWeb) {
      await PlatformLocalStorage.delete(_deviceContextKey);
      await PlatformLocalStorage.delete(_deviceFingerprintKey);
    }
    developer.log('Device context cleared.', name: 'pos.session');
  }

  Future<void> _persistFingerprint(String fingerprint) async {
    final trimmed = fingerprint.trim();
    if (trimmed.isEmpty) {
      return;
    }

    await _storage.write(_deviceFingerprintKey, trimmed);
    if (kIsWeb) {
      await PlatformLocalStorage.write(_deviceFingerprintKey, trimmed);
    }
  }

  Future<String?> _readFingerprintFromSecureStorage() async {
    final stored = await _storage.read(_deviceFingerprintKey);
    if (stored != null && stored.trim().isNotEmpty) {
      return stored.trim();
    }

    final contextValue = await _storage.read(_deviceContextKey);
    if (contextValue == null || contextValue.trim().isEmpty) {
      return null;
    }

    return _fingerprintFromEncodedContext(contextValue);
  }

  Future<String?> _readFingerprintFromLocalStorage() async {
    if (!kIsWeb) {
      return null;
    }

    final stored = await PlatformLocalStorage.read(_deviceFingerprintKey);
    if (stored != null && stored.trim().isNotEmpty) {
      return stored.trim();
    }

    final contextValue = await PlatformLocalStorage.read(_deviceContextKey);
    if (contextValue == null || contextValue.trim().isEmpty) {
      return null;
    }

    return _fingerprintFromEncodedContext(contextValue);
  }

  Future<PosDeviceContext?> _readContextFromSecureStorage() async {
    final value = await _storage.read(_deviceContextKey);
    developer.log(
      'Device context retrieved from secure storage. present=${value != null}',
      name: 'pos.session',
    );

    return _trustedContextFromEncoded(value);
  }

  Future<PosDeviceContext?> _readContextFromLocalStorage() async {
    if (!kIsWeb) {
      return null;
    }

    final value = await PlatformLocalStorage.read(_deviceContextKey);
    developer.log(
      'Device context retrieved from local storage. present=${value != null}',
      name: 'pos.session',
    );

    return _trustedContextFromEncoded(value);
  }

  String? _fingerprintFromEncodedContext(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }

    try {
      final decoded = jsonDecode(value);
      if (decoded is Map<String, dynamic>) {
        final fingerprint =
            PosDeviceContext.fromJson(decoded).deviceFingerprint.trim();
        if (fingerprint.isNotEmpty) {
          return fingerprint;
        }
      }
    } catch (_) {
      return null;
    }

    return null;
  }

  PosDeviceContext? _trustedContextFromEncoded(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }

    try {
      final decoded = jsonDecode(value);
      if (decoded is! Map<String, dynamic>) {
        return null;
      }

      final context = PosDeviceContext.fromJson(decoded);
      if (!context.isTrusted || context.deviceId.trim().isEmpty) {
        return null;
      }

      return context;
    } catch (_) {
      return null;
    }
  }
}
