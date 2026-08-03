import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/storage/app_secure_storage.dart';
import '../../../../core/storage/secure_storage_provider.dart';
import 'drawer_operation.dart';

class DrawerOperationStore {
  DrawerOperationStore(this._storage);

  static const _key = 'pos.cash-drawer.operations.v1';
  static const _retention = Duration(days: 30);
  final AppSecureStorage _storage;
  Future<void> _writeTail = Future.value();

  Future<List<DrawerOperation>> load() async {
    final raw = await _storage.read(_key);
    if (raw == null || raw.trim().isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw) as List;
      final cutoff = DateTime.now().toUtc().subtract(_retention);
      return decoded
          .whereType<Map>()
          .map((item) => DrawerOperation.fromJson(
                item.map((key, value) => MapEntry(key.toString(), value)),
              ))
          .where((operation) =>
              operation.updatedAt.isAfter(cutoff) ||
              operation.state != DrawerOperationState.opened)
          .toList(growable: false);
    } catch (_) {
      return const [];
    }
  }

  Future<void> upsert(DrawerOperation operation) {
    final completer = _writeTail.then((_) async {
      final operations = (await load()).toList();
      final index = operations.indexWhere(
        (item) => item.operationId == operation.operationId,
      );
      if (index < 0) {
        operations.add(operation);
      } else {
        operations[index] = operation;
      }
      await _storage.write(
        _key,
        jsonEncode(operations.map((item) => item.toJson()).toList()),
      );
    });
    _writeTail = completer.catchError((_) {});
    return completer;
  }
}

final drawerOperationStoreProvider = Provider<DrawerOperationStore>(
  (ref) => DrawerOperationStore(ref.watch(secureStorageProvider)),
);
