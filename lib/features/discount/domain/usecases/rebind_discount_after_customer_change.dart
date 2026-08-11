import 'package:nytroz_pos/features/cart/presentation/providers/pos_new_sale_cart_provider.dart';
import 'package:nytroz_pos/features/device_activation/domain/entities/pos_device_context.dart';
import 'package:nytroz_pos/features/discount/domain/entities/pos_cart_discount.dart';
import 'package:nytroz_pos/features/discount/domain/repositories/pos_discount_repository.dart';
import 'package:nytroz_pos/features/sale/presentation/providers/pos_checkout_summary_provider.dart';

class RebindDiscountAfterCustomerChange {
  const RebindDiscountAfterCustomerChange(this._repository);
  final PosDiscountRepository _repository;

  Future<String?> call({
    required PosNewSaleCartState currentCart,
    required PosDeviceContext? deviceContext,
    required PosNewSaleCartNotifier cartNotifier,
    required String Function(String deviceId) createIdempotencyKey,
    required String Function(Object error) formatErrorMessage,
  }) async {
    final bindings = activeDiscountBindings(currentCart);
    if (bindings.isEmpty) {
      return null;
    }

    if (deviceContext == null) {
      return 'Device context is not available to refresh the discount.';
    }

    final customerId = currentCart.selectedCustomer?.customerId;

    for (final binding in bindings) {
      final applicationId = binding.discount.applicationId;
      if (applicationId == null || applicationId.isEmpty) {
        continue;
      }
      try {
        await _repository.cancelOnline(
          applicationId: applicationId,
          deviceId: deviceContext.deviceId,
          reason: 'Customer changed — rebinding discount',
        );
      } catch (_) {
        // Best-effort: stale applications are replaced by a new apply below.
      }
    }

    cartNotifier.clearDiscounts();

    final lines = checkoutLinesFromCart(currentCart);
    if (lines.isEmpty) {
      return null;
    }

    for (final binding in bindings) {
      final discount = binding.discount;
      final predefined = discount.source.toUpperCase() == 'POLICY' &&
          (discount.policyId?.trim().isNotEmpty ?? false);
      try {
        final result = await _repository.applyOnline(
          deviceId: deviceContext.deviceId,
          discountId: predefined ? discount.policyId : null,
          discountSource: predefined ? 'POLICY' : 'MANUAL',
          calculationMethod:
              discount.valueType == PosDiscountValueType.percentage
                  ? 'PERCENTAGE'
                  : 'FIXED_AMOUNT',
          scope: discount.scope.toUpperCase() == 'LINE' ? 'LINE' : 'ORDER',
          lines: lines,
          requestedValue: predefined ? null : discount.value,
          targetVariantId: discount.targetVariantId,
          reason: discount.reason,
          customerId: customerId,
          idempotencyKey: createIdempotencyKey(deviceContext.deviceId),
        );

        if (!result.applied && !result.requiresManagerApproval) {
          return 'Customer updated, but the discount could not be re-applied. '
              'Please apply the discount again.';
        }

        final rebound = PosCartDiscount(
          valueType: discount.valueType,
          value: discount.value,
          reason: discount.reason,
          policyId: discount.policyId ??
              (result.discountId.isEmpty ? null : result.discountId),
          applicationId: result.applicationId,
          status: result.status,
          cartHash: result.cartHash,
          source: discount.source,
          scope: discount.scope,
          targetVariantId: discount.targetVariantId,
          discountAmount: result.discountAmount,
          totalAfterDiscount: result.totalAfterDiscount,
          currencyCode: deviceContext.currencyCode,
        );

        if (binding.cartLineKey != null) {
          cartNotifier.applyItemDiscount(
            cartLineKey: binding.cartLineKey!,
            discount: rebound,
          );
        } else {
          cartNotifier.applyCartDiscount(rebound);
        }
      } catch (error) {
        return formatErrorMessage(error);
      }
    }

    return null;
  }

  static bool isBoundPosDiscount(PosCartDiscount discount) {
    final applicationId = discount.applicationId?.trim();
    if (applicationId == null || applicationId.isEmpty) {
      return false;
    }
    final status = discount.status.trim().toLowerCase();
    return status == 'approved' ||
        status == 'applied' ||
        status == 'pending_approval';
  }

  static List<({PosCartDiscount discount, String? cartLineKey})>
      activeDiscountBindings(PosNewSaleCartState cart) {
    final bindings = <({PosCartDiscount discount, String? cartLineKey})>[];
    final cartDiscount = cart.cartDiscount;
    if (cartDiscount != null && isBoundPosDiscount(cartDiscount)) {
      bindings.add((discount: cartDiscount, cartLineKey: null));
    }
    for (final entry in cart.items.entries) {
      final itemDiscount = entry.value.discount;
      if (itemDiscount != null && isBoundPosDiscount(itemDiscount)) {
        bindings.add((discount: itemDiscount, cartLineKey: entry.key));
      }
    }
    return bindings;
  }
}
