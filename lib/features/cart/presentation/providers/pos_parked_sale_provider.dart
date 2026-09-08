import 'dart:convert';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nytroz_pos/core/access/pos_access_codes.dart';
import 'package:nytroz_pos/core/network/dio_provider.dart';
import 'package:nytroz_pos/core/storage/app_secure_storage.dart';
import 'package:nytroz_pos/core/storage/secure_storage_provider.dart';
import 'package:nytroz_pos/features/auth/presentation/providers/session_provider.dart';
import 'package:nytroz_pos/features/cart/data/datasources/pos_parked_sale_remote_datasource.dart';
import 'package:nytroz_pos/features/cart/data/models/pos_parked_sale_dtos.dart';
import 'package:nytroz_pos/features/cart/data/repositories/pos_parked_sale_repository_impl.dart';
import 'package:nytroz_pos/features/discount/domain/entities/pos_cart_discount.dart';
import 'package:nytroz_pos/features/cart/domain/repositories/pos_parked_sale_repository.dart';
import 'package:nytroz_pos/features/cart/presentation/providers/pos_new_sale_cart_provider.dart';
import 'package:nytroz_pos/features/device_activation/presentation/providers/device_activation_provider.dart';
import 'package:nytroz_pos/features/sale/domain/entities/pos_customer.dart';
import 'package:nytroz_pos/features/sale/domain/entities/pos_checkout_api_exception.dart';
import 'package:nytroz_pos/features/sale/presentation/providers/pos_checkout_summary_provider.dart';

final posParkedSaleRemoteDatasourceProvider =
    Provider((ref) => PosParkedSaleRemoteDatasource(ref.watch(appDioProvider)));
final posParkedSaleRepositoryProvider = Provider<PosParkedSaleRepository>(
    (ref) => PosParkedSaleRepositoryImpl(
        ref.watch(posParkedSaleRemoteDatasourceProvider)));

final posParkedSaleStorageProvider = Provider<PosParkedSaleStorage>((ref) {
  return PosParkedSaleStorage(ref.watch(secureStorageProvider));
});

final posParkedSaleProvider =
    AsyncNotifierProvider<PosParkedSaleNotifier, List<PosParkedSale>>(
  PosParkedSaleNotifier.new,
);

final posParkedSaleCountProvider = Provider<int>((ref) {
  ref.watch(posParkedSaleProvider);
  return ref.read(posParkedSaleProvider.notifier).totalCount;
});

final posParkedSaleOperationProvider =
    StateProvider<PosParkedSaleOperation>((ref) => PosParkedSaleOperation.idle);

final posParkedSaleAccessContextProvider =
    Provider<PosParkedSaleAccessContext>((ref) {
  final session = ref.watch(authSessionProvider);
  final device = ref.watch(deviceActivationProvider).deviceContext;
  return PosParkedSaleAccessContext(
    authenticated: session?.isAuthenticated == true,
    permissions: session?.permissionCodes.toSet() ?? const {},
    deviceId: device?.deviceId,
    trustedDevice: device?.isTrusted == true,
  );
});

class PosParkedSaleAccessContext {
  const PosParkedSaleAccessContext(
      {required this.authenticated,
      required this.permissions,
      this.deviceId,
      this.trustedDevice = false});
  final bool authenticated, trustedDevice;
  final Set<String> permissions;
  final String? deviceId;
}

class PosParkedSaleNotifier extends AsyncNotifier<List<PosParkedSale>> {
  PosParkedSaleStorage get _storage => ref.read(posParkedSaleStorageProvider);
  PosParkedSaleRepository get _repository =>
      ref.read(posParkedSaleRepositoryProvider);
  int totalCount = 0;
  int totalValue = 0;
  String currency = '';
  int page = 1;
  int pageSize = 25;
  PosParkedSaleScope scope = PosParkedSaleScope.today;
  PosParkedSaleOperation operation = PosParkedSaleOperation.idle;
  PosCheckoutApiException? lastFailure;
  PosRecallHoldDto? lastRecall;
  String? _pendingKey, _pendingFingerprint;
  final Set<String> _mutatingHolds = {};
  bool _creating = false;

