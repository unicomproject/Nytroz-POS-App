import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nytroz_pos/core/storage/app_secure_storage.dart';
import 'package:nytroz_pos/core/storage/secure_storage_provider.dart';
import 'package:nytroz_pos/features/cart/domain/entities/pos_cart_discount.dart';
import 'package:nytroz_pos/features/cart/presentation/providers/pos_new_sale_cart_provider.dart';
import 'package:nytroz_pos/features/sale/domain/entities/pos_customer.dart';

final posParkedSaleStorageProvider = Provider<PosParkedSaleStorage>((ref) {
  return PosParkedSaleStorage(ref.watch(secureStorageProvider));
});

final posParkedSaleProvider =
    AsyncNotifierProvider<PosParkedSaleNotifier, List<PosParkedSale>>(
  PosParkedSaleNotifier.new,
);

class PosParkedSaleNotifier extends AsyncNotifier<List<PosParkedSale>> {
  PosParkedSaleStorage get _storage => ref.read(posParkedSaleStorageProvider);

  @override
  Future<List<PosParkedSale>> build() {
    return _storage.readAll();
  }

  Future<PosParkedSale?> saveCurrentCart(
    PosNewSaleCartState cart, {
    PosParkedSaleReference? referenceDetails,
  }) async {
    if (!cart.hasItems) {
      return null;
    }

    final current = await future;
    final saleNumber = current.length + 1;
    final sale = PosParkedSale.fromCart(
      cart: cart,
      reference: 'Parked Sale #$saleNumber',
      createdAt: DateTime.now(),
      sequenceNumber: saleNumber,
      referenceDetails: referenceDetails,
    );
    final next = [sale, ...current];

    await _storage.saveAll(next);
    state = AsyncData(next);
    return sale;
  }

  Future<PosParkedSale?> recall(String id) async {
    final current = await future;
    PosParkedSale? recalled;
    final next = <PosParkedSale>[];

    for (final sale in current) {
      if (sale.id == id) {
        recalled = sale;
      } else {
        next.add(sale);
      }
    }

    if (recalled == null) {
      return null;
    }

    await _storage.saveAll(next);
    state = AsyncData(next);
    return recalled;
  }

  Future<void> delete(String id) async {
    final current = await future;
    final next = current.where((sale) => sale.id != id).toList();

    await _storage.saveAll(next);
    state = AsyncData(next);
  }
}

class PosParkedSaleStorage {
  const PosParkedSaleStorage(this._storage);

  static const _storageKey = 'pos.parked_sales';

  final AppSecureStorage _storage;

  Future<List<PosParkedSale>> readAll() async {
    final value = await _storage.read(_storageKey);
    if (value == null || value.trim().isEmpty) {
      return const [];
    }

    try {
      final decoded = jsonDecode(value);
      if (decoded is! List) {
        return const [];
      }

      return decoded
          .whereType<Map>()
          .map((item) => PosParkedSale.fromJson(
                Map<String, dynamic>.from(item),
              ))
          .where((sale) => sale.items.isNotEmpty)
          .toList();
    } catch (_) {
      return const [];
    }
  }

  Future<void> saveAll(List<PosParkedSale> sales) async {
    await _storage.write(
      _storageKey,
      jsonEncode(sales.map((sale) => sale.toJson()).toList()),
    );
  }
}

class PosParkedSale {
  const PosParkedSale({
    required this.id,
    required this.reference,
    required this.createdAt,
    required this.items,
    required this.subtotal,
    required this.discount,
    required this.tax,
    required this.total,
    this.customer,
    this.customerId,
    this.customerName,
    this.customerPhone,
    this.customerEmail,
    this.referenceName,
    this.referencePhone,
    this.note,
    this.cartDiscount,
  });

