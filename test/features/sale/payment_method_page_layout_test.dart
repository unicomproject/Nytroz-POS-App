import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nytroz_pos/features/cart/domain/entities/pos_cart_discount.dart';
import 'package:nytroz_pos/features/cart/presentation/providers/pos_new_sale_cart_provider.dart';
import 'package:nytroz_pos/features/sale/domain/entities/pos_payment_method_type.dart';
import 'package:nytroz_pos/features/sale/presentation/providers/pos_checkout_summary_provider.dart';
import 'package:nytroz_pos/features/sale/presentation/widgets/payment_method/pages/payment_method_page.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('no discount expands summary and omits discount card',
      (tester) async {
    await _pumpPage(tester, cart: _cart());
    expect(find.byKey(const ValueKey('sale-summary-card')), findsOneWidget);
    expect(find.byKey(const ValueKey('payment-customer-card')), findsOneWidget);
    expect(find.byKey(const ValueKey('payment-discount-card')), findsNothing);
    expect(find.byKey(const ValueKey('payment-product-list')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('applied discount appears and reduces summary height',
      (tester) async {
    await _pumpPage(tester, cart: _cart());
    final withoutDiscount = tester
        .getSize(
          find.byKey(const ValueKey('sale-summary-card')),
        )
        .height;

    await _pumpPage(tester, cart: _cart(discount: true));
    final withDiscount = tester
        .getSize(
          find.byKey(const ValueKey('sale-summary-card')),
        )
        .height;
    expect(find.byKey(const ValueKey('payment-discount-card')), findsOneWidget);
    expect(withDiscount, lessThan(withoutDiscount));
    expect(find.byType(ListView), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('four equal methods and authoritative totals fit tablet height',
      (tester) async {
    await _pumpPage(tester, cart: _cart(discount: true), height: 700);
    final cards = PosPaymentMethodType.values
        .map((method) => find.byKey(ValueKey('payment-method-${method.name}')))
        .toList();
    for (final card in cards) {
      expect(card, findsOneWidget);
    }
    final first = tester.getSize(cards.first);
    for (final card in cards.skip(1)) {
      expect(tester.getSize(card).width, closeTo(first.width, .01));
      expect(tester.getSize(card).height, closeTo(first.height, .01));
    }
    expect(find.text('LKR 3,200.00'), findsWidgets);
    expect(
        find.byKey(const ValueKey('continue-payment-button')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

Future<void> _pumpPage(
  WidgetTester tester, {
  required PosNewSaleCartState cart,
  double height = 800,
}) async {
  await tester.binding.setSurfaceSize(Size(1200, height));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(
            size: Size(1200, height),
            textScaler: TextScaler.noScaling,
          ),
          child: PaymentMethodPage(
            summary: _summary(discount: cart.discount),
            cart: cart,
            allowedMethods: PosPaymentMethodType.values.toSet(),
            selectedMethod: null,
            isNavigating: false,
            onSelectMethod: (_) {},
            onContinue: null,
            showChrome: false,
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

PosNewSaleCartState _cart({bool discount = false}) {
  const product = PosNewSaleProduct(
    id: 'line-1',
    productId: 'product-1',
    variantId: 'variant-1',
    name: 'Training Jersey',
    category: 'Apparel',
    price: 3200,
    selectedAttributes: {'Size': 'Small'},
  );
  return PosNewSaleCartState(
    items: const {
      'line-1': PosNewSaleCartItem(product: product),
    },
    cartDiscount: discount
        ? const PosCartDiscount(
            valueType: PosDiscountValueType.fixedAmount,
            value: 200,
            reason: 'Approved offer',
            applicationId: 'application-1',
            status: 'applied',
          )
        : null,
  );
}

PosCheckoutSummaryViewData _summary({required int discount}) =>
    PosCheckoutSummaryViewData(
      itemCount: 1,
      subtotal: 3200,
      discount: discount,
      tax: 0,
      totalPayable: 3200 - discount,
      saleType: 'New Sale',
      itemsInCart: 1,
      saleDate: DateTime(2026, 8, 3),
      cashierName: 'Cashier',
      paymentMethods: PosPaymentMethodType.values,
      usedFallback: false,
    );
