import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';

import '../../../../core/network/dio_provider.dart';
import '../../../auth/domain/entities/auth_session.dart';
import '../../../auth/presentation/providers/session_provider.dart';
import '../../../cart/presentation/providers/pos_new_sale_cart_provider.dart';
import '../../../device_activation/presentation/providers/device_activation_provider.dart';
import '../../data/datasources/pos_checkout_remote_datasource.dart';
import '../../domain/entities/pos_checkout_api_exception.dart';
import '../../domain/entities/pos_checkout_summary.dart';
import '../../domain/entities/pos_payment_method_type.dart';

final posCheckoutRemoteDatasourceProvider =
    Provider<PosCheckoutRemoteDatasource>((ref) {
  return PosCheckoutRemoteDatasource(ref.watch(appDioProvider));
});

const checkoutFallbackUnavailableMessage =
    'Backend validation is unavailable. You can review local totals, but checkout cannot continue until the server responds.';

class PosCheckoutSummaryViewData {
  const PosCheckoutSummaryViewData({
    required this.itemCount,
    required this.subtotal,
    required this.discount,
    required this.tax,
    required this.totalPayable,
    required this.saleType,
    required this.itemsInCart,
    required this.saleDate,
    required this.cashierName,
    required this.paymentMethods,
    required this.usedFallback,
    this.currency = '',
    this.pricingInputFingerprint = '',
    this.fallbackMessage,
    this.validationMessages = const [],
    this.calculatedLines = const [],
    this.linesByClientLineId = const {},
  });

  final int itemCount;
  final int subtotal;
  final int discount;
  final int tax;
  final int totalPayable;
  final String saleType;
  final int itemsInCart;
  final DateTime saleDate;
  final String cashierName;
  final List<PosPaymentMethodType> paymentMethods;
  final bool usedFallback;
  final String currency;
  final String pricingInputFingerprint;
  final String? fallbackMessage;
  final List<String> validationMessages;
  final List<PosCalculatedCartLinePayload> calculatedLines;
  final Map<String, PosCalculatedCartLinePayload> linesByClientLineId;

  factory PosCheckoutSummaryViewData.fallback({
    required PosNewSaleCartState cart,
    required AuthSession? session,
    required Set<String> grantedPermissions,
    String? fallbackMessage,
  }) {
    final itemCount =
        cart.itemList.fold<int>(0, (sum, item) => sum + item.quantity);

    return PosCheckoutSummaryViewData(
      itemCount: itemCount,
      subtotal: cart.subtotal,
      discount: cart.discount,
      tax: cart.tax,
      totalPayable: cart.total,
      saleType: 'New Sale',
      itemsInCart: itemCount,
      saleDate: DateTime.now(),
      cashierName: session?.userDisplayName.trim().isNotEmpty == true
          ? session!.userDisplayName.trim()
          : 'Cashier',
      paymentMethods: allowedPosPaymentMethods(grantedPermissions),
      usedFallback: true,
      currency: '',
      pricingInputFingerprint: checkoutPricingInputFingerprint(cart),
      fallbackMessage: fallbackMessage ?? checkoutFallbackUnavailableMessage,
    );
  }

  static Map<String, PosCalculatedCartLinePayload> _indexLinesByClientLineId(
    List<PosCalculatedCartLinePayload> lines,
  ) {
    final indexed = <String, PosCalculatedCartLinePayload>{};
    for (final line in lines) {
      final clientLineId = line.clientLineId?.trim();
      if (clientLineId == null || clientLineId.isEmpty) {
        continue;
      }
      indexed[clientLineId] = line;
    }
    return indexed;
  }

  factory PosCheckoutSummaryViewData.fromPayload({
    required PosCheckoutSummaryPayload payload,
    required PosNewSaleCartState cart,
    required Set<String> grantedPermissions,
  }) {
    final apiMethods = paymentMethodsFromApiCodes(payload.paymentMethods);
    final sessionMethods = allowedPosPaymentMethods(grantedPermissions);
    final methods =
        apiMethods.where(sessionMethods.contains).toList(growable: false);

    final subtotal = payload.billingSummary.subtotal;
    final tax = payload.billingSummary.tax;

    return PosCheckoutSummaryViewData(
      itemCount: payload.billingSummary.itemCount,
      subtotal: subtotal,
      discount: payload.billingSummary.discount,
      tax: tax,
      totalPayable: payload.billingSummary.totalPayable,
      saleType: payload.saleDetails.saleType,
      itemsInCart: payload.saleDetails.itemsInCart,
      saleDate: payload.saleDetails.saleDate,
      cashierName: payload.saleDetails.cashierName,
      paymentMethods: methods,
      usedFallback: false,
      currency: payload.billingSummary.currency,
      pricingInputFingerprint: checkoutPricingInputFingerprint(cart),
      validationMessages: payload.validationMessages,
      calculatedLines: payload.lines,
      linesByClientLineId: _indexLinesByClientLineId(payload.lines),
    );
  }
}

