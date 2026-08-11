import 'package:flutter_test/flutter_test.dart';
import 'package:nytroz_pos/core/offline/offline_operation.dart';
import 'package:nytroz_pos/core/offline/offline_operation_store.dart';
import 'package:nytroz_pos/core/offline/offline_outbox.dart';

void main() {
  group('OfflineOutbox', () {
    test('deduplicates enqueue by stable idempotency key', () async {
      final store = _MemoryStore();
      final outbox = OfflineOutbox(store);
      await outbox.enqueue(_operation('one'));
      await outbox.enqueue(_operation('two'));

      expect(await outbox.pending(), hasLength(1));
      expect((await outbox.pending()).single.idempotencyKey, 'stable-key');
    });

    test('retryable failure preserves key and retry state', () async {
      final store = _MemoryStore();
      final outbox = OfflineOutbox(store);
      await outbox.enqueue(_operation('one'));
      String? processedKey;

      await outbox.sync(
        type: 'discount',
        processor: (operation) async {
          processedKey = operation.idempotencyKey;
          return const OfflineProcessResult(
            OfflineProcessOutcome.retryableFailure,
            errorCode: 'network_unavailable',
          );
        },
      );

      final failed = (await outbox.pending()).single;
      expect(processedKey, 'stable-key');
      expect(failed.status, OfflineOperationStatus.failed);
      expect(failed.retryCount, 1);
      expect(failed.lastErrorCode, 'network_unavailable');
    });

    test('success records canonical id and removes it from pending', () async {
      final store = _MemoryStore();
      final outbox = OfflineOutbox(store);
      await outbox.enqueue(_operation('one'));

      await outbox.sync(
        type: 'discount',
        processor: (_) async => const OfflineProcessResult(
          OfflineProcessOutcome.synced,
          canonicalId: 'server-application-id',
        ),
      );

      expect(await outbox.pending(), isEmpty);
      expect(store.values.single.status, OfflineOperationStatus.synced);
      expect(store.values.single.canonicalId, 'server-application-id');
    });

    test('server rejection becomes a terminal visible conflict', () async {
      final store = _MemoryStore();
      final outbox = OfflineOutbox(store);
      await outbox.enqueue(_operation('one'));

      await outbox.sync(
        type: 'discount',
        processor: (_) async => const OfflineProcessResult(
          OfflineProcessOutcome.conflict,
          errorCode: 'pos_discounts.cart_changed',
        ),
      );

      final conflict = (await outbox.pending()).single;
      expect(conflict.status, OfflineOperationStatus.conflict);
      expect(conflict.lastErrorCode, 'pos_discounts.cart_changed');
    });
  });
}

OfflineOperation _operation(String localId) => OfflineOperation(
      localId: localId,
      type: 'discount',
      idempotencyKey: 'stable-key',
      createdAt: DateTime.utc(2026, 8, 10),
      payload: const {'requestedValue': 5},
    );

class _MemoryStore implements OfflineOperationStore {
  List<OfflineOperation> values = [];

  @override
  Future<List<OfflineOperation>> readAll() async => [...values];

  @override
  Future<void> writeAll(List<OfflineOperation> operations) async {
    values = [...operations];
  }
}