  @override
  Future<List<PosParkedSale>> build() async {
    // Watching the trusted deviceId means a till/device change (e.g. a
    // different trusted till taking over this session) invalidates this
    // provider and forces a fresh load scoped to the new device, instead of
    // silently continuing to show holds resolved for the previous till.
    ref.watch(posParkedSaleAccessContextProvider.select((c) => c.deviceId));
    return _loadFromBackend();
  }

  Future<List<PosParkedSale>> _loadFromBackend() async {
    _requirePermission(PosPermissionCodes.viewBackendParkedSales);
    final result = await _repository.list(
      deviceId: _deviceId(),
      scope: scope.apiValue,
      page: page,
      pageSize: pageSize,
    );
    _applyListMetadata(result);
    lastFailure = null;
    return result.holds.map(PosParkedSale.fromBackend).toList(growable: false);
  }

  Future<void> refresh() async {
    final previous = state.valueOrNull ?? const <PosParkedSale>[];
    _setOperation(PosParkedSaleOperation.loadingList);
    try {
      final next = await _loadFromBackend();
      state = AsyncData(next);
    } catch (e) {
      lastFailure = _failure(e);
      state = AsyncData(previous);
    } finally {
      _setOperation(PosParkedSaleOperation.idle);
    }
  }

  Future<void> selectScope(PosParkedSaleScope nextScope) async {
    if (scope == nextScope && page == 1) return;
    scope = nextScope;
    page = 1;
    await refresh();
  }

  Future<void> goToPage(int nextPage) async {
    final lastPage = totalCount == 0 ? 1 : ((totalCount - 1) ~/ pageSize) + 1;
    if (nextPage < 1 || nextPage > lastPage || nextPage == page) return;
    page = nextPage;
    await refresh();
  }

  Future<PosParkedSale?> saveCurrentCart(
    PosNewSaleCartState cart, {
    PosParkedSaleReference? referenceDetails,
  }) async {
    if (!cart.hasItems) {
      return null;
    }
    _requirePermission(PosPermissionCodes.createParkedSale);
    if (_creating) return null;
    final note = referenceDetails?.note?.trim();
    if ((note?.length ?? 0) > 250) {
      throw PosCheckoutApiException(
          message: 'Park Sale note must be 250 characters or fewer.',
          code: 'pos_holds.invalid_note',
          statusCode: 400);
    }
    final device = _deviceId();
    final lines = checkoutLinesFromCart(cart);
    if (lines
        .any((line) => line.variantId.trim().isEmpty || line.quantity <= 0)) {
      throw PosCheckoutApiException(
          message:
              'Every Park Sale line requires a valid variant and quantity.',
          code: 'pos_holds.invalid_line',
          statusCode: 400);
    }
    final fingerprint = jsonEncode({
      'deviceId': device,
      'customerId': cart.selectedCustomer?.customerId,
      'discountApplicationId': cart.discountApplicationId,
      'note': note,
      'lines': lines.map((e) => e.toJson()).toList()
    });
    if (_pendingFingerprint != fingerprint) {
      _pendingFingerprint = fingerprint;
      _pendingKey = _newIdempotencyKey();
    }
    _creating = true;
    _setOperation(PosParkedSaleOperation.creating);
    lastFailure = null;
    try {
      final dto = await _repository.create(PosCreateHoldRequestDto(
          deviceId: device,
          lines: lines,
          customerId: cart.selectedCustomer?.customerId,
          reason: note,
          discountApplicationId: cart.discountApplicationId,
          idempotencyKey: _pendingKey!));
      final sale = PosParkedSale.fromBackend(dto);
      ref.read(posNewSaleCartProvider.notifier).clear();
      _pendingKey = null;
      _pendingFingerprint = null;
      final current = state.valueOrNull ?? const <PosParkedSale>[];
      final isNewSale = !current.any((x) => x.id == sale.id);
      if (isNewSale) {
        totalCount += 1;
        totalValue += sale.total;
      }
      state = AsyncData([sale, ...current.where((x) => x.id != sale.id)]);
      _setOperation(PosParkedSaleOperation.createSuccess);
      return sale;
    } catch (e) {
      lastFailure = _failure(e);
      _setOperation(_operationFor(lastFailure!));
      rethrow;
    } finally {
      _creating = false;
    }
  }

