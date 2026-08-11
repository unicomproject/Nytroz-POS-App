import 'dart:convert';

import '../../../../../core/storage/app_secure_storage.dart';
import '../../../../cart/presentation/providers/pos_new_sale_cart_provider.dart';
import '../../../../sale/domain/entities/pos_customer.dart';
import '../../../domain/entities/pos_cart_discount.dart';

abstract interface class OfflineStringStore {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
  Future<void> delete(String key);
}

class SecureOfflineStringStore implements OfflineStringStore {
  const SecureOfflineStringStore(this._storage);
  final AppSecureStorage _storage;

  @override
  Future<String?> read(String key) => _storage.read(key);

  @override
  Future<void> write(String key, String value) => _storage.write(key, value);

  @override
  Future<void> delete(String key) => _storage.delete(key);
}

/// Persists the visible New Sale cart + pending Discount for process restart
/// while offline. Ownership is bound to tenant/user/device; mismatched context
/// fails closed.
class PosPendingSaleRecoveryStore {
  const PosPendingSaleRecoveryStore(this._storage);

  static const storageKey = 'pos.offline.pending-sale.v1';
  static const schemaVersion = 1;

  final OfflineStringStore _storage;

  Future<void> save({
    required String tenantId,
    required String userId,
    required String deviceId,
    required String? outletId,
    required String? tillId,
    required PosNewSaleCartState cart,
    required String? idempotencyKey,
    required String? localDiscountOperationId,
  }) async {
    if (!cart.hasItems) {
      await clear();
      return;
    }
    final payload = <String, dynamic>{
      'schemaVersion': schemaVersion,
      'tenantId': tenantId,
      'userId': userId,
      'deviceId': deviceId,
      'outletId': outletId,
      'tillId': tillId,
      'savedAt': DateTime.now().toUtc().toIso8601String(),
      'idempotencyKey': idempotencyKey,
      'localDiscountOperationId': localDiscountOperationId,
      'cart': _cartToJson(cart),
    };
    await _storage.write(storageKey, jsonEncode(payload));
  }

  Future<PosPendingSaleRecoverySnapshot?> loadMatching({
    required String tenantId,
    required String userId,
    required String deviceId,
  }) async {
    final raw = await _storage.read(storageKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      final json = Map<String, dynamic>.from(jsonDecode(raw) as Map);
      if ((json['schemaVersion'] as num?)?.toInt() != schemaVersion) {
        await clear();
        return null;
      }
      if (json['tenantId']?.toString() != tenantId ||
          json['userId']?.toString() != userId ||
          json['deviceId']?.toString() != deviceId) {
        return null;
      }
      final cartJson = json['cart'];
      if (cartJson is! Map) {
        await clear();
        return null;
      }
      final cart = _cartFromJson(Map<String, dynamic>.from(cartJson));
      if (!cart.hasItems) {
        await clear();
        return null;
      }
      return PosPendingSaleRecoverySnapshot(
        tenantId: tenantId,
        userId: userId,
        deviceId: deviceId,
        outletId: json['outletId']?.toString(),
        tillId: json['tillId']?.toString(),
        cart: cart,
        idempotencyKey: json['idempotencyKey']?.toString(),
        localDiscountOperationId: json['localDiscountOperationId']?.toString(),
      );
    } catch (_) {
      await clear();
      return null;
    }
  }

  Future<void> clear() => _storage.delete(storageKey);

  Map<String, dynamic> _cartToJson(PosNewSaleCartState cart) => {
        'editableSaleId': cart.editableSaleId,
        'selectedCustomer': cart.selectedCustomer?.toJson(),
        'cartDiscount': cart.cartDiscount?.toJson(),
        'items': [
          for (final entry in cart.items.entries)
            {
              'cartLineKey': entry.key,
              'quantity': entry.value.quantity,
              'discount': entry.value.discount?.toJson(),
              'product': _productToJson(entry.value.product),
            },
        ],
      };

