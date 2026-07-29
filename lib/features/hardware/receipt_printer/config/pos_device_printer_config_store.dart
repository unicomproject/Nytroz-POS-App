import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/storage/app_secure_storage.dart';
import '../../../../core/storage/secure_storage_provider.dart';
import '../models/pos_device_printer_config.dart';

class PosDevicePrinterConfigStore {
  PosDevicePrinterConfigStore(this._storage);

  final AppSecureStorage _storage;

  static String _key(String deviceId) => 'pos.device.$deviceId.printerConfig';

  Future<PosDevicePrinterConfig?> load(String deviceId) async {
    final id = deviceId.trim();
    if (id.isEmpty) {
      return null;
    }
    final raw = await _storage.read(_key(id));
    if (raw == null || raw.trim().isEmpty) {
      return null;
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        return null;
      }
      final config = PosDevicePrinterConfig.fromJson(decoded);
      if (config.deviceId.trim().isNotEmpty && config.deviceId.trim() != id) {
        // Never load another device's hardware identifiers.
        return null;
      }
      return PosDevicePrinterConfig.fromJson({
        ...decoded,
        'deviceId': id,
      });
    } catch (_) {
      return null;
    }
  }

  Future<void> save(PosDevicePrinterConfig config) async {
    final id = config.deviceId.trim();
    if (id.isEmpty) {
      return;
    }
    await _storage.write(_key(id), jsonEncode(config.toJson()));
  }

  Future<void> clear(String deviceId) async {
    final id = deviceId.trim();
    if (id.isEmpty) {
      return;
    }
    await _storage.delete(_key(id));
  }
}

final posDevicePrinterConfigStoreProvider =
    Provider<PosDevicePrinterConfigStore>((ref) {
  return PosDevicePrinterConfigStore(ref.watch(secureStorageProvider));
});
