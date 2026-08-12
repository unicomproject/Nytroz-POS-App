import '../../../../core/offline/offline_operation.dart';
import '../../../../core/offline/offline_outbox.dart';
import '../../../sale/domain/entities/pos_checkout_summary.dart';
import '../entities/pos_discount_api_models.dart';

abstract interface class PosDiscountRepository {
  /// Fetches available discounts and cashier authority from the backend.
  Future<PosDiscountCatalog> getDiscounts({
    required String deviceId,
    required String scope,
    String? variantId,
    List<String> variantIds = const [],
    String? customerId,
    double? quantity,
    double? cartSubtotal,
  });

  /// Caches the cashier authority and discount catalog locally.
  Future<void> cacheCatalog({
    required String deviceId,
    required PosDiscountCatalog catalog,
  });

  /// Reads the cached discount catalog if valid and unexpired.
  Future<PosDiscountCatalog?> cachedCatalog(String deviceId);

  /// Validates a discount online with the backend.
  Future<PosDiscountValidationResult> validateOnline({
    required String deviceId,
    required String scope,
    required String calculationMethod,
    required List<PosCheckoutLineRequest> lines,
    required double requestedValue,
    String? targetVariantId,
    String? reason,
    String? customerId,
  });

  /// Applies a discount online with the backend.
  Future<PosDiscountApplyResult> applyOnline({
    required String deviceId,
    String? discountId,
    required String discountSource,
    required String scope,
    required String calculationMethod,
    required List<PosCheckoutLineRequest> lines,
    required String idempotencyKey,
    double? requestedValue,
    String? targetVariantId,
    String? reason,
    String? customerId,
  });

  /// Cancels an active discount online with the backend.
  Future<void> cancelOnline({
    required String applicationId,
    required String deviceId,
    String? reason,
  });

  /// Enqueues a manual discount intent to the offline outbox.
  Future<void> enqueueManualApply({
    required String localId,
    required String idempotencyKey,
    required String deviceId,
    required String scope,
    required String calculationMethod,
    required double requestedValue,
    required List<PosCheckoutLineRequest> lines,
    required int discountAmount,
    required int totalAfterDiscount,
    String? targetVariantId,
    String? reason,
    String? customerId,
    String? cartLineKey,
    String? tenantId,
    String? userId,
    String? outletId,
    String? tillId,
    int? maxPercentageSnapshot,
    int? maxFixedAmountSnapshot,
    String? currencyCodeSnapshot,
  });

  /// Removes an offline operation from the outbox.
  Future<void> removeLocalOutbox(String localId);

  /// Persists the visible cart + pending discount state for restart recovery.
  Future<void> persistVisibleSaleForRestart({
    required String tenantId,
    required String userId,
    required String deviceId,
    required String? outletId,
    required String? tillId,
    required dynamic cart,
    required String? idempotencyKey,
    required String? localDiscountOperationId,
  });

  /// Loads a recoverable sale if tenant/user/device context matches.
  Future<dynamic> loadRecoverableSale({
    required String tenantId,
    required String userId,
    required String deviceId,
  });

  /// Clears restart recovery storage.
  Future<void> clearRecoverableSale();

  /// Finds a pending discount operation in the outbox.
  Future<OfflineOperation?> findPendingDiscount({String? localId});

  /// Processes pending outbox operations.
  Future<void> syncOutbox({
    required String operationType,
    required Future<OfflineProcessResult> Function(OfflineOperation operation)
        processor,
  });

  /// Adds a listener for connectivity wake events.
  void addConnectivityListener(Future<void> Function() listener);

  /// Reports network availability status.
  void reportOnline();
  void reportOffline();

  /// Disposes resources such as connectivity listeners.
  void dispose();
}
