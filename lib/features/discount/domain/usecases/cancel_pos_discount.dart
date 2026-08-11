import '../entities/pos_cart_discount.dart';
import '../repositories/pos_discount_repository.dart';

class CancelPosDiscount {
  const CancelPosDiscount(this._repository);
  final PosDiscountRepository _repository;

  Future<void> call({
    required PosCartDiscount discount,
    required String? deviceId,
  }) async {
    final applicationId = discount.applicationId;
    if (applicationId == null) return;

    if (discount.isPendingSync && applicationId.startsWith('local:')) {
      await _repository
          .removeLocalOutbox(applicationId.substring('local:'.length));
      await _repository.clearRecoverableSale();
      return;
    }

    if (discount.isSyncConflict && applicationId.startsWith('local:')) {
      await _repository
          .removeLocalOutbox(applicationId.substring('local:'.length));
      await _repository.clearRecoverableSale();
      return;
    }

    if (deviceId == null) {
      throw StateError('POS device context is not ready.');
    }

    await _repository.cancelOnline(
      applicationId: applicationId,
      deviceId: deviceId,
      reason: 'Removed from POS cart',
    );
  }
}
