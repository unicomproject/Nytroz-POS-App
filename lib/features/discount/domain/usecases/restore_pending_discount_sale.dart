import '../../data/datasources/local/pos_pending_sale_recovery_store.dart';
import '../repositories/pos_discount_repository.dart';

class RestorePendingDiscountSale {
  const RestorePendingDiscountSale(this._repository);
  final PosDiscountRepository _repository;

  Future<PosPendingSaleRecoverySnapshot?> call({
    required String tenantId,
    required String userId,
    required String deviceId,
    required String? outletId,
    required String? tillId,
    required bool hasCartItems,
  }) async {
    if (hasCartItems) return null;

    final snapshot = await _repository.loadRecoverableSale(
      tenantId: tenantId,
      userId: userId,
      deviceId: deviceId,
    );
    if (snapshot == null) return null;

    // Fail closed if outlet/till context drifted.
    if ((snapshot.outletId != null &&
            snapshot.outletId!.isNotEmpty &&
            snapshot.outletId != outletId) ||
        (snapshot.tillId != null &&
            snapshot.tillId!.isNotEmpty &&
            snapshot.tillId != tillId)) {
      return null;
    }

    final localId = snapshot.localDiscountOperationId;
    if (localId != null && localId.isNotEmpty) {
      final pending = await _repository.findPendingDiscount(localId: localId);
      if (pending == null) {
        // Outbox missing — do not restore orphan cart with fake pending discount.
        await _repository.clearRecoverableSale();
        return null;
      }
      // Ensure recovered discount retains the same idempotency key via outbox.
      if (snapshot.idempotencyKey != null &&
          snapshot.idempotencyKey != pending.idempotencyKey) {
        await _repository.clearRecoverableSale();
        return null;
      }
    }

    return snapshot;
  }
}
