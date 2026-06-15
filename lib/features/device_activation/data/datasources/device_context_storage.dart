import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:math';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../domain/entities/pos_device_context.dart';

class DeviceContextStorage {
  const DeviceContextStorage(this._storage);

  static const _deviceContextKey = 'pos.deviceContext';
  static const _deviceFingerprintKey = 'pos.deviceFingerprint';

  final FlutterSecureStorage _storage;

  Future<String> readOrCreateDeviceFingerprint() async {
    final stored = await _storage.read(key: _deviceFingerprintKey);
    if (stored != null && stored.trim().isNotEmpty) {
      developer.log(
        'Device fingerprint retrieved. source=fingerprint_key',
        name: 'pos.session',
      );
      return stored;
    }

    final contextValue = await _storage.read(key: _deviceContextKey);
    if (contextValue != null && contextValue.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(contextValue);
        if (decoded is Map<String, dynamic>) {
          final context = PosDeviceContext.fromJson(decoded);
          if (context.deviceFingerprint.trim().isNotEmpty) {
            await _storage.write(
              key: _deviceFingerprintKey,
              value: context.deviceFingerprint,
            );
            developer.log(
              'Device fingerprint restored from device context.',
              name: 'pos.session',
            );
            return context.deviceFingerprint;
          }
        }
      } catch (_) {
        developer.log(
          'Stored device context could not restore fingerprint.',
          name: 'pos.session',
        );
      }
    }

    final random = Random.secure();
    final entropy = List.generate(
      16,
      (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0'),
    ).join();
    final fingerprint = 'pos-device-$entropy';

    await _storage.write(key: _deviceFingerprintKey, value: fingerprint);
    developer.log(
      'Device fingerprint created.',
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
