import 'dart:async';

import 'offline_operation.dart';
import 'offline_operation_store.dart';

enum OfflineProcessOutcome { synced, retryableFailure, conflict }

class OfflineProcessResult {
  const OfflineProcessResult(this.outcome, {this.canonicalId, this.errorCode});
  final OfflineProcessOutcome outcome;
  final String? canonicalId;
  final String? errorCode;
}

typedef OfflineOperationProcessor = Future<OfflineProcessResult> Function(
  OfflineOperation operation,
);

/// Durable, feature-neutral outbox. Processing is single-flight and always
/// reuses the operation's original idempotency key.
class OfflineOutbox {
  OfflineOutbox(this._store);
  final OfflineOperationStore _store;
  Future<void>? _activeSync;

  Future<List<OfflineOperation>> pending({String? type}) async =>
      (await _store.readAll())
          .where((item) =>
              item.status != OfflineOperationStatus.synced &&
              (type == null || item.type == type))
          .toList(growable: false);

  Future<void> enqueue(OfflineOperation operation) async {
    final operations = [...await _store.readAll()];
    final existing = operations
        .indexWhere((item) => item.idempotencyKey == operation.idempotencyKey);
    if (existing >= 0) return;
    operations.add(operation);
    await _store.writeAll(operations);
  }

  Future<void> remove(String localId) async {
    final operations = [...await _store.readAll()]
      ..removeWhere((item) => item.localId == localId);
    await _store.writeAll(operations);
  }

  Future<void> sync({
    required String type,
    required OfflineOperationProcessor processor,
  }) {
    final running = _activeSync;
    if (running != null) return running;
    final completer = Completer<void>();
    _activeSync = completer.future;
    _syncInternal(type, processor)
        .then(completer.complete)
        .catchError(
          completer.completeError,
        )
        .whenComplete(() => _activeSync = null);
    return completer.future;
  }

  Future<void> _syncInternal(
    String type,
    OfflineOperationProcessor processor,
  ) async {
    var operations = [...await _store.readAll()];
    for (var index = 0; index < operations.length; index += 1) {
      final operation = operations[index];
      if (operation.type != type ||
          operation.status == OfflineOperationStatus.synced ||
          operation.status == OfflineOperationStatus.conflict) {
        continue;
      }
      operations[index] = operation.copyWith(
        status: OfflineOperationStatus.syncing,
        retryCount: operation.retryCount + 1,
      );
      await _store.writeAll(operations);
      final result = await processor(operation);
      operations[index] = switch (result.outcome) {
        OfflineProcessOutcome.synced => operation.copyWith(
            status: OfflineOperationStatus.synced,
            retryCount: operation.retryCount + 1,
            canonicalId: result.canonicalId,
          ),
        OfflineProcessOutcome.retryableFailure => operation.copyWith(
            status: OfflineOperationStatus.failed,
            retryCount: operation.retryCount + 1,
            lastErrorCode: result.errorCode,
          ),
        OfflineProcessOutcome.conflict => operation.copyWith(
            status: OfflineOperationStatus.conflict,
            retryCount: operation.retryCount + 1,
            lastErrorCode: result.errorCode,
          ),
      };
      await _store.writeAll(operations);
      if (result.outcome == OfflineProcessOutcome.retryableFailure) break;
    }
  }
}
