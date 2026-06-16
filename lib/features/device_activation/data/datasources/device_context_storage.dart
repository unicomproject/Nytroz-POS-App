import 'dart:convert';
import 'dart:developer' as developer;

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../domain/entities/pos_device_context.dart';
import '../device_fingerprint.dart';

class DeviceContextStorage {
  const DeviceContextStorage(this._storage);

  static const _deviceContextKey = 'pos.deviceContext';
  static const _deviceFingerprintKey = 'pos.deviceFingerprint';

  final FlutterSecureStorage _storage;

  Future<String?> readStoredDeviceFingerprint() async {
    final stored = await _storage.read(key: _deviceFingerprintKey);
    if (stored != null && stored.trim().isNotEmpty) {
      return stored.trim();
    }

    final contextValue = await _storage.read(key: _deviceContextKey);
    if (contextValue == null || contextValue.trim().isEmpty) {
      return null;
    }

    try {
      final decoded = jsonDecode(contextValue);
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
      return stored;
    }

    final fingerprint = await createStableDeviceFingerprint();

    await _storage.write(key: _deviceFingerprintKey, value: fingerprint);
    developer.log(
      'Device fingerprint created. source=stable value=$fingerprint',
      name: 'pos.session',
    );
    return fingerprint;
  }

  Future<void> save(PosDeviceContext context) async {
    await _storage.write(
      key: _deviceContextKey,
      value: jsonEncode(context.toJson()),
    );
    if (context.deviceFingerprint.trim().isNotEmpty) {
      await _storage.write(
        key: _deviceFingerprintKey,
        value: context.deviceFingerprint,
      );
    }
    developer.log(
      'Device context stored. deviceId=${context.deviceId}, tillId=${context.tillId}, trusted=${context.isTrusted}',
      name: 'pos.session',
    );
  }

  Future<PosDeviceContext?> read() async {
    final value = await _storage.read(key: _deviceContextKey);
    developer.log(
      'Device context retrieved. present=${value != null}',
      name: 'pos.session',
    );

    if (value == null || value.trim().isEmpty) {
      return null;
    }

    final decoded = jsonDecode(value);
    if (decoded is! Map<String, dynamic>) {
      return null;
    }

    final context = PosDeviceContext.fromJson(decoded);
    if (!context.isTrusted || context.deviceId.trim().isEmpty) {
      return null;
    }

    return context;
  }

  Future<void> clear() async {
    await _storage.delete(key: _deviceContextKey);
    developer.log('Device context cleared.', name: 'pos.session');
  }
}