final posCheckoutSummaryProvider =
    FutureProvider.autoDispose<PosCheckoutSummaryViewData>((ref) async {
  final cart = ref.watch(posNewSaleCartProvider);
  final session = ref.watch(authSessionProvider);
  final deviceContext = ref.watch(deviceActivationProvider).deviceContext;
  final grantedPermissions = session?.permissionCodes.toSet() ?? const {};

  if (!cart.hasItems) {
    throw PosCheckoutApiException(
      message: 'Checkout summary requires cart items.',
    );
  }

  if (session == null || !session.isAuthenticated || deviceContext == null) {
    throw PosCheckoutApiException(
      message: 'Checkout requires an active session and activated device.',
    );
  }

  _ensureAuthorizationHeader(ref.read(appDioProvider), session);

  final lines = checkoutLinesFromCart(cart);
  if (lines.isEmpty) {
    throw PosCheckoutApiException(
      message: 'Checkout summary requires valid cart line items.',
    );
  }

  try {
    final payload =
        await ref.watch(posCheckoutRemoteDatasourceProvider).getCheckoutSummary(
              deviceId: deviceContext.deviceId,
              lines: lines,
              customerId: cart.selectedCustomer?.customerId,
              discountApplicationId: cart.discountApplicationId,
            );

    return PosCheckoutSummaryViewData.fromPayload(
      payload: payload,
      cart: cart,
      grantedPermissions: grantedPermissions,
    );
  } on PosCheckoutApiException catch (error) {
    if (error.isNetworkUnavailable) {
      return PosCheckoutSummaryViewData.fallback(
        cart: cart,
        session: session,
        grantedPermissions: grantedPermissions,
        fallbackMessage: error.message,
      );
    }

    rethrow;
  }
});

String checkoutPricingInputFingerprint(PosNewSaleCartState cart) {
  final lines = cart.itemList
      .map((item) => [
            item.product.clientLineId ?? '',
            item.product.cartLineKey,
            item.product.variantId ?? '',
            item.product.uomId ?? '',
            item.quantity,
            item.product.normalizedLineNote,
          ].join(':'))
      .toList(growable: false)
    ..sort();
  return [
    ...lines,
    'customer:${cart.selectedCustomer?.customerId ?? ''}',
    'discount:${cart.discountApplicationId ?? ''}',
  ].join('|');
}

PosCalculatedCartLinePayload? authoritativeLinePricingFor({
  required PosNewSaleCartItem item,
  required PosCheckoutSummaryViewData pricing,
}) {
  final clientLineId = item.product.clientLineId?.trim();
  if (clientLineId != null && clientLineId.isNotEmpty) {
    return pricing.linesByClientLineId[clientLineId];
  }

  final matches = pricing.calculatedLines.where((line) {
    return line.variantId == (item.product.variantId ?? '') &&
        (line.uomId ?? '') == (item.product.uomId ?? '') &&
        (line.lineNote ?? '') == item.product.normalizedLineNote &&
        line.quantity == item.quantity;
  }).toList(growable: false);

  if (matches.length == 1) {
    return matches.single;
  }

  return null;
}

String formatCheckoutMoney(String currency, int value) {
  final normalizedCurrency = currency.trim();
  if (normalizedCurrency.isEmpty) {
    return formatLkr(value);
  }
  return '$normalizedCurrency ${formatLkr(value).replaceFirst('LKR ', '')}';
}

bool isCurrentAuthoritativePricing({
  required PosNewSaleCartState cart,
  required PosCheckoutSummaryViewData pricing,
}) =>
    cart.hasItems &&
    !pricing.usedFallback &&
    pricing.pricingInputFingerprint == checkoutPricingInputFingerprint(cart);

List<PosCheckoutLineRequest> checkoutLinesFromCart(PosNewSaleCartState cart) {
  return cart.itemList
      .map(
        (item) => PosCheckoutLineRequest(
          variantId: item.product.variantId ?? '',
          quantity: item.quantity,
          clientLineId: item.product.clientLineId,
          uomId: item.product.uomId,
          lineNote: item.product.normalizedLineNote.isEmpty
              ? null
              : item.product.normalizedLineNote,
          source: item.product.source,
          recommendationParentProductId:
              item.product.recommendationParentProductId,
          recommendationRelationshipId:
              item.product.recommendationRelationshipId,
        ),
      )
      .toList(growable: false);
}

String checkoutApiPaymentMethodCode(PosPaymentMethodType method) {
  return switch (method) {
    PosPaymentMethodType.cash => 'cash',
    PosPaymentMethodType.card => 'card',
    PosPaymentMethodType.qrMobile => 'qr',
    PosPaymentMethodType.split => 'split',
  };
}

void _ensureAuthorizationHeader(Dio dio, AuthSession session) {
  final currentValue = dio.options.headers['Authorization'];
  if (currentValue is String && currentValue.trim().isNotEmpty) {
    return;
  }

  dio.options.headers['Authorization'] = 'Bearer ${session.accessToken}';
}

List<PosPaymentMethodType> paymentMethodsFromApiCodes(List<String> codes) {
  final normalized = codes.map((code) => code.toLowerCase()).toSet();
  return PosPaymentMethodType.values
      .where(
          (method) => normalized.contains(checkoutApiPaymentMethodCode(method)))
      .toList(growable: false);
}
