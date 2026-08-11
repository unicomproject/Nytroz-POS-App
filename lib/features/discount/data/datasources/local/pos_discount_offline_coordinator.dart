import 'dart:convert';

import '../../../../../core/offline/offline_connectivity_monitor.dart';
import '../../../../../core/offline/offline_operation.dart';
import '../../../../../core/offline/offline_operation_store.dart';
import '../../../../../core/offline/offline_outbox.dart';
import '../../../../../core/storage/app_secure_storage.dart';
import '../../../../cart/presentation/providers/pos_new_sale_cart_provider.dart';
import '../../../../sale/domain/entities/pos_checkout_summary.dart';
import '../../../domain/entities/pos_discount_api_models.dart';
import 'pos_pending_sale_recovery_store.dart';

class PosDiscountOfflineCoordinator {
  PosDiscountOfflineCoordinator(AppSecureStorage storage)
      : _storage = storage,
        outbox = OfflineOutbox(SecureOfflineOperationStore(storage)),
        recovery =
            PosPendingSaleRecoveryStore(SecureOfflineStringStore(storage)),
        connectivity = OfflineConnectivityMonitor();

  static const operationType = 'POS_MANUAL_DISCOUNT_APPLY';
  static const _catalogKey = 'pos.discount.authority-cache.v1';
  static const _cacheLifetime = Duration(hours: 24);

  final AppSecureStorage _storage;
  final OfflineOutbox outbox;
  final PosPendingSaleRecoveryStore recovery;
  final OfflineConnectivityMonitor connectivity;

  Future<void> remove(String localId) => outbox.remove(localId);

  Future<void> cacheCatalog({
    required String deviceId,
    required PosDiscountCatalog catalog,
  }) =>
      _storage.write(
        _catalogKey,
        jsonEncode({
          'deviceId': deviceId,
          'cachedAt': DateTime.now().toUtc().toIso8601String(),
          'catalog': catalog.toJson(),
        }),
      );

  Future<PosDiscountCatalog?> cachedCatalog(String deviceId) async {
    final raw = await _storage.read(_catalogKey);
    if (raw == null) return null;
    try {
      final json = Map<String, dynamic>.from(jsonDecode(raw) as Map);
      final cachedAt = DateTime.tryParse(json['cachedAt']?.toString() ?? '');
      if (json['deviceId'] != deviceId ||
          cachedAt == null ||
          DateTime.now().toUtc().difference(cachedAt.toUtc()) >
              _cacheLifetime) {
        return null;
      }
      return PosDiscountCatalog.fromJson(
          Map<String, dynamic>.from(json['catalog'] as Map));
    } catch (_) {
      return null;
    }
  }

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
  }) =>
      outbox.enqueue(OfflineOperation(
        localId: localId,
        type: operationType,
        idempotencyKey: idempotencyKey,
        createdAt: DateTime.now().toUtc(),
        payload: {
          'deviceId': deviceId,
          'scope': scope,
          'calculationMethod': calculationMethod,
          'requestedValue': requestedValue,
          'lines': lines.map((line) => line.toJson()).toList(),
          'discountAmount': discountAmount,
          'totalAfterDiscount': totalAfterDiscount,
          if (targetVariantId != null) 'targetVariantId': targetVariantId,
          if (reason != null && reason.trim().isNotEmpty) 'reason': reason,
          if (customerId != null) 'customerId': customerId,
          if (cartLineKey != null) 'cartLineKey': cartLineKey,
          if (tenantId != null) 'tenantId': tenantId,
          if (userId != null) 'userId': userId,
          if (outletId != null) 'outletId': outletId,
          if (tillId != null) 'tillId': tillId,
          if (maxPercentageSnapshot != null)
            'maxPercentageSnapshot': maxPercentageSnapshot,
          if (maxFixedAmountSnapshot != null)
            'maxFixedAmountSnapshot': maxFixedAmountSnapshot,
          if (currencyCodeSnapshot != null)
            'currencyCodeSnapshot': currencyCodeSnapshot,
        },
      ));

  Future<void> persistVisibleSaleForRestart({
    required String tenantId,
    required String userId,
    required String deviceId,
    required String? outletId,
    required String? tillId,
    required PosNewSaleCartState cart,
    required String? idempotencyKey,
    required String? localDiscountOperationId,
  }) =>
      recovery.save(
        tenantId: tenantId,
        userId: userId,
        deviceId: deviceId,
        outletId: outletId,
        tillId: tillId,
        cart: cart,
        idempotencyKey: idempotencyKey,
        localDiscountOperationId: localDiscountOperationId,
      );

  Future<PosPendingSaleRecoverySnapshot?> loadRecoverableSale({
    required String tenantId,
    required String userId,
    required String deviceId,
  }) =>
      recovery.loadMatching(
        tenantId: tenantId,
        userId: userId,
        deviceId: deviceId,
      );

  Future<void> clearRecoverableSale() => recovery.clear();

  Future<OfflineOperation?> findPendingDiscount({String? localId}) async {
    final pending = await outbox.pending(type: operationType);
    if (localId == null) {
      return pending.isEmpty ? null : pending.first;
    }
    for (final item in pending) {
      if (item.localId == localId) return item;
    }
    return null;
  }
}
