import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nytroz_pos/features/sale/domain/entities/pos_receipt_snapshot.dart';
import 'package:nytroz_pos/features/sale/presentation/providers/pos_cash_payment_success_provider.dart';
import 'package:nytroz_pos/features/sale/presentation/widgets/payment_success/payment_success_screen_body.dart';
import 'package:nytroz_pos/features/sale/presentation/widgets/payment_success/receipt/payment_success_receipt_preview.dart';
import 'package:nytroz_pos/shared/pos_session/pos_session_context.dart';

void main() {
  testWidgets('receipt preview supports intrinsic measurement', (tester) async {
    final snapshot = PosReceiptSnapshot.fromJson({
      'branding': {'merchantName': 'OneVerz'},
      'receiptIdentity': {
        'receiptId': 'receipt-1',
        'receiptNumber': 'R-001',
        'issuedAt': '2026-08-06T09:08:00Z',
      },
      'operator': {'cashierName': 'Cashier'},
      'items': const [],
      'totals': const {},
      'tenders': const [],
      'presentation': const {},
      'copyPolicy': const {},
    });

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 400,
              child: IntrinsicHeight(
                child: PaymentSuccessReceiptPreview(snapshot: snapshot),
              ),
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('R-001'), findsOneWidget);
  });

  for (final size in <Size>[
    const Size(1400, 620),
    const Size(720, 480),
  ]) {
    testWidgets(
        'success screen fits ${size.width}x${size.height} with equal cards',
        (tester) async {
      await tester.binding.setSurfaceSize(size);
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: PaymentSuccessScreenBody(
                successData: _successData,
                cashierName: 'Cashier',
                sessionContext: _sessionContext,
              ),
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.byType(SingleChildScrollView), findsOneWidget);
      expect(find.text('Sale Completed'), findsOneWidget);
      expect(find.text('Start New Sale'), findsOneWidget);

      final summarySize = tester.getSize(
        find.byKey(const Key('payment-success-summary-card')),
      );
      final receiptSize = tester.getSize(
        find.byKey(const Key('payment-success-receipt-card')),
      );
      if (size.width >= 900) {
        expect(summarySize.width, closeTo(receiptSize.width, 0.01));
        expect(summarySize.height, closeTo(receiptSize.height, 0.01));
      } else {
        expect(summarySize.height, closeTo(receiptSize.height, 0.01));
        expect(summarySize.width, closeTo(receiptSize.width, 0.01));
      }
    });
  }

  testWidgets('Print Receipt runs directly without opening a dialog',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: PaymentSuccessScreenBody(
              successData: _successData,
              cashierName: 'Cashier',
              sessionContext: _sessionContext,
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Print Receipt'));
    await tester.pumpAndSettle();

    expect(find.byType(Dialog), findsNothing);
    // Provider not seeded with authoritative checkout payload in this widget
    // harness; first-print mapping correctly refuses instead of opening a dialog.
    expect(
      find.text('Completed sale receipt data is unavailable for printing.'),
      findsOneWidget,
    );
  });

  testWidgets(
      'displays selected customer name on Left summary and Right receipt preview',
      (tester) async {
    final customSuccessData = PosCashPaymentSuccessData(
      receiptNumber: 'RCP-000100',
      barcodeValue: 'RCP-000100',
      saleId: 'sale-1',
      customerName: 'Maya Silva',
      customerPhone: '+94771234567',
      completedAt: DateTime.utc(2026, 8, 8, 6, 34),
      itemCount: 2,
      subtotal: 570000,
      discount: 0,
      tax: 0,
      total: 570000,
      cashReceived: 570000,
      changeDue: 0,
      items: const [
        PosCashPaymentSuccessLineItem(
          name: 'Team Jersey',
          quantity: 1,
          unitPrice: 450000,
          lineTotal: 450000,
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: PaymentSuccessScreenBody(
              successData: customSuccessData,
              cashierName: 'Kavin',
              sessionContext: _sessionContext,
            ),
          ),
        ),
      ),
    );

    expect(find.text('Customer'), findsWidgets);
    expect(find.text('Maya Silva'), findsWidgets);
  });

  testWidgets('displays Walk-in Customer fallback when customer is null',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: PaymentSuccessScreenBody(
              successData: _successData,
              cashierName: 'Kavin',
              sessionContext: _sessionContext,
            ),
          ),
        ),
      ),
    );

    expect(find.text('Customer'), findsWidgets);
    expect(find.text('Walk-in Customer'), findsWidgets);
  });
}

final _successData = PosCashPaymentSuccessData(
  receiptNumber: 'R-001',
  barcodeValue: 'R-001',
  saleId: 'sale-1',
  completedAt: DateTime.utc(2026, 8, 6, 9, 8),
  itemCount: 1,
  subtotal: 280000,
  discount: 0,
  tax: 0,
  total: 280000,
  cashReceived: 300000,
  changeDue: 20000,
  items: const [
    PosCashPaymentSuccessLineItem(
      name: 'Match Shorts',
      quantity: 1,
      unitPrice: 280000,
      lineTotal: 280000,
      variantSummary: 'Small',
    ),
  ],
);

const _sessionContext = PosSessionContext(
  brandName: 'OneVerz',
  brandSubtitle: 'POS',
  outletName: 'Main Outlet',
  outletLocation: 'Colombo',
  tillName: 'Till 01',
  tillStatus: 'Open',
  userName: 'Cashier',
  userRole: 'Cashier',
  deviceName: 'POS 01',
  deviceCode: 'POS-01',
  systemStatus: 'Online',
  lastSyncLabel: 'Now',
);
