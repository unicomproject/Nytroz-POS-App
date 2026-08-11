import 'package:flutter_test/flutter_test.dart';
import 'package:nytroz_pos/core/offline/offline_operation.dart';
import 'package:nytroz_pos/core/offline/offline_outbox.dart';
import 'package:nytroz_pos/features/cart/presentation/providers/pos_new_sale_cart_provider.dart';
import 'package:nytroz_pos/features/discount/data/datasources/local/pos_discount_offline_coordinator.dart';
import 'package:nytroz_pos/features/discount/data/datasources/local/pos_pending_sale_recovery_store.dart';
import 'package:nytroz_pos/features/discount/domain/entities/pos_cart_discount.dart';
import 'package:nytroz_pos/features/discount/domain/entities/pos_discount_api_models.dart';
import 'package:nytroz_pos/features/discount/domain/repositories/pos_discount_repository.dart';
import 'package:nytroz_pos/features/discount/domain/usecases/apply_pos_discount.dart';
import 'package:nytroz_pos/features/discount/domain/usecases/cancel_pos_discount.dart';
import 'package:nytroz_pos/features/discount/domain/usecases/restore_pending_discount_sale.dart';
import 'package:nytroz_pos/features/discount/domain/usecases/validate_pos_discount.dart';
import 'package:nytroz_pos/features/discount/presentation/utils/pos_discount_error_mapper.dart';
import 'package:nytroz_pos/features/sale/domain/entities/pos_checkout_api_exception.dart';
import 'package:nytroz_pos/features/sale/domain/entities/pos_checkout_summary.dart';

