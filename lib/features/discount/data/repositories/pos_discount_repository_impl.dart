import '../../../../core/offline/offline_operation.dart';
import '../../../../core/offline/offline_outbox.dart';
import '../../../sale/domain/entities/pos_checkout_summary.dart';
import '../../domain/entities/pos_discount_api_models.dart';
import '../../domain/repositories/pos_discount_repository.dart';
import '../datasources/local/pos_discount_offline_coordinator.dart';
import '../datasources/local/pos_pending_sale_recovery_store.dart';
import '../datasources/remote/pos_discount_remote_datasource.dart';

class PosDiscountRepositoryImpl implements PosDiscountRepository {
  const PosDiscountRepositoryImpl({
    required PosDiscountRemoteDatasource remoteDatasource,
    required PosDiscountOfflineCoordinator offlineCoordinator,
  })  : _remote = remoteDatasource,
        _offline = offlineCoordinator;

  final PosDiscountRemoteDatasource _remote;
  final PosDiscountOfflineCoordinator _offline;

  @override
  Future<PosDiscountCatalog> getDiscounts({
    required String deviceId,
    required String scope,
    String? variantId,
    List<String> variantIds = const [],
    String? customerId,
    double? quantity,
    double? cartSubtotal,
  }) {
    return _remote.getDiscounts(
      deviceId: deviceId,
      scope: scope,
      variantId: variantId,
      variantIds: variantIds,
      customerId: customerId,
      quantity: quantity,
      cartSubtotal: cartSubtotal,
    );
  }

  @override
  Future<void> cacheCatalog({
    required String deviceId,
    required PosDiscountCatalog catalog,
  }) {
    return _offline.cacheCatalog(deviceId: deviceId, catalog: catalog);
  }

  @override
  Future<PosDiscountCatalog?> cachedCatalog(String deviceId) {
    return _offline.cachedCatalog(deviceId);
  }

  @override
  Future<PosDiscountValidationResult> validateOnline({
    required String deviceId,
    required String scope,
    required String calculationMethod,
    required List<PosCheckoutLineRequest> lines,
    required double requestedValue,
    String? targetVariantId,
    String? reason,
    String? customerId,
  }) {
    return _remote.validate(
      deviceId: deviceId,
      scope: scope,
      calculationMethod: calculationMethod,
      lines: lines,
      requestedValue: requestedValue,
      targetVariantId: targetVariantId,
      reason: reason,
      customerId: customerId,
    );
  }

  @override
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
  }) {
    return _remote.apply(
      deviceId: deviceId,
      discountId: discountId,
      discountSource: discountSource,
      scope: scope,
      calculationMethod: calculationMethod,
      lines: lines,
      idempotencyKey: idempotencyKey,
      requestedValue: requestedValue,
      targetVariantId: targetVariantId,
      reason: reason,
      customerId: customerId,
    );
  }

  @override
  Future<void> cancelOnline({
    required String applicationId,
    required String deviceId,
    String? reason,
  }) {
    return _remote.cancel(
      applicationId: applicationId,
      deviceId: deviceId,
      reason: reason,
    );
  }

  @override
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
  }) {
    return _offline.enqueueManualApply(
      localId: localId,
      idempotencyKey: idempotencyKey,
      deviceId: deviceId,
      scope: scope,
      calculationMethod: calculationMethod,
      requestedValue: requestedValue,
      lines: lines,
      discountAmount: discountAmount,
      totalAfterDiscount: totalAfterDiscount,
      targetVariantId: targetVariantId,
      reason: reason,
      customerId: customerId,
      cartLineKey: cartLineKey,
      tenantId: tenantId,
      userId: userId,
      outletId: outletId,
      tillId: tillId,
      maxPercentageSnapshot: maxPercentageSnapshot,
      maxFixedAmountSnapshot: maxFixedAmountSnapshot,
      currencyCodeSnapshot: currencyCodeSnapshot,
    );
  }

  @override
  Future<void> removeLocalOutbox(String localId) {
    return _offline.remove(localId);
  }

  @override
  Future<void> persistVisibleSaleForRestart({
    required String tenantId,
    required String userId,
    required String deviceId,
    required String? outletId,
    required String? tillId,
    required dynamic cart,
    required String? idempotencyKey,
    required String? localDiscountOperationId,
  }) {
    return _offline.persistVisibleSaleForRestart(
      tenantId: tenantId,
      userId: userId,
      deviceId: deviceId,
      outletId: outletId,
      tillId: tillId,
      cart: cart,
      idempotencyKey: idempotencyKey,
      localDiscountOperationId: localDiscountOperationId,
    );
  }

  @override
  Future<PosPendingSaleRecoverySnapshot?> loadRecoverableSale({
    required String tenantId,
    required String userId,
    required String deviceId,
  }) {
    return _offline.loadRecoverableSale(
      tenantId: tenantId,
      userId: userId,
      deviceId: deviceId,
    );
  }

  @override
  Future<void> clearRecoverableSale() {
    return _offline.clearRecoverableSale();
  }

  @override
  Future<OfflineOperation?> findPendingDiscount({String? localId}) {
    return _offline.findPendingDiscount(localId: localId);
  }

  @override
  Future<void> syncOutbox({
    required String operationType,
    required Future<OfflineProcessResult> Function(OfflineOperation operation)
        processor,
  }) {
    return _offline.outbox.sync(
      type: operationType,
      processor: processor,
    );
  }

  @override
  void addConnectivityListener(Future<void> Function() listener) {
    _offline.connectivity.addListener(listener);
  }

  @override
  void reportOnline() {
    _offline.connectivity.reportOnline();
  }

  @override
  void reportOffline() {
    _offline.connectivity.reportOffline();
  }

  @override
  void dispose() {
    _offline.connectivity.dispose();
  }
}
