import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nytroz_pos/features/device_activation/presentation/providers/device_activation_provider.dart';
import 'package:nytroz_pos/features/discount/domain/entities/pos_discount_api_models.dart';
import 'package:nytroz_pos/features/discount/presentation/providers/pos_discount_provider.dart';
import 'package:nytroz_pos/features/sale/domain/entities/pos_checkout_api_exception.dart';

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
  final repo = ref.watch(posDiscountRepositoryProvider);
  try {
    final catalog = await repo.getDiscounts(
      deviceId: device.deviceId,
      scope: query.scope,
      variantId: query.variantId,
      variantIds: query.variantIds,
      customerId: query.customerId,
      quantity: query.quantity,
      cartSubtotal: query.cartSubtotal,
    );
    await repo.cacheCatalog(deviceId: device.deviceId, catalog: catalog);
    repo.reportOnline();
    return catalog;
  } on PosCheckoutApiException catch (error) {
    if (!error.isNetworkUnavailable) rethrow;
    repo.reportOffline();
    final cached = await repo.cachedCatalog(device.deviceId);
    if (cached == null) rethrow;
    return cached;
  }
});

bool _listEquals(List<String> left, List<String> right) {
  if (identical(left, right)) return true;
  if (left.length != right.length) return false;
  for (var i = 0; i < left.length; i += 1) {
    if (left[i] != right[i]) return false;
  }
  return true;
}
