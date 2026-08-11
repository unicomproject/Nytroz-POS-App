import 'dart:convert';

import '../storage/app_secure_storage.dart';
import 'offline_operation.dart';

abstract interface class OfflineOperationStore {
  Future<List<OfflineOperation>> readAll();
  Future<void> writeAll(List<OfflineOperation> operations);
}

class SecureOfflineOperationStore implements OfflineOperationStore {
  const SecureOfflineOperationStore(this._storage);

  static const storageKey = 'pos.offline.operations.v1';
  final AppSecureStorage _storage;

  @override
  Future<List<OfflineOperation>> readAll() async {
    final raw = await _storage.read(storageKey);
    if (raw == null || raw.isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      return decoded
          .whereType<Map>()
          .map((item) =>
              OfflineOperation.fromJson(Map<String, dynamic>.from(item)))
          .where((item) => item.localId.isNotEmpty)
          .toList(growable: false);
    } catch (_) {
      return const [];
    }
  }

  @override
  Future<void> writeAll(List<OfflineOperation> operations) => _storage.write(
        storageKey,
        jsonEncode(operations.map((item) => item.toJson()).toList()),
      );
}