void main() {
  group('ValidatePosDiscount', () {
    test('rejects item fixed discount before API call', () async {
      final fakeRepo = _FakePosDiscountRepository();
      final useCase = ValidatePosDiscount(fakeRepo);
      expect(
        () => useCase(
          deviceId: 'device-1',
          currencyCode: 'LKR',
          cart: const PosNewSaleCartState(),
          valueType: PosDiscountValueType.fixedAmount,
          value: 100,
          isLineDiscount: true,
        ),
        throwsA(isA<StateError>()),
      );
    });

    test('falls back to offline validation when network is unavailable',
        () async {
      final fakeRepo = _FakePosDiscountRepository(
        validateThrows: PosCheckoutApiException(
          statusCode: 0,
          code: 'network_unavailable',
          message: 'Offline',
          isNetworkUnavailable: true,
        ),
        cachedAuthority: const PosDiscountCatalog(
          authority: PosDiscountAuthority(
            maxPercentage: 15,
            maxFixedAmount: 1000,
            currencyCode: 'LKR',
          ),
          discounts: [],
        ),
      );
      final useCase = ValidatePosDiscount(fakeRepo);
      final cart = PosNewSaleCartState(
        items: {
          'line-1': PosNewSaleCartItem(
            product: const PosNewSaleProduct(
              id: 'p1',
              productId: 'p1',
              name: 'Item',
              category: 'Cat',
              price: 2000,
            ),
            quantity: 1,
          ),
        },
      );

      final result = await useCase(
        deviceId: 'device-1',
        currencyCode: 'LKR',
        cart: cart,
        valueType: PosDiscountValueType.percentage,
        value: 10,
        isLineDiscount: false,
      );

      expect(result.isValid, isTrue);
      expect(result.outcome, 'offline_provisional');
      expect(result.discountAmount, 200);
      expect(result.totalAfterDiscount, 1800);
    });
  });

  group('ApplyPosDiscount', () {
    test('enqueues manual discount offline when network fails', () async {
      final fakeRepo = _FakePosDiscountRepository(
        applyThrows: PosCheckoutApiException(
          statusCode: 0,
          code: 'network_unavailable',
          message: 'Offline',
          isNetworkUnavailable: true,
        ),
        cachedAuthority: const PosDiscountCatalog(
          authority: PosDiscountAuthority(
            maxPercentage: 20,
            maxFixedAmount: 2000,
            currencyCode: 'LKR',
          ),
          discounts: [],
        ),
      );
      final useCase = ApplyPosDiscount(fakeRepo);
      final cart = PosNewSaleCartState(
        items: {
          'line-1': PosNewSaleCartItem(
            product: const PosNewSaleProduct(
              id: 'p1',
              productId: 'p1',
              name: 'Item',
              category: 'Cat',
              price: 3000,
            ),
            quantity: 1,
          ),
        },
      );

      final result = await useCase(
        deviceId: 'device-1',
        currencyCode: 'LKR',
        cart: cart,
        valueType: PosDiscountValueType.percentage,
        value: 10,
        isLineDiscount: false,
        idempotencyKey: 'test-key-1',
      );

      expect(result.applied, isTrue);
      expect(result.status, 'pending_sync');
      expect(result.applicationId, startsWith('local:'));
      expect(fakeRepo.enqueuedOperations, hasLength(1));
    });
  });

  group('CancelPosDiscount', () {
    test('removes local outbox operation and recovery when local', () async {
      final fakeRepo = _FakePosDiscountRepository();
      final useCase = CancelPosDiscount(fakeRepo);
      const discount = PosCartDiscount(
        valueType: PosDiscountValueType.percentage,
        value: 10,
        applicationId: 'local:op-123',
        status: 'pending_sync',
      );

      await useCase(discount: discount, deviceId: 'device-1');

      expect(fakeRepo.removedLocalIds, ['op-123']);
      expect(fakeRepo.clearedRecoverableSaleCount, 1);
    });

    test('calls cancel online when discount is server-authoritative', () async {
      final fakeRepo = _FakePosDiscountRepository();
      final useCase = CancelPosDiscount(fakeRepo);
      const discount = PosCartDiscount(
        valueType: PosDiscountValueType.percentage,
        value: 10,
        applicationId: 'server-app-456',
        status: 'approved',
      );

      await useCase(discount: discount, deviceId: 'device-1');

      expect(fakeRepo.cancelledOnlineApplicationIds, ['server-app-456']);
    });
  });

  group('RestorePendingDiscountSale', () {
    test('restores snapshot when ownership context and outbox match', () async {
      final snapshot = PosPendingSaleRecoverySnapshot(
        tenantId: 't1',
        userId: 'u1',
        deviceId: 'd1',
        outletId: 'o1',
        tillId: 'till1',
        idempotencyKey: 'key-1',
        localDiscountOperationId: 'op-1',
        cart: const PosNewSaleCartState(),
      );
      final fakeRepo = _FakePosDiscountRepository(
        recoverySnapshot: snapshot,
        pendingOperation: OfflineOperation(
          localId: 'op-1',
          type: PosDiscountOfflineCoordinator.operationType,
          idempotencyKey: 'key-1',
          createdAt: DateTime.now(),
          payload: const {},
        ),
      );
      final useCase = RestorePendingDiscountSale(fakeRepo);

      final result = await useCase(
        tenantId: 't1',
        userId: 'u1',
        deviceId: 'd1',
        outletId: 'o1',
        tillId: 'till1',
        hasCartItems: false,
      );

      expect(result, isNotNull);
      expect(result?.localDiscountOperationId, 'op-1');
    });
  });

  group('PosDiscountErrorMapper', () {
    test('maps common backend discount error codes to friendly messages', () {
      expect(
        safePosDiscountErrorMessage(
          PosCheckoutApiException(
            statusCode: 422,
            code: 'pos_discounts.permission_denied',
            message: 'Raw error',
          ),
        ),
        'You do not have permission to apply discounts.',
      );
      expect(
        safePosDiscountErrorMessage(
          PosCheckoutApiException(
            statusCode: 422,
            code: 'pos_discounts.active_discount_exists',
            message: 'Raw error',
          ),
        ),
        'Only one active discount is allowed. Remove the current discount first.',
      );
    });

    test('generates valid non-empty idempotency key with device id', () {
      final key = createPosDiscountIdempotencyKey('dev-10');
      expect(key, startsWith('dev-10-'));
    });
  });
}