  Future<PosParkedSale?> recall(String id) async {
    _requirePermission(PosPermissionCodes.recallBackendParkedSale);
    if (ref.read(posNewSaleCartProvider).hasItems) {
      throw PosCheckoutApiException(
          message:
              'Clear or park the active cart before recalling another sale.',
          code: 'pos_holds.active_cart_not_empty',
          statusCode: 409);
    }
    if (!_mutatingHolds.add('recall:$id')) return null;
    final current = await future;
    final held = current.where((x) => x.id == id).firstOrNull;
    if (held == null) {
      _mutatingHolds.remove('recall:$id');
      return null;
    }
    _setOperation(PosParkedSaleOperation.recalling);
    try {
      final result = await _repository.recall(id, _deviceId());
      lastRecall = result;
      final restored = held.toRecalledCart(result);
      ref.read(posNewSaleCartProvider.notifier).restore(restored);
      state =
          AsyncData(current.where((x) => x.id != id).toList(growable: false));
      totalCount = (totalCount - 1).clamp(0, 1 << 31);
      await _refreshAfterMutation();
      _setOperation(PosParkedSaleOperation.recallSuccess);
      return held;
    } catch (e) {
      lastFailure = _failure(e);
      _setOperation(_operationFor(lastFailure!));
      rethrow;
    } finally {
      _mutatingHolds.remove('recall:$id');
    }
  }

  Future<void> delete(String id, {String? reason}) async {
    _requirePermission(PosPermissionCodes.heldSalesCancel);
    if (!_mutatingHolds.add('cancel:$id')) return;
    final current = await future;
    _setOperation(PosParkedSaleOperation.cancelling);
    try {
      await _repository.cancel(id, reason: reason);
      state =
          AsyncData(current.where((x) => x.id != id).toList(growable: false));
      totalCount = (totalCount - 1).clamp(0, 1 << 31);
      await _refreshAfterMutation();
      _setOperation(PosParkedSaleOperation.cancelSuccess);
    } catch (e) {
      lastFailure = _failure(e);
      _setOperation(_operationFor(lastFailure!));
      rethrow;
    } finally {
      _mutatingHolds.remove('cancel:$id');
    }
  }

  Future<int> legacyRecordCount() => _storage.readAll().then((v) => v.length);

  Future<void> _refreshAfterMutation() async {
    final confirmed = state.valueOrNull ?? const <PosParkedSale>[];
    try {
      var result = await _repository.list(
        deviceId: _deviceId(),
        scope: scope.apiValue,
        page: page,
        pageSize: pageSize,
      );
      if (result.holds.isEmpty && result.totalCount > 0 && page > 1) {
        page = ((result.totalCount - 1) ~/ pageSize) + 1;
        result = await _repository.list(
          deviceId: _deviceId(),
          scope: scope.apiValue,
          page: page,
          pageSize: pageSize,
        );
      }
      _applyListMetadata(result);
      state = AsyncData(
        result.holds.map(PosParkedSale.fromBackend).toList(growable: false),
      );
      lastFailure = null;
    } catch (error) {
      lastFailure = _failure(error);
      state = AsyncData(confirmed);
    }
  }

  void _applyListMetadata(PosHoldListDto result) {
    totalCount = result.totalCount;
    totalValue = result.totalValue;
    currency = result.currency;
    page = result.page;
    pageSize = result.pageSize;
  }

