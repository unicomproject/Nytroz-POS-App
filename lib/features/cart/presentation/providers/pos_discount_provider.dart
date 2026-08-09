import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_provider.dart';
import '../../../device_activation/presentation/providers/device_activation_provider.dart';
import '../../../sale/presentation/providers/pos_checkout_summary_provider.dart';
import '../../../sale/domain/entities/pos_checkout_api_exception.dart';
import '../../data/datasources/pos_discount_remote_datasource.dart';
import '../../domain/entities/pos_cart_discount.dart';
import '../../domain/entities/pos_discount_api_models.dart';
import 'pos_new_sale_cart_provider.dart';

final posDiscountRemoteDatasourceProvider =
    Provider<PosDiscountRemoteDatasource>(
  (ref) => PosDiscountRemoteDatasource(ref.watch(appDioProvider)),
);

class PosDiscountCatalogQuery {
  const PosDiscountCatalogQuery({
    required this.scope,
    this.variantId,
    this.variantIds = const [],
    this.customerId,
    this.quantity,
    this.cartSubtotal,
  });
  final String scope;
  final String? variantId;
  final List<String> variantIds;
  final String? customerId;
  final double? quantity;
  final double? cartSubtotal;
  @override
  bool operator ==(Object other) =>
      other is PosDiscountCatalogQuery &&
      scope == other.scope &&
      variantId == other.variantId &&
      _listEquals(variantIds, other.variantIds) &&
      customerId == other.customerId &&
      quantity == other.quantity &&
      cartSubtotal == other.cartSubtotal;
  @override
  int get hashCode => Object.hash(
        scope,
        variantId,
        Object.hashAll(variantIds),
        customerId,
        quantity,
        cartSubtotal,
      );
}

final posDiscountCatalogProvider = FutureProvider.autoDispose
    .family<PosDiscountCatalog, PosDiscountCatalogQuery>((ref, query) async {
  final device = ref.watch(deviceActivationProvider).deviceContext;
  if (device == null) throw StateError('POS device context is not ready.');
  return ref.watch(posDiscountRemoteDatasourceProvider).getDiscounts(
        deviceId: device.deviceId,
        scope: query.scope,
        variantId: query.variantId,
        variantIds: query.variantIds,
        customerId: query.customerId,
        quantity: query.quantity,
        cartSubtotal: query.cartSubtotal,
      );
});

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
  final lines = checkoutLinesFromCart(cart);
  final result = await ref.read(posDiscountRemoteDatasourceProvider).apply(
        deviceId: device.deviceId,
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
        idempotencyKey:
            idempotencyKey ?? createPosDiscountIdempotencyKey(device.deviceId),
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
  if (isLineDiscount && valueType == PosDiscountValueType.fixedAmount) {
    throw StateError('Item fixed discounts are not available.');
  }
  final device = ref.read(deviceActivationProvider).deviceContext;
  final cart = ref.read(posNewSaleCartProvider);
  if (device == null) throw StateError('POS device context is not ready.');
  return ref.read(posDiscountRemoteDatasourceProvider).validate(
        deviceId: device.deviceId,
        scope: isLineDiscount ? 'LINE' : 'ORDER',
        calculationMethod: valueType == PosDiscountValueType.percentage
            ? 'PERCENTAGE'
            : 'FIXED_AMOUNT',
        lines: checkoutLinesFromCart(cart),
        requestedValue: value,
        targetVariantId: targetVariantId,
        reason: reason,
        customerId: cart.selectedCustomer?.customerId,
      );
}

Future<void> cancelPosDiscount({
  required WidgetRef ref,
  required PosCartDiscount discount,
}) async {
  final applicationId = discount.applicationId;
  if (applicationId == null) return;
  final device = ref.read(deviceActivationProvider).deviceContext;
  if (device == null) throw StateError('POS device context is not ready.');
  await ref.read(posDiscountRemoteDatasourceProvider).cancel(
        applicationId: applicationId,
        deviceId: device.deviceId,
        reason: 'Removed from POS cart',
      );
}

