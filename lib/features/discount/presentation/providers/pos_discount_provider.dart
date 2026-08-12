import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_provider.dart';
import '../../../../core/storage/secure_storage_provider.dart';
import '../../../auth/presentation/providers/session_provider.dart';
import '../../../cart/presentation/providers/pos_new_sale_cart_provider.dart';
import '../../../device_activation/presentation/providers/device_activation_provider.dart';
import '../../../sale/presentation/providers/pos_checkout_summary_provider.dart';
import '../../data/datasources/local/pos_discount_offline_coordinator.dart';
import '../../data/datasources/local/pos_pending_sale_recovery_store.dart';
import '../../data/datasources/remote/pos_discount_remote_datasource.dart';
import '../../data/repositories/pos_discount_repository_impl.dart';
import '../../domain/entities/pos_cart_discount.dart';
import '../../domain/entities/pos_discount_api_models.dart';
import '../../domain/repositories/pos_discount_repository.dart';
import '../../domain/usecases/apply_pos_discount.dart';
import '../../domain/usecases/cancel_pos_discount.dart';
import '../../domain/usecases/rebind_discount_after_customer_change.dart';
import '../../domain/usecases/restore_pending_discount_sale.dart';
import '../../domain/usecases/sync_pending_pos_discounts.dart';
import '../../domain/usecases/validate_pos_discount.dart';
import '../utils/pos_discount_error_mapper.dart';

export '../utils/pos_discount_error_mapper.dart';
export 'pos_discount_catalog_provider.dart';

// --- DATA SOURCE & REPOSITORY PROVIDERS ---

final posDiscountRemoteDatasourceProvider =
    Provider<PosDiscountRemoteDatasource>(
  (ref) => PosDiscountRemoteDatasource(ref.watch(appDioProvider)),
);

final posDiscountOfflineCoordinatorProvider =
    Provider<PosDiscountOfflineCoordinator>((ref) {
  final coordinator =
      PosDiscountOfflineCoordinator(ref.watch(secureStorageProvider));
  ref.onDispose(coordinator.connectivity.dispose);
  return coordinator;
});

final posDiscountRepositoryProvider = Provider<PosDiscountRepository>((ref) {
  final repo = PosDiscountRepositoryImpl(
    remoteDatasource: ref.watch(posDiscountRemoteDatasourceProvider),
    offlineCoordinator: ref.watch(posDiscountOfflineCoordinatorProvider),
  );
  ref.onDispose(repo.dispose);
  return repo;
});

// --- USE CASE PROVIDERS ---

final validatePosDiscountUseCaseProvider = Provider<ValidatePosDiscount>((ref) {
  return ValidatePosDiscount(ref.watch(posDiscountRepositoryProvider));
});

final applyPosDiscountUseCaseProvider = Provider<ApplyPosDiscount>((ref) {
  return ApplyPosDiscount(ref.watch(posDiscountRepositoryProvider));
});

final cancelPosDiscountUseCaseProvider = Provider<CancelPosDiscount>((ref) {
  return CancelPosDiscount(ref.watch(posDiscountRepositoryProvider));
});

final rebindDiscountAfterCustomerChangeUseCaseProvider =
    Provider<RebindDiscountAfterCustomerChange>((ref) {
  return RebindDiscountAfterCustomerChange(
      ref.watch(posDiscountRepositoryProvider));
});

final syncPendingPosDiscountsUseCaseProvider =
    Provider<SyncPendingPosDiscounts>((ref) {
  return SyncPendingPosDiscounts(ref.watch(posDiscountRepositoryProvider));
});

final restorePendingDiscountSaleUseCaseProvider =
    Provider<RestorePendingDiscountSale>((ref) {
  return RestorePendingDiscountSale(ref.watch(posDiscountRepositoryProvider));
});

// --- PRESENTATION-FACING OPERATIONS ---

