import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nytroz_pos/core/access/effective_permission_set.dart';
import 'package:nytroz_pos/core/access/permission_access_providers.dart';
import 'package:nytroz_pos/core/access/pos_access_codes.dart';
import 'package:nytroz_pos/features/cart/presentation/providers/pos_new_sale_cart_provider.dart';
import 'package:nytroz_pos/features/sale/domain/entities/pos_payment_method_type.dart';
import 'package:nytroz_pos/features/sale/presentation/providers/pos_checkout_summary_provider.dart';
import 'package:nytroz_pos/features/sale/presentation/widgets/cash_payment/cash_payment_screen_body.dart';
import 'package:nytroz_pos/features/sale/presentation/widgets/payment_method/widgets/sale_summary/left_payment_summary_column.dart';

/// Cash accept + tender children + full numpad (Chunk 14 exact membership).
final _fullCashPaymentPermissions = EffectivePermissionSet.fromIterable({
  PosPermissionCodes.checkoutSale,
  PosPermissionCodes.acceptCashPayment,
  PosPermissionCodes.cashPaymentSummaryOrder,
  PosPermissionCodes.cashPaymentLineItem,
  PosPermissionCodes.cashPaymentLineQuantity,
  PosPermissionCodes.cashPaymentLinePrice,
  PosPermissionCodes.cashPaymentLineItemTotal,
  PosPermissionCodes.cashPaymentSummarySubtotal,
  PosPermissionCodes.cashPaymentSummaryDiscount,
  PosPermissionCodes.cashPaymentSummaryTax,
  PosPermissionCodes.cashPaymentSummaryTotalDue,
  PosPermissionCodes.cashPaymentTenderAmountReceivedView,
  PosPermissionCodes.cashPaymentTenderAmountReceivedEntry,
  PosPermissionCodes.cashPaymentTenderDueAmount,
  PosPermissionCodes.cashPaymentTenderExact,
  PosPermissionCodes.cashPaymentTenderChangeDue,
  PosPermissionCodes.cashPaymentQuickAmountsContainer,
  PosPermissionCodes.cashPaymentQuickAmountsSlot1,
  PosPermissionCodes.cashPaymentQuickAmountsSlot2,
  PosPermissionCodes.cashPaymentQuickAmountsSlot3,
  PosPermissionCodes.cashPaymentNumpadContainer,
  PosPermissionCodes.cashPaymentNumpadDigit0,
  PosPermissionCodes.cashPaymentNumpadDigit1,
  PosPermissionCodes.cashPaymentNumpadDigit2,
  PosPermissionCodes.cashPaymentNumpadDigit3,
  PosPermissionCodes.cashPaymentNumpadDigit4,
  PosPermissionCodes.cashPaymentNumpadDigit5,
  PosPermissionCodes.cashPaymentNumpadDigit6,
  PosPermissionCodes.cashPaymentNumpadDigit7,
  PosPermissionCodes.cashPaymentNumpadDigit8,
  PosPermissionCodes.cashPaymentNumpadDigit9,
  PosPermissionCodes.cashPaymentNumpadDigit00,
  PosPermissionCodes.cashPaymentNumpadDecimal,
  PosPermissionCodes.cashPaymentControlsBackspace,
  PosPermissionCodes.cashPaymentControlsClear,
  PosPermissionCodes.cashPaymentCompletionExecute,
});

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('cash screen reuses canonical sale summary and exposes target UI',
      (tester) async {
    var backPressed = false;
    await _pumpBody(tester, onBack: () => backPressed = true);

    expect(find.byType(LeftPaymentSummaryColumn), findsOneWidget);
    expect(find.byKey(const ValueKey('cash-payment-shared-sale-summary')),
        findsOneWidget);
    expect(find.text('SALE SUMMARY'), findsOneWidget);
    expect(find.text('CASH PAYMENT'), findsOneWidget);
    expect(
        find.text('Enter the amount received from customer.'), findsOneWidget);
    expect(find.text('AMOUNT RECEIVED'), findsOneWidget);
    expect(find.text('QUICK CASH'), findsOneWidget);
    expect(find.byKey(const ValueKey('cash-key-1')), findsOneWidget);
    expect(find.byKey(const ValueKey('cash-key-00')), findsOneWidget);
    expect(find.byKey(const ValueKey('cash-key-dot')), findsOneWidget);
    expect(find.byKey(const ValueKey('cash-key-backspace')), findsOneWidget);
    expect(find.byKey(const ValueKey('cash-key-clear')), findsOneWidget);
    expect(find.byKey(const ValueKey('cash-complete-sale')), findsOneWidget);
    expect(
        find.byKey(const ValueKey('cash-payment-info-card')), findsOneWidget);

    await tester
        .tap(find.byKey(const ValueKey('cash-back-to-payment-methods')));
    expect(backPressed, isTrue);
  });

  testWidgets('under exact and over tender states are distinct',
      (tester) async {
    await _pumpBody(tester, cashReceived: 0);
    expect(
        find.byKey(const ValueKey('cash-tender-status-under')), findsOneWidget);
    expect(find.text('AMOUNT REMAINING'), findsOneWidget);

    await _pumpBody(tester, cashReceived: 3200);
    expect(
        find.byKey(const ValueKey('cash-tender-status-exact')), findsOneWidget);
    expect(find.text('EXACT CASH RECEIVED'), findsOneWidget);

    await _pumpBody(tester, cashReceived: 5000);
    expect(
        find.byKey(const ValueKey('cash-tender-status-over')), findsOneWidget);
    expect(find.text('CHANGE DUE'), findsOneWidget);
  });

  for (final size in <Size>[const Size(1200, 700), const Size(900, 800)]) {
    testWidgets('cash target has no overflow at ${size.width}x${size.height}',
        (tester) async {
      await _pumpBody(tester, size: size);
      expect(find.byKey(const ValueKey('payment-method-workspace-card')),
          findsOneWidget);
    });
  }
}