/// After customer attach/clear, backend discount cartHash includes customerId.
/// Re-bind any active application so New Sale → Discount → Customer → Payment
/// keeps working without forcing cashiers to reverse that order.
Future<String?> rebindPosDiscountsAfterCustomerChange({
  required T Function<T>(ProviderListenable<T> provider) read,
  required void Function(ProviderOrFamily provider) invalidate,
}) async {
  final cart = read(posNewSaleCartProvider);
  final bindings = _activeDiscountBindings(cart);
  if (bindings.isEmpty) {
    return null;
  }

  final device = read(deviceActivationProvider).deviceContext;
  if (device == null) {
    return 'Device context is not available to refresh the discount.';
  }

  final datasource = read(posDiscountRemoteDatasourceProvider);
  final cartNotifier = read(posNewSaleCartProvider.notifier);
  final customerId = cart.selectedCustomer?.customerId;

  for (final binding in bindings) {
    final applicationId = binding.discount.applicationId;
    if (applicationId == null || applicationId.isEmpty) {
      continue;
    }
    try {
      await datasource.cancel(
        applicationId: applicationId,
        deviceId: device.deviceId,
        reason: 'Customer changed — rebinding discount',
      );
    } catch (_) {
      // Best-effort: stale applications are replaced by a new apply below.
    }
  }

  cartNotifier.clearDiscounts();

  final lines = checkoutLinesFromCart(read(posNewSaleCartProvider));
  if (lines.isEmpty) {
    return null;
  }

  for (final binding in bindings) {
    final discount = binding.discount;
    final predefined = discount.source.toUpperCase() == 'POLICY' &&
        (discount.policyId?.trim().isNotEmpty ?? false);
    try {
      final result = await datasource.apply(
        deviceId: device.deviceId,
        discountId: predefined ? discount.policyId : null,
        discountSource: predefined ? 'POLICY' : 'MANUAL',
        calculationMethod: discount.valueType == PosDiscountValueType.percentage
            ? 'PERCENTAGE'
            : 'FIXED_AMOUNT',
        scope: discount.scope.toUpperCase() == 'LINE' ? 'LINE' : 'ORDER',
        lines: lines,
        requestedValue: predefined ? null : discount.value,
        targetVariantId: discount.targetVariantId,
        reason: discount.reason,
        customerId: customerId,
        idempotencyKey: createPosDiscountIdempotencyKey(device.deviceId),
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
        currencyCode: device.currencyCode,
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
      return safePosDiscountErrorMessage(error);
    }
  }

  invalidate(posCheckoutSummaryProvider);
  return null;
}

bool isBoundPosDiscount(PosCartDiscount discount) {
  final applicationId = discount.applicationId?.trim();
  if (applicationId == null || applicationId.isEmpty) {
    return false;
  }
  final status = discount.status.trim().toLowerCase();
  return status == 'approved' ||
      status == 'applied' ||
      status == 'pending_approval';
}

List<({PosCartDiscount discount, String? cartLineKey})> _activeDiscountBindings(
  PosNewSaleCartState cart,
) {
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

String createPosDiscountIdempotencyKey(String deviceId) {
  final random = Random.secure();
  final suffix =
      List.generate(12, (_) => random.nextInt(16).toRadixString(16)).join();
  return '$deviceId-${DateTime.now().microsecondsSinceEpoch}-$suffix';
}

bool _listEquals(List<String> left, List<String> right) {
  if (identical(left, right)) return true;
  if (left.length != right.length) return false;
  for (var i = 0; i < left.length; i += 1) {
    if (left[i] != right[i]) return false;
  }
  return true;
}

String safePosDiscountErrorMessage(Object error) {
  if (error is PosCheckoutApiException) {
    return switch (error.code) {
      'pos_discounts.permission_denied' =>
        'You do not have permission to apply discounts.',
      'pos_discounts.device_not_found' ||
      'pos_discounts.device_not_trusted' =>
        'This POS device is not authorized for discounts.',
      'pos_discounts.till_not_assigned' ||
      'pos_discounts.till_session_not_open' =>
        'An assigned till with an open session is required.',
      'pos_discounts.item_fixed_not_allowed' =>
        'Fixed amount discounts are not available for individual items.',
      'pos_discounts.target_required' ||
      'pos_discounts.target_not_in_cart' =>
        'Select a valid item from the current cart.',
      'pos_discounts.active_discount_exists' =>
        'Only one active discount is allowed. Remove the current discount first.',
      'pos_discounts.idempotency_conflict' =>
        'This discount request changed. Close and start a new discount request.',
      'pos_discounts.cart_changed' =>
        'The cart changed. Revalidate the discount and try again.',
      _ => error.isNetworkUnavailable
          ? 'Discount service is unavailable. Check the connection and try again.'
          : error.message,
    };
  }
  if (error is StateError) return error.message;
  return 'Unable to process the discount. Try again.';
}