Future<PosDiscountApplyResult> applyPosDiscount({
  required WidgetRef ref,
  PosDiscountPolicy? policy,
  required PosDiscountValueType valueType,
  required double value,
  required bool isLineDiscount,
  String? targetVariantId,
  String? reason,
  bool predefined = false,
  String? cartLineKey,
  String? idempotencyKey,
}) async {
  final device = ref.read(deviceActivationProvider).deviceContext;
  final cart = ref.read(posNewSaleCartProvider);
  if (device == null) throw StateError('POS device context is not ready.');
  final session = ref.read(authSessionProvider);

  final key =
      idempotencyKey ?? createPosDiscountIdempotencyKey(device.deviceId);
  final useCase = ref.read(applyPosDiscountUseCaseProvider);

  final result = await useCase(
    deviceId: device.deviceId,
    currencyCode: device.currencyCode,
    cart: cart,
    policy: policy,
    valueType: valueType,
    value: value,
    isLineDiscount: isLineDiscount,
    targetVariantId: targetVariantId,
    reason: reason,
    predefined: predefined,
    cartLineKey: cartLineKey,
    idempotencyKey: key,
    tenantId: device.tenantId,
    userId: session?.userId,
    outletId: device.outletId,
    tillId: device.tillId,
  );

  if (result.applied || result.requiresManagerApproval) {
    final discount = PosCartDiscount(
      valueType: valueType,
      value: value,
      reason: reason,
      policyId: policy?.id,
      applicationId: result.applicationId,
      status: result.status,
      cartHash: result.cartHash,
      source: predefined ? 'POLICY' : 'MANUAL',
      scope: isLineDiscount ? 'LINE' : 'ORDER',
      targetVariantId: targetVariantId,
      discountAmount: result.discountAmount,
      totalAfterDiscount: result.totalAfterDiscount,
      currencyCode: device.currencyCode,
    );
    final notifier = ref.read(posNewSaleCartProvider.notifier);
    if (isLineDiscount && cartLineKey != null) {
      notifier.applyItemDiscount(cartLineKey: cartLineKey, discount: discount);
    } else {
      notifier.applyCartDiscount(discount);
    }
    ref.invalidate(posCheckoutSummaryProvider);

    if (discount.isPendingSync) {
      final localId = discount.applicationId?.startsWith('local:') == true
          ? discount.applicationId!.substring('local:'.length)
          : null;
      if (session != null) {
        await ref
            .read(posDiscountRepositoryProvider)
            .persistVisibleSaleForRestart(
              tenantId: device.tenantId,
              userId: session.userId,
              deviceId: device.deviceId,
              outletId: device.outletId,
              tillId: device.tillId,
              cart: ref.read(posNewSaleCartProvider),
              idempotencyKey: key,
              localDiscountOperationId: localId,
            );
      }
    }
  }
  return result;
}

Future<PosDiscountValidationResult> validatePosDiscount({
  required Ref ref,
  required PosDiscountValueType valueType,
  required double value,
  required bool isLineDiscount,
  String? targetVariantId,
  String? reason,
}) async {
  final device = ref.read(deviceActivationProvider).deviceContext;
  final cart = ref.read(posNewSaleCartProvider);
  if (device == null) throw StateError('POS device context is not ready.');

  return ref.read(validatePosDiscountUseCaseProvider)(
    deviceId: device.deviceId,
    currencyCode: device.currencyCode,
    cart: cart,
    valueType: valueType,
    value: value,
    isLineDiscount: isLineDiscount,
    targetVariantId: targetVariantId,
    reason: reason,
    customerId: cart.selectedCustomer?.customerId,
  );
}

Future<void> cancelPosDiscount({
  required WidgetRef ref,
  required PosCartDiscount discount,
}) async {
  final device = ref.read(deviceActivationProvider).deviceContext;
  await ref.read(cancelPosDiscountUseCaseProvider)(
    discount: discount,
    deviceId: device?.deviceId,
  );
}

