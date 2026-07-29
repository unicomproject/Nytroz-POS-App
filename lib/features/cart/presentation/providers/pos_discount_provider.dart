import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_provider.dart';
import '../../../device_activation/presentation/providers/device_activation_provider.dart';
import '../../../sale/presentation/providers/pos_checkout_summary_provider.dart';
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
        idempotencyKey: _idempotencyKey(device.deviceId),
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
    );
    final notifier = ref.read(posNewSaleCartProvider.notifier);
    if (isLineDiscount && targetVariantId != null) {
      notifier.applyItemDiscount(
          cartLineKey: targetVariantId, discount: discount);
    } else {
      notifier.applyCartDiscount(discount);
    }
    ref.invalidate(posCheckoutSummaryProvider);
  }
  return result;
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

String _idempotencyKey(String deviceId) {
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
