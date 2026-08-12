import 'package:nytroz_pos/features/cart/presentation/providers/pos_new_sale_cart_provider.dart';
import 'package:nytroz_pos/features/discount/domain/entities/pos_cart_discount.dart';
import 'package:nytroz_pos/features/discount/domain/entities/pos_discount_api_models.dart';
import 'package:nytroz_pos/features/discount/domain/repositories/pos_discount_repository.dart';
import 'package:nytroz_pos/features/sale/domain/entities/pos_checkout_api_exception.dart';
import 'package:nytroz_pos/features/sale/presentation/providers/pos_checkout_summary_provider.dart';

class ValidatePosDiscount {
  const ValidatePosDiscount(this._repository);
  final PosDiscountRepository _repository;

  Future<PosDiscountValidationResult> call({
    required String deviceId,
    required String currencyCode,
    required PosNewSaleCartState cart,
    required PosDiscountValueType valueType,
    required double value,
    required bool isLineDiscount,
    String? targetVariantId,
    String? reason,
    String? customerId,
  }) async {
    if (isLineDiscount && valueType == PosDiscountValueType.fixedAmount) {
      throw StateError('Item fixed discounts are not available.');
    }

    try {
      return await _repository.validateOnline(
        deviceId: deviceId,
        scope: isLineDiscount ? 'LINE' : 'ORDER',
        calculationMethod: valueType == PosDiscountValueType.percentage
            ? 'PERCENTAGE'
            : 'FIXED_AMOUNT',
        lines: checkoutLinesFromCart(cart),
        requestedValue: value,
        targetVariantId: targetVariantId,
        reason: reason,
        customerId: customerId,
      );
    } on PosCheckoutApiException catch (error) {
      if (!error.isNetworkUnavailable) rethrow;
      final authority = await _repository.cachedCatalog(deviceId);
      return validateOfflineManualDiscount(
        authority: authority,
        cart: cart,
        valueType: valueType,
        value: value,
        isLineDiscount: isLineDiscount,
        targetVariantId: targetVariantId,
        currencyCode: currencyCode,
      );
    }
  }

  static PosDiscountValidationResult validateOfflineManualDiscount({
    required PosDiscountCatalog? authority,
    required PosNewSaleCartState cart,
    required PosDiscountValueType valueType,
    required double value,
    required bool isLineDiscount,
    required String? targetVariantId,
    required String currencyCode,
  }) {
    if (authority == null) {
      throw StateError(
        'Offline discount authority is unavailable or expired. Reconnect before applying a discount.',
      );
    }
    if (isLineDiscount && valueType == PosDiscountValueType.fixedAmount) {
      throw StateError('Item fixed discounts are not available.');
    }
    final limit = valueType == PosDiscountValueType.percentage
        ? authority.authority.maxPercentage
        : authority.authority.maxFixedAmount;
    if (value <= 0 || value > limit) {
      throw StateError(
        'Discount exceeds the cached cashier authority limit (${valueType == PosDiscountValueType.percentage ? '${limit.toStringAsFixed(2)}%' : '$currencyCode ${limit.toStringAsFixed(2)}'}).',
      );
    }
    var eligible = cart.subtotal;
    if (isLineDiscount) {
      final line = cart.items.values.where(
        (item) => item.product.variantId == targetVariantId,
      );
      if (line.isEmpty) throw StateError('Select a valid item from the cart.');
      eligible = line.first.lineTotal;
    }
    final amount = (valueType == PosDiscountValueType.percentage
            ? eligible * value / 100
            : value)
        .round()
        .clamp(0, eligible);
    return PosDiscountValidationResult(
      discountId: '',
      isValid: true,
      outcome: 'offline_provisional',
      calculationMethod: valueType == PosDiscountValueType.percentage
          ? 'PERCENTAGE'
          : 'FIXED_AMOUNT',
      requestedValue: value,
      cashierLimit: limit,
      absoluteLimit: limit,
      subtotal: cart.subtotal,
      eligibleSubtotal: eligible,
      discountAmount: amount,
      totalAfterDiscount: cart.subtotal - amount,
      currencyCode: currencyCode,
      cartHash: 'offline-provisional',
      validationMessages: const [
        'Offline provisional discount. Backend revalidation is required.'
      ],
    );
  }
}