Future<String?> rebindPosDiscountsAfterCustomerChange({
  required T Function<T>(ProviderListenable<T> provider) read,
  required void Function(ProviderOrFamily provider) invalidate,
}) async {
  final cart = read(posNewSaleCartProvider);
  final deviceContext = read(deviceActivationProvider).deviceContext;
  final cartNotifier = read(posNewSaleCartProvider.notifier);
  final useCase = read(rebindDiscountAfterCustomerChangeUseCaseProvider);

  final error = await useCase(
    currentCart: cart,
    deviceContext: deviceContext,
    cartNotifier: cartNotifier,
    createIdempotencyKey: createPosDiscountIdempotencyKey,
    formatErrorMessage: safePosDiscountErrorMessage,
  );

  invalidate(posCheckoutSummaryProvider);
  return error;
}

Future<void> syncPendingPosDiscounts({required WidgetRef ref}) async {
  final useCase = ref.read(syncPendingPosDiscountsUseCaseProvider);
  await useCase(
    getCurrentCart: () => ref.read(posNewSaleCartProvider),
    onMarkLocalStatus: (localId, status) {
      _markLocalDiscountStatus(
        ref: ref,
        localId: localId,
        status: status,
      );
    },
    onApplyCanonical: (canonical, lineKey) {
      if (lineKey != null && lineKey.isNotEmpty) {
        ref.read(posNewSaleCartProvider.notifier).applyItemDiscount(
              cartLineKey: lineKey,
              discount: canonical,
            );
      } else {
        ref.read(posNewSaleCartProvider.notifier).applyCartDiscount(canonical);
      }
    },
    onSyncCompleted: () {
      ref.invalidate(posCheckoutSummaryProvider);
    },
  );
}

Future<PosPendingSaleRecoverySnapshot?> restoreRecoverablePendingSale({
  required WidgetRef ref,
}) async {
  final device = ref.read(deviceActivationProvider).deviceContext;
  final session = ref.read(authSessionProvider);
  if (device == null || session == null) return null;

  final useCase = ref.read(restorePendingDiscountSaleUseCaseProvider);
  final snapshot = await useCase(
    tenantId: device.tenantId,
    userId: session.userId,
    deviceId: device.deviceId,
    outletId: device.outletId,
    tillId: device.tillId,
    hasCartItems: ref.read(posNewSaleCartProvider).hasItems,
  );

  if (snapshot != null) {
    ref
        .read(posNewSaleCartProvider.notifier)
        .restoreRecoveredSale(snapshot.cart);
  }
  return snapshot;
}

void ensureDiscountOutboxConnectivityWake({required WidgetRef ref}) {
  final repo = ref.read(posDiscountRepositoryProvider);
  Future<void> wake() => syncPendingPosDiscounts(ref: ref);
  if (!_discountWakeRegistered.contains(repo)) {
    repo.addConnectivityListener(wake);
    _discountWakeRegistered.add(repo);
  }
}

final Set<PosDiscountRepository> _discountWakeRegistered = {};

bool isBoundPosDiscount(PosCartDiscount discount) =>
    RebindDiscountAfterCustomerChange.isBoundPosDiscount(discount);

void _markLocalDiscountStatus({
  required WidgetRef ref,
  required String localId,
  required String status,
}) {
  final cart = ref.read(posNewSaleCartProvider);
  final notifier = ref.read(posNewSaleCartProvider.notifier);
  final localApplicationId = 'local:$localId';
  final cartDiscount = cart.cartDiscount;
  if (cartDiscount?.applicationId == localApplicationId) {
    notifier.applyCartDiscount(cartDiscount!.copyWith(status: status));
    return;
  }
  for (final entry in cart.items.entries) {
    final itemDiscount = entry.value.discount;
    if (itemDiscount?.applicationId == localApplicationId) {
      notifier.applyItemDiscount(
        cartLineKey: entry.key,
        discount: itemDiscount!.copyWith(status: status),
      );
      return;
    }
  }
}