Future<void> _pumpBody(
  WidgetTester tester, {
  Size size = const Size(1200, 800),
  int cashReceived = 0,
  VoidCallback? onBack,
}) async {
  await tester.binding.setSurfaceSize(size);
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        effectivePermissionSetProvider.overrideWithValue(
          _fullCashPaymentPermissions,
        ),
      ],
      child: MaterialApp(
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFFF5A00)),
        ),
        home: Scaffold(
          body: CashPaymentScreenBody(
            cart: _cart,
            summary: _summary,
            cashReceived: cashReceived,
            inputBuffer: cashReceived == 0 ? '' : '$cashReceived',
            quickAmounts: const [3200, 4000, 5000],
            selectedQuickAmount: null,
            onCustomerTap: () {},
            onBackToPaymentMethods: onBack ?? () {},
            onQuickAmountSelected: (_) {},
            onDigitPressed: (_) {},
            onDoubleZeroPressed: () {},
            onBackspacePressed: () {},
            onClearPressed: () {},
            isSubmitting: false,
            canCompleteSale: cashReceived >= 3200,
            onCompleteSalePressed: () {},
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

const _product = PosNewSaleProduct(
  id: 'line-1',
  productId: 'product-1',
  variantId: 'variant-1',
  name: 'Training Shoes',
  category: 'Footwear',
  price: 3200,
  selectedAttributes: {'Size': '8'},
);

const _cart = PosNewSaleCartState(
  items: {'line-1': PosNewSaleCartItem(product: _product)},
);

final _summary = PosCheckoutSummaryViewData(
  itemCount: 1,
  subtotal: 3200,
  discount: 0,
  tax: 0,
  totalPayable: 3200,
  saleType: 'New Sale',
  itemsInCart: 1,
  saleDate: DateTime(2026, 9, 4),
  cashierName: 'Cashier',
  paymentMethods: const [PosPaymentMethodType.cash],
  usedFallback: false,
);
