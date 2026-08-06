import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nytroz_pos/features/sale/presentation/providers/pos_checkout_summary_provider.dart';
import 'package:nytroz_pos/features/sale/presentation/screens/pos_payment_placeholder_screen.dart';

void main() {
  testWidgets('card screen reports provider unavailable without fake charge',
      (tester) async {
    final summary = PosCheckoutSummaryViewData(
      itemCount: 1,
      subtotal: 1000,
      discount: 0,
      tax: 0,
      totalPayable: 1000,
      saleType: 'New Sale',
      itemsInCart: 1,
      saleDate: DateTime.utc(2026, 7, 29),
      cashierName: 'Cashier',
      paymentMethods: const [],
      usedFallback: false,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          posCheckoutSummaryProvider.overrideWith((ref) async => summary),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: PosPaymentPlaceholderScreen(
              title: 'Card Payment',
              subtitle: 'Accept card payment from customer',
              unavailableMessage:
                  'No supported card provider or terminal is configured. '
                  'No charge was initiated.',
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Card terminal unavailable'), findsOneWidget);
    expect(find.textContaining('No charge was initiated'), findsOneWidget);
    expect(find.text('Coming Soon'), findsNothing);
    expect(find.byIcon(Icons.credit_card_off_outlined), findsOneWidget);
  });
}