  PosNewSaleCartState _cartFromJson(Map<String, dynamic> json) {
    final items = <String, PosNewSaleCartItem>{};
    final rawItems = json['items'];
    if (rawItems is List) {
      for (final raw in rawItems.whereType<Map>()) {
        final itemJson = Map<String, dynamic>.from(raw);
        final productRaw = itemJson['product'];
        if (productRaw is! Map) continue;
        final product = _productFromJson(Map<String, dynamic>.from(productRaw));
        final key = itemJson['cartLineKey']?.toString() ?? product.cartLineKey;
        final discountRaw = itemJson['discount'];
        items[key] = PosNewSaleCartItem(
          product: product,
          quantity: (itemJson['quantity'] as num?)?.toInt() ?? 1,
          discount: discountRaw is Map
              ? PosCartDiscount.fromJson(
                  Map<String, dynamic>.from(discountRaw),
                )
              : null,
        );
      }
    }
    final customerRaw = json['selectedCustomer'];
    final cartDiscountRaw = json['cartDiscount'];
    return PosNewSaleCartState(
      items: items,
      selectedCustomer: customerRaw is Map
          ? PosCustomer.fromJson(Map<String, dynamic>.from(customerRaw))
          : null,
      cartDiscount: cartDiscountRaw is Map
          ? PosCartDiscount.fromJson(
              Map<String, dynamic>.from(cartDiscountRaw),
            )
          : null,
      editableSaleId: json['editableSaleId']?.toString(),
    );
  }

  Map<String, dynamic> _productToJson(PosNewSaleProduct product) => {
        'id': product.id,
        'productId': product.productId,
        'variantId': product.variantId,
        'name': product.name,
        'category': product.category,
        'price': product.price,
        'sku': product.sku,
        'imageUrl': product.imageUrl,
        'stockLabel': product.stockLabel,
        'stockStatus': product.stockStatus,
        'hasVariants': product.hasVariants,
        'selectedAttributes': product.selectedAttributes,
        'maxQuantity': product.maxQuantity,
        'clientLineId': product.clientLineId,
        'uomId': product.uomId,
        'lineNote': product.lineNote,
        'source': product.source,
        'recommendationParentProductId': product.recommendationParentProductId,
        'recommendationRelationshipId': product.recommendationRelationshipId,
        'authoritativePrice': product.authoritativePrice,
      };

  PosNewSaleProduct _productFromJson(Map<String, dynamic> json) {
    final attrsRaw = json['selectedAttributes'];
    final attrs = <String, String>{};
    if (attrsRaw is Map) {
      for (final entry in attrsRaw.entries) {
        attrs[entry.key.toString()] = entry.value.toString();
      }
    }
    return PosNewSaleProduct(
      id: json['id']?.toString() ?? '',
      productId: json['productId']?.toString() ?? '',
      variantId: json['variantId']?.toString(),
      name: json['name']?.toString() ?? '',
      category: json['category']?.toString() ?? '',
      price: (json['price'] as num?)?.toInt() ?? 0,
      sku: json['sku']?.toString(),
      imageUrl: json['imageUrl']?.toString(),
      stockLabel: json['stockLabel']?.toString() ?? 'In Stock',
      stockStatus: json['stockStatus']?.toString() ?? 'InStock',
      hasVariants: json['hasVariants'] == true,
      selectedAttributes: attrs,
      maxQuantity: (json['maxQuantity'] as num?)?.toInt(),
      clientLineId: json['clientLineId']?.toString(),
      uomId: json['uomId']?.toString(),
      lineNote: json['lineNote']?.toString(),
      source: json['source']?.toString() ?? 'direct',
      recommendationParentProductId:
          json['recommendationParentProductId']?.toString(),
      recommendationRelationshipId:
          json['recommendationRelationshipId']?.toString(),
      authoritativePrice: (json['authoritativePrice'] as num?)?.toDouble(),
    );
  }
}

class PosPendingSaleRecoverySnapshot {
  const PosPendingSaleRecoverySnapshot({
    required this.tenantId,
    required this.userId,
    required this.deviceId,
    required this.cart,
    this.outletId,
    this.tillId,
    this.idempotencyKey,
    this.localDiscountOperationId,
  });

  final String tenantId;
  final String userId;
  final String deviceId;
  final String? outletId;
  final String? tillId;
  final PosNewSaleCartState cart;
  final String? idempotencyKey;
  final String? localDiscountOperationId;
}