  factory PosParkedSale.fromCart({
    required PosNewSaleCartState cart,
    required String reference,
    required DateTime createdAt,
    required int sequenceNumber,
    PosParkedSaleReference? referenceDetails,
  }) {
    final timestamp = createdAt.toUtc();
    final customer = cart.selectedCustomer;
    return PosParkedSale(
      id: 'parked-${timestamp.microsecondsSinceEpoch}-$sequenceNumber',
      reference: reference,
      createdAt: timestamp,
      items: cart.itemList,
      customer: customer,
      customerId: customer?.customerId,
      customerName: customer?.displayName,
      customerPhone: customer?.phone,
      customerEmail: customer?.email,
      referenceName: referenceDetails?.referenceName,
      referencePhone: referenceDetails?.referencePhone,
      note: referenceDetails?.note,
      subtotal: cart.subtotal,
      discount: cart.discount,
      tax: cart.tax,
      total: cart.total,
      cartDiscount: cart.cartDiscount,
    );
  }

  factory PosParkedSale.fromJson(Map<String, dynamic> json) {
    final items = json['items'];
    return PosParkedSale(
      id: json['id']?.toString() ?? '',
      reference: json['reference']?.toString() ?? 'Parked Sale',
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      items: items is List
          ? items
              .whereType<Map>()
              .map((item) => _cartItemFromJson(Map<String, dynamic>.from(item)))
              .whereType<PosNewSaleCartItem>()
              .toList()
          : const [],
      customer: _customerFromJson(json['customer']),
      customerId: _nullableString(json['customerId']),
      customerName: _nullableString(json['customerName']),
      customerPhone: _nullableString(json['customerPhone']),
      customerEmail: _nullableString(json['customerEmail']),
      referenceName: _nullableString(json['referenceName']),
      referencePhone: _nullableString(json['referencePhone']),
      note: _nullableString(json['note']),
      subtotal: _intValue(json['subtotal']),
      discount: _intValue(json['discount']),
      tax: _intValue(json['tax']),
      total: _intValue(json['total']),
      cartDiscount: _discountFromJson(json['cartDiscount']),
    );
  }

  final String id;
  final String reference;
  final DateTime createdAt;
  final List<PosNewSaleCartItem> items;
  final PosCustomer? customer;
  final String? customerId;
  final String? customerName;
  final String? customerPhone;
  final String? customerEmail;
  final String? referenceName;
  final String? referencePhone;
  final String? note;
  final PosCartDiscount? cartDiscount;
  final int subtotal;
  final int discount;
  final int tax;
  final int total;

  int get itemCount =>
      items.fold(0, (totalQuantity, item) => totalQuantity + item.quantity);

  String get primaryDisplayName {
    final candidates = [
      customerName,
      customer?.displayName,
      referenceName,
    ];

    for (final candidate in candidates) {
      final value = candidate?.trim();
      if (value != null && value.isNotEmpty && value != 'Customer') {
        return value;
      }
    }

    return 'Walk-in customer';
  }

  String? get primaryPhone {
    final candidates = [customerPhone, customer?.phone, referencePhone];
    for (final candidate in candidates) {
      final value = candidate?.trim();
      if (value != null && value.isNotEmpty) {
        return value;
      }
    }
    return null;
  }

  String? get primaryEmail {
    final candidates = [customerEmail, customer?.email];
    for (final candidate in candidates) {
      final value = candidate?.trim();
      if (value != null && value.isNotEmpty) {
        return value;
      }
    }
    return null;
  }

  String get identityLine {
    final parts = [
      primaryDisplayName,
      if (primaryPhone != null) primaryPhone!,
      if (primaryEmail != null) primaryEmail!,
    ];

    return parts.join(' • ');
  }

  String get itemPreview {
    final names = items
        .map((item) => item.product.name.trim())
        .where((name) => name.isNotEmpty)
        .take(3)
        .toList();

    if (names.isEmpty) {
      return 'Items unavailable';
    }

    final suffix = items.length > names.length ? ', ...' : '';
    return '${names.join(', ')}$suffix';
  }

