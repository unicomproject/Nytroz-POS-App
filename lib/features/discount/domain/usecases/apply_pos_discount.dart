import 'package:nytroz_pos/features/cart/presentation/providers/pos_new_sale_cart_provider.dart';
import 'package:nytroz_pos/features/discount/domain/entities/pos_cart_discount.dart';
import 'package:nytroz_pos/features/discount/domain/entities/pos_discount_api_models.dart';
import 'package:nytroz_pos/features/discount/domain/repositories/pos_discount_repository.dart';
import 'package:nytroz_pos/features/discount/domain/usecases/validate_pos_discount.dart';
import 'package:nytroz_pos/features/sale/domain/entities/pos_checkout_api_exception.dart';
import 'package:nytroz_pos/features/sale/domain/entities/pos_checkout_summary.dart';
import 'package:nytroz_pos/features/sale/presentation/providers/pos_checkout_summary_provider.dart';

class ApplyPosDiscount {
  const ApplyPosDiscount(this._repository);
  final PosDiscountRepository _repository;

  Future<PosDiscountApplyResult> call({
    required String deviceId,
    required String currencyCode,
    required PosNewSaleCartState cart,
    PosDiscountPolicy? policy,
    required PosDiscountValueType valueType,
    required double value,
    required bool isLineDiscount,
    String? targetVariantId,
    String? reason,
    bool predefined = false,
    String? cartLineKey,
    required String idempotencyKey,
    String? tenantId,
    String? userId,
    String? outletId,
    String? tillId,
  }) async {
    final lines = checkoutLinesFromCart(cart);
    try {
      return await _repository.applyOnline(
        deviceId: deviceId,
        discountId: predefined ? policy?.id : null,
        discountSource: predefined ? 'POLICY' : 'MANUAL',
        calculationMethod: valueType == PosDiscountValueType.percentage
            ? 'PERCENTAGE'
            : 'FIXED_AMOUNT',
        scope: isLineDiscount ? 'LINE' : 'ORDER',
        lines: lines,
        requestedValue: predefined ? null : value,
        targetVariantId: targetVariantId,
        reason: reason,
        customerId: cart.selectedCustomer?.customerId,
        idempotencyKey: idempotencyKey,
      );
    } on PosCheckoutApiException catch (error) {
      if (!error.isNetworkUnavailable || predefined) rethrow;
      _repository.reportOffline();
      return _createOfflineManualDiscount(
        deviceId: deviceId,
        currencyCode: currencyCode,
        cart: cart,
        valueType: valueType,
        value: value,
        isLineDiscount: isLineDiscount,
        targetVariantId: targetVariantId,
        reason: reason,
        cartLineKey: cartLineKey,
        idempotencyKey: idempotencyKey,
        lines: lines,
        tenantId: tenantId,
        userId: userId,
        outletId: outletId,
        tillId: tillId,
      );
    }
  }

  Future<PosDiscountApplyResult> _createOfflineManualDiscount({
    required String deviceId,
    required String currencyCode,
    required PosNewSaleCartState cart,
    required PosDiscountValueType valueType,
    required double value,
    required bool isLineDiscount,
    required String? targetVariantId,
    required String? reason,
    required String? cartLineKey,
    required String idempotencyKey,
    required List<PosCheckoutLineRequest> lines,
    required String? tenantId,
    required String? userId,
    required String? outletId,
    required String? tillId,
  }) async {
    final authority = await _repository.cachedCatalog(deviceId);
    final validation = ValidatePosDiscount.validateOfflineManualDiscount(
      authority: authority,
      cart: cart,
      valueType: valueType,
      value: value,
      isLineDiscount: isLineDiscount,
      targetVariantId: targetVariantId,
      currencyCode: currencyCode,
    );
    if (!validation.isValid) {
      throw StateError(validation.validationMessages.join(' '));
    }
    final localId =
        '${DateTime.now().microsecondsSinceEpoch}-${idempotencyKey.hashCode.abs()}';
    await _repository.enqueueManualApply(
      localId: localId,
      idempotencyKey: idempotencyKey,
      deviceId: deviceId,
      scope: isLineDiscount ? 'LINE' : 'ORDER',
      calculationMethod: valueType == PosDiscountValueType.percentage
          ? 'PERCENTAGE'
          : 'FIXED_AMOUNT',
      requestedValue: value,
      lines: lines,
      discountAmount: validation.discountAmount,
      totalAfterDiscount: validation.totalAfterDiscount,
      targetVariantId: targetVariantId,
      reason: reason,
      customerId: cart.selectedCustomer?.customerId,
      cartLineKey: cartLineKey,
      tenantId: tenantId,
      userId: userId,
      outletId: outletId,
      tillId: tillId,
      currencyCodeSnapshot: currencyCode,
    );
    return PosDiscountApplyResult(
      applicationId: 'local:$localId',
      discountId: '',
      applied: true,
      status: 'pending_sync',
      subtotal: validation.subtotal,
      discountAmount: validation.discountAmount,
      totalAfterDiscount: validation.totalAfterDiscount,
      requiresManagerApproval: false,
      cartHash: 'offline:$localId',
      messages: const ['Saved offline. Final approval is pending sync.'],
    );
  }
}
