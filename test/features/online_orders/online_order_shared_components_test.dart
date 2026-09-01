import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'dart:async';
import 'package:nytroz_pos/features/fulfilment_pickup/domain/entities/pos_online_order.dart';
import 'package:nytroz_pos/features/fulfilment_pickup/presentation/widgets/online_order_ui.dart';
import 'package:nytroz_pos/features/fulfilment_pickup/presentation/widgets/start_fulfilment_dialog.dart';
import 'package:nytroz_pos/shared/widgets/pos_action_buttons.dart';

void main() {
  group('PaymentStatusChip exact status mapping', () {
    test('maps every backend-supported status explicitly', () {
      expect(
        OnlineOrderPaymentStatusStyle.fromStatus('PAID'),
        OnlineOrderPaymentStatusStyle.paid,
      );
      expect(
        OnlineOrderPaymentStatusStyle.fromStatus('UNPAID'),
        OnlineOrderPaymentStatusStyle.pending,
      );
      expect(
        OnlineOrderPaymentStatusStyle.fromStatus('PARTIALLY_PAID'),
        OnlineOrderPaymentStatusStyle.pending,
      );
      expect(
        OnlineOrderPaymentStatusStyle.fromStatus('PARTIALLY_REFUNDED'),
        OnlineOrderPaymentStatusStyle.refunded,
      );
      expect(
        OnlineOrderPaymentStatusStyle.fromStatus('REFUNDED'),
        OnlineOrderPaymentStatusStyle.refunded,
      );
      expect(
        OnlineOrderPaymentStatusStyle.fromStatus('FAILED'),
        OnlineOrderPaymentStatusStyle.failed,
      );
    });

    test('normalizes case and safely falls back for unknown status', () {
      expect(
        OnlineOrderPaymentStatusStyle.fromStatus(' paid '),
        OnlineOrderPaymentStatusStyle.paid,
      );
      expect(
        OnlineOrderPaymentStatusStyle.fromStatus('future_status'),
        OnlineOrderPaymentStatusStyle.unknown,
      );
    });

    testWidgets('UNPAID never receives the PAID foreground style',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Row(
            children: [
              PaymentStatusChip(status: 'PAID'),
              PaymentStatusChip(status: 'UNPAID'),
            ],
          ),
        ),
      );

      final paid = tester.widget<Text>(find.text('PAID'));
      final unpaid = tester.widget<Text>(find.text('UNPAID'));
      expect(paid.style?.color, Colors.green.shade700);
      expect(unpaid.style?.color, Colors.orange.shade800);
      expect(unpaid.style?.color, isNot(paid.style?.color));
    });
  });

  testWidgets(
      'shared primary CTA supports theme colour, multiline icon and loading',
      (tester) async {
    const tenantPrimary = Color(0xFFFF1493);
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: tenantPrimary).copyWith(
            primary: tenantPrimary,
          ),
        ),
        home: Scaffold(
          body: Builder(
            builder: (context) => PosPrimaryActionButton(
              label: 'START\nFULFILMENT',
              onPressed: () {},
              backgroundColor: Theme.of(context).colorScheme.primary,
              leadingIcon: Icons.inventory_2_outlined,
              maxLabelLines: 2,
              iconSize: 26,
              fullWidth: true,
            ),
          ),
        ),
      ),
    );

    expect(find.text('START\nFULFILMENT'), findsOneWidget);
    expect(find.byIcon(Icons.inventory_2_outlined), findsOneWidget);
    final decoration = tester
        .widgetList<AnimatedContainer>(find.byType(AnimatedContainer))
        .map((widget) => widget.decoration)
        .whereType<BoxDecoration>()
        .firstWhere((value) => value.color == tenantPrimary);
    expect(decoration.color, tenantPrimary);

    await tester.pumpWidget(
      const MaterialApp(
        home: PosPrimaryActionButton(
          label: 'Start',
          onPressed: _noop,
          isLoading: true,
        ),
      ),
    );
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Start'), findsNothing);
  });

  group('StartFulfilmentDialog shared modal flow', () {
    testWidgets('shared dialog displays authority and Cancel returns false',
        (tester) async {
      Future<bool>? result;
      var starts = 0;
      await _pumpLauncher(
        tester,
        onConfirm: () async {
          starts++;
          return true;
        },
        onResult: (value) => result = value,
      );

      expect(find.byType(BackdropFilter), findsOneWidget);
      expect(find.text('Start Fulfilment?'), findsOneWidget);
      expect(find.byKey(const Key('oo03-dialog-icon')), findsOneWidget);
      expect(find.byKey(const Key('oo03-summary-card')), findsOneWidget);
      expect(
        find.text('You are about to start picking this order.\n'
            'This order will be assigned to you.'),
        findsOneWidget,
      );
      expect(find.byType(SingleChildScrollView), findsNothing);
      expect(
        find.bySemanticsLabel('Start fulfilment confirmation'),
        findsOneWidget,
      );
      expect(find.bySemanticsLabel('Yes, Start Fulfilment'), findsWidgets);
      expect(find.bySemanticsLabel('Cancel'), findsOneWidget);
      expect(find.text('ORDER-001'), findsOneWidget);
      expect(find.text('Customer One'), findsOneWidget);
      expect(find.text('Development Store'), findsOneWidget);
      expect(find.textContaining('2h 15m remaining'), findsOneWidget);
      expect(find.text('3 items • 4 units'), findsOneWidget);

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(await result, isFalse);
      expect(starts, 0);
    });

    testWidgets('shared dialog Confirm returns true exactly once',
        (tester) async {
      Future<bool>? result;
      var completions = 0;
      var starts = 0;
      await _pumpLauncher(
        tester,
        onConfirm: () async {
          starts++;
          return true;
        },
        onResult: (value) {
          result = value.whenComplete(() => completions++);
        },
      );

      await tester.tap(find.text('Yes, Start Fulfilment'));
      await tester.pumpAndSettle();
      expect(await result, isTrue);
      expect(completions, 1);
      expect(starts, 1);
    });

    testWidgets('pending Confirm shows loading and ignores duplicate taps',
        (tester) async {
      final pending = Completer<bool>();
      var starts = 0;
      await _pumpLauncher(
        tester,
        onConfirm: () {
          starts++;
          return pending.future;
        },
        onResult: (_) {},
      );

      await tester.tap(find.byKey(const Key('oo03-confirm-start')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('oo03-confirm-start')));
      await tester.pump();

      expect(starts, 1);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(
          tester.widget<OutlinedButton>(find.byType(OutlinedButton)).onPressed,
          isNull);

      pending.complete(true);
      await tester.pumpAndSettle();
    });

    for (final primary in [
      const Color(0xFFFF6A00),
      const Color(0xFFFF1493),
    ]) {
      testWidgets('Confirm follows ThemeData primary $primary', (tester) async {
        await _pumpLauncher(
          tester,
          primary: primary,
          onResult: (_) {},
        );

        final decoration = tester
            .widgetList<AnimatedContainer>(find.byType(AnimatedContainer))
            .map((widget) => widget.decoration)
            .whereType<BoxDecoration>()
            .firstWhere((value) => value.color == primary);
        expect(decoration.color, primary);
      });
    }
  });
}