  PosNewSaleCartState toCartState() {
    return PosNewSaleCartState(
      items: {
        for (final item in items) item.product.cartLineKey: item,
      },
      selectedCustomer: customer,
      cartDiscount: cartDiscount,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'reference': reference,
      'createdAt': createdAt.toUtc().toIso8601String(),
      'items': items.map(_cartItemToJson).toList(),
      'customer': customer?.toJson(),
      'customerId': customerId,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'customerEmail': customerEmail,
      'referenceName': referenceName,
      'referencePhone': referencePhone,
      'note': note,
      'subtotal': subtotal,
      'discount': discount,
      'tax': tax,
      'total': total,
      'cartDiscount': cartDiscount?.toJson(),
    };
  }
}

class PosParkedSaleReference {
  const PosParkedSaleReference({
    required this.referenceName,
    this.referencePhone,
    this.note,
  });

  final String referenceName;
  final String? referencePhone;
  final String? note;
}

Map<String, dynamic> _cartItemToJson(PosNewSaleCartItem item) {
  final product = item.product;
  return {
    'quantity': item.quantity,
    'discount': item.discount?.toJson(),
    'product': {
      'id': product.id,
      'productId': product.productId,
      'variantId': product.variantId,
      'name': product.name,
      'category': product.category,
      'price': product.price,
      'sku': product.sku,
      'stockLabel': product.stockLabel,
      'hasVariants': product.hasVariants,
      'selectedAttributes': product.selectedAttributes,
      'maxQuantity': product.maxQuantity,
    },
  };
}

PosNewSaleCartItem? _cartItemFromJson(Map<String, dynamic> json) {
  final productJson = json['product'];
  if (productJson is! Map) {
    return null;
  }

  final product = Map<String, dynamic>.from(productJson);
  final productId = product['productId']?.toString() ?? '';
  final id = product['id']?.toString() ?? productId;
  final name = product['name']?.toString() ?? '';

  if (id.isEmpty || productId.isEmpty || name.isEmpty) {
    return null;
  }

  return PosNewSaleCartItem(
    product: PosNewSaleProduct(
      id: id,
      productId: productId,
      variantId: product['variantId']?.toString(),
      name: name,
      category: product['category']?.toString() ?? '',
      price: _intValue(product['price']),
      sku: product['sku']?.toString(),
      stockLabel: product['stockLabel']?.toString() ?? 'In Stock',
      hasVariants: product['hasVariants'] == true,
      selectedAttributes: _stringMap(product['selectedAttributes']),
      maxQuantity: _nullableInt(product['maxQuantity']),
    ),
    quantity: _positiveInt(json['quantity']),
    discount: _discountFromJson(json['discount']),
  );
}

PosCartDiscount? _discountFromJson(Object? value) {
  if (value is! Map) {
    return null;
  }

  final discount = PosCartDiscount.fromJson(Map<String, dynamic>.from(value));
  return discount.value <= 0 ? null : discount;
}

PosCustomer? _customerFromJson(Object? value) {
  if (value is! Map) {
    return null;
  }

  final customer = PosCustomer.fromJson(Map<String, dynamic>.from(value));
  return customer.customerId.trim().isEmpty ? null : customer;
}

Map<String, String> _stringMap(Object? value) {
  if (value is! Map) {
    return const {};
  }

  return value.map(
    (key, itemValue) => MapEntry(key.toString(), itemValue.toString()),
  );
}

int _intValue(Object? value) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.round();
  }
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

int? _nullableInt(Object? value) {
  if (value == null) {
    return null;
  }
  return _intValue(value);
}

int _positiveInt(Object? value) {
  final parsed = _intValue(value);
  return parsed <= 0 ? 1 : parsed;
}

String? _nullableString(Object? value) {
  final stringValue = value?.toString().trim();
  return stringValue == null || stringValue.isEmpty ? null : stringValue;
}