  void _setOperation(PosParkedSaleOperation value) {
    operation = value;
    ref.read(posParkedSaleOperationProvider.notifier).state = value;
  }

  void _requirePermission(String code) {
    final context = ref.read(posParkedSaleAccessContextProvider);
    if (!context.authenticated) {
      throw PosCheckoutApiException(
          message: 'An authenticated session is required.',
          code: 'authentication_required',
          statusCode: 401);
    }
    if (!context.permissions.contains(code)) {
      throw PosCheckoutApiException(
          message: 'You do not have permission for this Park Sale action.',
          code: 'pos_holds.permission_denied',
          statusCode: 403);
    }
  }

  String _deviceId() {
    final context = ref.read(posParkedSaleAccessContextProvider);
    final id = context.deviceId?.trim() ?? '';
    if (!context.trustedDevice || id.isEmpty) {
      throw PosCheckoutApiException(
          message: 'An activated trusted device is required.',
          code: 'pos_checkout.device_not_found',
          statusCode: 404);
    }
    return id;
  }

  PosCheckoutApiException _failure(Object e) => e is PosCheckoutApiException
      ? e
      : PosCheckoutApiException(
          message: e is FormatException
              ? 'The Park Sale response was malformed.'
              : 'Park Sale operation failed.');

  PosParkedSaleOperation _operationFor(PosCheckoutApiException e) {
    if (_isSalePartiallyPaid(e.code)) {
      return PosParkedSaleOperation.partiallyPaidCannotPark;
    }
    if (e.statusCode == 401) {
      return PosParkedSaleOperation.authenticationFailure;
    }
    if (e.statusCode == 403) return PosParkedSaleOperation.permissionDenied;
    if (e.statusCode == 409) {
      return e.code == 'pos_holds.expired'
          ? PosParkedSaleOperation.expired
          : PosParkedSaleOperation.conflict;
    }
    if (e.isNetworkUnavailable) return PosParkedSaleOperation.networkFailure;
    if ((e.statusCode ?? 0) >= 500) return PosParkedSaleOperation.serverFailure;
    return PosParkedSaleOperation.validationFailure;
  }

  /// Matches `sale_partially_paid` and
  /// `pos_holds.sale_partially_paid_cannot_be_parked` backend error codes.
  bool _isSalePartiallyPaid(String? code) =>
      code?.contains('sale_partially_paid') == true;

  String _newIdempotencyKey() {
    final r = Random.secure();
    final bytes = List<int>.generate(16, (_) => r.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    final h = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return '${h.substring(0, 8)}-${h.substring(8, 12)}-${h.substring(12, 16)}-${h.substring(16, 20)}-${h.substring(20)}';
  }
}

enum PosParkedSaleOperation {
  idle,
  loadingList,
  creating,
  createSuccess,
  recalling,
  recallSuccess,
  cancelling,
  cancelSuccess,
  validationFailure,
  permissionDenied,
  authenticationFailure,
  conflict,
  expired,
  networkFailure,
  serverFailure,
  partiallyPaidCannotPark,
}

enum PosParkedSaleScope {
  today('today', 'Today'),
  currentShift('current-shift', 'This Shift'),
  allActive('all-active', 'All Parked Sales');

  const PosParkedSaleScope(this.apiValue, this.label);
  final String apiValue;
  final String label;
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
    this.status = 'Held',
    this.currency = 'LKR',
    this.expiresAt,
    this.backendItemCount,
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

