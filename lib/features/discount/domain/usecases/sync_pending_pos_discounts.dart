import '../../../../core/offline/offline_outbox.dart';
import '../../../cart/presentation/providers/pos_new_sale_cart_provider.dart';
import '../../../sale/domain/entities/pos_checkout_api_exception.dart';
import '../../data/datasources/local/pos_discount_offline_coordinator.dart';
import '../../data/dtos/pos_discount_dtos.dart';
import '../entities/pos_cart_discount.dart';
import '../repositories/pos_discount_repository.dart';

class SyncPendingPosDiscounts {
  const SyncPendingPosDiscounts(this._repository);
  final PosDiscountRepository _repository;

  Future<void> call({
    required PosNewSaleCartState Function() getCurrentCart,
    required void Function(String localId, String status) onMarkLocalStatus,
    required void Function(PosCartDiscount canonical, String? cartLineKey)
        onApplyCanonical,
    required void Function() onSyncCompleted,
  }) async {
    await _repository.syncOutbox(
      operationType: PosDiscountOfflineCoordinator.operationType,
      processor: (operation) async {
        final payload = operation.payload;
        try {
          final result = await _repository.applyOnline(
            deviceId: payload['deviceId']?.toString() ?? '',
            discountSource: 'MANUAL',
            scope: payload['scope']?.toString() ?? 'ORDER',
            calculationMethod:
                payload['calculationMethod']?.toString() ?? 'PERCENTAGE',
            lines: PosDiscountLineMapper.linesFromJson(payload['lines']),
            idempotencyKey: operation.idempotencyKey,
            requestedValue: (payload['requestedValue'] as num?)?.toDouble(),
            targetVariantId: payload['targetVariantId']?.toString(),
            reason: payload['reason']?.toString(),
            customerId: payload['customerId']?.toString(),
          );

          if (!result.applied || result.applicationId.isEmpty) {
            onMarkLocalStatus(operation.localId, 'conflict');
            return const OfflineProcessResult(
              OfflineProcessOutcome.conflict,
              errorCode: 'pos_discounts.rejected_after_sync',
            );
          }

          final cart = getCurrentCart();
          final current = cart.cartDiscount ??
              cart.items.values
                  .map((item) => item.discount)
                  .whereType<PosCartDiscount>()
                  .firstOrNull;

          if (current?.applicationId == 'local:${operation.localId}') {
            final canonical = PosCartDiscount(
              valueType: payload['calculationMethod'] == 'FIXED_AMOUNT'
                  ? PosDiscountValueType.fixedAmount
                  : PosDiscountValueType.percentage,
              value: (payload['requestedValue'] as num).toDouble(),
              reason: payload['reason']?.toString(),
              applicationId: result.applicationId,
              status: result.status,
              cartHash: result.cartHash,
              scope: payload['scope']?.toString() ?? 'ORDER',
              targetVariantId: payload['targetVariantId']?.toString(),
              discountAmount: result.discountAmount,
              totalAfterDiscount: result.totalAfterDiscount,
            );
            final lineKey = payload['cartLineKey']?.toString();
            onApplyCanonical(canonical, lineKey);
            onSyncCompleted();
          }

          await _repository.clearRecoverableSale();
          _repository.reportOnline();
          return OfflineProcessResult(
            OfflineProcessOutcome.synced,
            canonicalId: result.applicationId,
          );
        } on PosCheckoutApiException catch (error) {
          if (error.isNetworkUnavailable) {
            _repository.reportOffline();
            return OfflineProcessResult(
              OfflineProcessOutcome.retryableFailure,
              errorCode: error.code ?? 'network_unavailable',
            );
          }
          onMarkLocalStatus(operation.localId, 'conflict');
          return OfflineProcessResult(
            OfflineProcessOutcome.conflict,
            errorCode: error.code ?? 'server_rejected',
          );
        }
      },
    );
  }
}