class _FakePosDiscountRepository implements PosDiscountRepository {
  _FakePosDiscountRepository({
    this.validateThrows,
    this.applyThrows,
    this.cachedAuthority,
    this.recoverySnapshot,
    this.pendingOperation,
  });

  final Object? validateThrows;
  final Object? applyThrows;
  final PosDiscountCatalog? cachedAuthority;
  final PosPendingSaleRecoverySnapshot? recoverySnapshot;
  final OfflineOperation? pendingOperation;

  final List<String> enqueuedOperations = [];
  final List<String> removedLocalIds = [];
  final List<String> cancelledOnlineApplicationIds = [];
  int clearedRecoverableSaleCount = 0;

  @override
  Future<PosDiscountCatalog> getDiscounts({
    required String deviceId,
    required String scope,
    String? variantId,
    List<String> variantIds = const [],
    String? customerId,
    double? quantity,
    double? cartSubtotal,
  }) async {
    return cachedAuthority ??
        const PosDiscountCatalog(
          authority: PosDiscountAuthority(
              maxPercentage: 20, maxFixedAmount: 2000, currencyCode: 'LKR'),
          discounts: [],
        );
  }

  @override
  Future<void> cacheCatalog(
      {required String deviceId, required PosDiscountCatalog catalog}) async {}

  @override
  Future<PosDiscountCatalog?> cachedCatalog(String deviceId) async =>
      cachedAuthority;

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
  }) async {
    if (validateThrows != null) throw validateThrows!;
    return PosDiscountValidationResult(
      discountId: '',
      isValid: true,
      outcome: 'DIRECT_APPLY',
      calculationMethod: calculationMethod,
      requestedValue: requestedValue,
      cashierLimit: 20,
      absoluteLimit: 20,
      subtotal: 3000,
      eligibleSubtotal: 3000,
      discountAmount: 300,
      totalAfterDiscount: 2700,
      currencyCode: 'LKR',
      cartHash: 'cart-hash',
      validationMessages: const [],
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
  }) async {
    if (applyThrows != null) throw applyThrows!;
    return const PosDiscountApplyResult(
      applicationId: 'server-app-1',
      discountId: '',
      applied: true,
      status: 'approved',
      subtotal: 3000,
      discountAmount: 300,
      totalAfterDiscount: 2700,
      requiresManagerApproval: false,
      cartHash: 'cart-hash',
      messages: [],
    );
  }

  @override
  Future<void> cancelOnline({
    required String applicationId,
    required String deviceId,
    String? reason,
  }) async {
    cancelledOnlineApplicationIds.add(applicationId);
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
  }) async {
    enqueuedOperations.add(localId);
  }

  @override
  Future<void> removeLocalOutbox(String localId) async {
    removedLocalIds.add(localId);
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
  }) async {}

  @override
  Future<PosPendingSaleRecoverySnapshot?> loadRecoverableSale({
    required String tenantId,
    required String userId,
    required String deviceId,
  }) async =>
      recoverySnapshot;

  @override
  Future<void> clearRecoverableSale() async {
    clearedRecoverableSaleCount++;
  }

  @override
  Future<OfflineOperation?> findPendingDiscount({String? localId}) async =>
      pendingOperation;

  @override
  Future<void> syncOutbox({
    required String operationType,
    required Future<OfflineProcessResult> Function(OfflineOperation operation)
        processor,
  }) async {}

  @override
  void addConnectivityListener(Future<void> Function() listener) {}

  @override
  void reportOnline() {}

  @override
  void reportOffline() {}

  @override
  void dispose() {}
}