Future<void> _pumpLauncher(
  WidgetTester tester, {
  required ValueChanged<Future<bool>> onResult,
  Future<bool> Function()? onConfirm,
  Color primary = const Color(0xFFFF6A00),
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: primary).copyWith(
          primary: primary,
        ),
      ),
      home: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () => onResult(
              StartFulfilmentDialog.show(
                context,
                _detail,
                onConfirm: onConfirm ?? () async => true,
              ),
            ),
            child: const Text('Open'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Open'));
  await tester.pumpAndSettle();
}

void _noop() {}

final _detail = PosOnlineOrderDetail(
  order: PosOnlineOrder(
    id: 'order-1',
    orderNumber: 'ORDER-001',
    customerName: 'Customer One',
    status: 'ACCEPTED',
    statusLabel: 'Accepted',
    paymentStatus: 'UNPAID',
    currencyCode: 'LKR',
    totalAmount: 4200,
    lineCount: 3,
    unitCount: 4,
    collectionAt: DateTime.utc(2026, 8, 31, 11, 38),
  ),
  outletName: 'Development Store',
  paymentStatus: 'UNPAID',
  subtotal: 4200,
  discount: 0,
  tax: 0,
  charges: 0,
  paid: 0,
  balanceDue: 4200,
  backendItemCount: 3,
  backendUnitCount: 4,
  serverTime: DateTime.utc(2026, 8, 31, 9, 23),
  lines: [
    PosOnlineOrderLine(
      id: 'line-1',
      lineNumber: 1,
      productName: 'Product One',
      quantity: 1,
      unitPrice: 4200,
      lineTotal: 4200,
      pickedQuantity: 0,
      packedQuantity: 0,
    ),
  ],
);
