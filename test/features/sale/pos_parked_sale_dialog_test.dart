import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nytroz_pos/features/sale/presentation/widgets/new_sale/pos_parked_sale_dialog.dart';

void main() {
  testWidgets('recall parked sale dialog shows empty state', (tester) async {
    FlutterSecureStorage.setMockInitialValues({});

    await tester.pumpWidget(const _DialogTestApp());

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.text('Recall Parked Sale'), findsOneWidget);
    expect(find.text('No parked sales'), findsOneWidget);
    expect(find.text('Saved parked sales will appear here.'), findsOneWidget);
    expect(find.widgetWithText(TextButton, 'Close'), findsOneWidget);
  });

  testWidgets('recall parked sale dialog shows saved parked sales', (
    tester,
  ) async {
    FlutterSecureStorage.setMockInitialValues({
      'pos.parked_sales': jsonEncode([_parkedSaleJson]),
    });

    await tester.pumpWidget(const _DialogTestApp());

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.text('Recall Parked Sale'), findsOneWidget);
    expect(find.text('Parked Sale #1'), findsOneWidget);
    expect(find.text('Walk-in customer'), findsOneWidget);
    expect(find.text('Items: General Admission'), findsOneWidget);
    expect(find.text('2 items'), findsOneWidget);
    expect(find.text('LKR 3,000.00'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Recall'), findsOneWidget);
    expect(find.byIcon(Icons.delete_outline_rounded), findsOneWidget);
  });

  testWidgets('recall parked sale dialog shows reference details', (
    tester,
  ) async {
    FlutterSecureStorage.setMockInitialValues({
      'pos.parked_sales': jsonEncode([
        {
          ..._parkedSaleJson,
          'referenceName': 'Token 12',
          'referencePhone': '0771234567',
          'note': 'Waiting near counter',
        },
      ]),
    });

    await tester.pumpWidget(const _DialogTestApp());

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.text('Token 12 • 0771234567'), findsOneWidget);
    expect(find.text('Waiting near counter'), findsOneWidget);
  });

  testWidgets('recall parked sale dialog shows customer details', (
    tester,
  ) async {
    FlutterSecureStorage.setMockInitialValues({
      'pos.parked_sales': jsonEncode([
        {
          ..._parkedSaleJson,
          'customerId': 'customer-1',
          'customerName': 'Tom',
          'customerPhone': '0771234567',
          'customerEmail': 'tom@example.com',
        },
      ]),
    });

    await tester.pumpWidget(const _DialogTestApp());

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.text('Tom • 0771234567 • tom@example.com'), findsOneWidget);
  });
}

class _DialogTestApp extends StatelessWidget {
  const _DialogTestApp();

  @override
  Widget build(BuildContext context) {
    return const ProviderScope(
      child: MaterialApp(
        home: Scaffold(
          body: Center(
            child: _OpenDialogButton(),
          ),
        ),
      ),
    );
  }
}

class _OpenDialogButton extends ConsumerWidget {
  const _OpenDialogButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FilledButton(
      onPressed: () => showPosParkedSaleDialog(context: context, ref: ref),
      child: const Text('Open'),
    );
  }
}

final _parkedSaleJson = {
  'id': 'parked-1',
  'reference': 'Parked Sale #1',
  'createdAt': '2026-07-01T10:30:00.000Z',
  'customer': null,
  'subtotal': 3000,
  'discount': 0,
  'tax': 0,
  'total': 3000,
  'items': [
    {
      'quantity': 2,
      'product': {
        'id': 'general-admission',
        'productId': 'general-admission',
        'variantId': null,
        'name': 'General Admission',
        'category': 'Tickets',
        'price': 1500,
        'sku': null,
        'stockLabel': 'In Stock',
        'hasVariants': false,
        'selectedAttributes': <String, String>{},
        'maxQuantity': null,
      },
    },
  ],
};
