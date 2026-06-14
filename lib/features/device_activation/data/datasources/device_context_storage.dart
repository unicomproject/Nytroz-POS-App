import 'dart:convert';
import 'dart:developer' as developer;

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../domain/entities/pos_device_context.dart';

class DeviceContextStorage {
  const DeviceContextStorage(this._storage);

  static const _deviceContextKey = 'pos.deviceContext';

  final FlutterSecureStorage _storage;

  Future<void> save(PosDeviceContext context) async {
    await _storage.write(
      key: _deviceContextKey,
      value: jsonEncode(context.toJson()),
    );
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