  factory PosParkedSale.fromBackend(PosHoldDto dto) {
    return PosParkedSale(
      id: dto.holdId,
      reference: dto.holdNumber,
      createdAt: dto.heldAt,
      items: dto.lines.map((line) {
        final variantId = line.variantId ?? line.lineId;
        return PosNewSaleCartItem(
          product: PosNewSaleProduct(
            id: variantId,
            productId: variantId,
            variantId: line.variantId,
            name: line.name,
            category: '',
            price: line.unitPrice,
            sku: line.sku,
            imageUrl: line.imageUrl,
            selectedAttributes: {
              if (line.variantName?.trim().isNotEmpty == true)
                'Variant': line.variantName!.trim(),
            },
            lineNote: line.lineNote,
            authoritativePrice: line.unitPrice.toDouble(),
          ),
          quantity: line.qty,
        );
      }).toList(growable: false),
      customerId: dto.customerId,
      customerName: dto.customerName,
      note: dto.reason,
      subtotal: dto.subtotal,
      discount: dto.discount,
      tax: dto.tax,
      total: dto.total,
      status: dto.status,
      currency: dto.currency,
      expiresAt: dto.expiresAt,
      backendItemCount: dto.itemCount,
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
      status: json['status']?.toString() ?? 'Held',
      currency: json['currency']?.toString() ?? 'LKR',
      expiresAt: DateTime.tryParse(json['expiresAt']?.toString() ?? ''),
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
  final String status;
  final String currency;
  final DateTime? expiresAt;
  final int? backendItemCount;
  final int subtotal;
  final int discount;
  final int tax;
  final int total;

  int get itemCount =>
      backendItemCount ??
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
        .toList(growable: false);

    if (names.isEmpty) {
      return 'Items unavailable';
    }

    if (items.length <= 2) {
      return names.join(', ');
    }

    final extra = items.length - 2;
    return '${names.take(2).join(', ')} +$extra more';
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

  PosNewSaleCartState toRecalledCart(PosRecallHoldDto recalled) {
    final byVariant = <String, PosNewSaleCartItem>{
      for (final item in items)
        if (item.product.variantId?.isNotEmpty == true)
          item.product.variantId!: item,
    };
    final recalledItems = <String, PosNewSaleCartItem>{};
    for (final line in recalled.lines) {
      final prior = byVariant[line.variantId];
      if (prior == null) {
        throw const FormatException('Recall returned an unknown cart variant.');
      }
      final product = PosNewSaleProduct(
          id: prior.product.id,
          productId: prior.product.productId,
          variantId: line.variantId,
          name: prior.product.name,
          category: prior.product.category,
          price: prior.product.price,
          sku: prior.product.sku,
          imageUrl: prior.product.imageUrl,
          selectedAttributes: prior.product.selectedAttributes,
          clientLineId: line.clientLineId,
          uomId: line.uomId,
          lineNote: line.lineNote,
          source: line.source ?? prior.product.source,
          authoritativePrice: prior.product.price.toDouble());
      recalledItems[product.cartLineKey] =
          PosNewSaleCartItem(product: product, quantity: line.quantity);
    }
    final customerIdValue = recalled.customerId?.trim();
    return PosNewSaleCartState(
      items: recalledItems,
      editableSaleId: recalled.saleId,
      selectedCustomer: customerIdValue?.isNotEmpty == true
          ? PosCustomer(
              customerId: customerIdValue!,
              fullName: recalled.customerName ?? 'Customer',
              status: 'Active')
          : null,
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
      'status': status,
      'currency': currency,
      'expiresAt': expiresAt?.toUtc().toIso8601String(),
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
      'imageUrl': product.imageUrl,
      'stockLabel': product.stockLabel,
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
      imageUrl: _nullableString(product['imageUrl']),
      stockLabel: product['stockLabel']?.toString() ?? 'In Stock',
      hasVariants: product['hasVariants'] == true,
      selectedAttributes: _stringMap(product['selectedAttributes']),
      maxQuantity: _nullableInt(product['maxQuantity']),
      clientLineId: product['clientLineId']?.toString(),
      uomId: product['uomId']?.toString(),
      lineNote: product['lineNote']?.toString(),
      source: product['source']?.toString() ?? 'direct',
      recommendationParentProductId:
          product['recommendationParentProductId']?.toString(),
      recommendationRelationshipId:
          product['recommendationRelationshipId']?.toString(),
      authoritativePrice: (product['authoritativePrice'] as num?)?.toDouble(),
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
