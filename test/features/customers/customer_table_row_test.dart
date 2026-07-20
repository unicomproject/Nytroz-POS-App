import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nytroz_pos/features/customers/presentation/widgets/customer_table_row.dart';
import 'package:nytroz_pos/features/sale/domain/entities/pos_customer.dart';

void main() {
  testWidgets('CustomerTableRow binds source, orders, and spent display',
      (tester) async {
    const customer = PosCustomer(
      customerId: 'cust-1',
      fullName: 'Table Customer',
      status: 'ACTIVE',
      sourceType: 'POS',
      totalOrderCount: 0,
      totalSpentAmount: 125.5,
      currencyCode: 'USD',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CustomerTableRow(
            customer: customer,
            selected: false,
            showSecondaryColumns: true,
            onSelect: () {},
          ),
        ),
      ),
    );

    expect(find.text('POS'), findsOneWidget);
    expect(find.text('0'), findsOneWidget);
    expect(find.text('USD 125.50'), findsOneWidget);
  });

  testWidgets('CustomerTableRow shows em dash for mixed currency spend',
      (tester) async {
    const customer = PosCustomer(
      customerId: 'cust-2',
      fullName: 'Mixed Customer',
      phone: '+100',
      email: 'mixed@example.com',
      status: 'ACTIVE',
      sourceType: 'ECOMMERCE',
      totalOrderCount: 4,
      totalSpentAmount: 999,
      currencyCode: 'LKR',
      isMixedCurrencySpend: true,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CustomerTableRow(
            customer: customer,
            selected: false,
            showSecondaryColumns: true,
            onSelect: () {},
          ),
        ),
      ),
    );

    expect(find.text('ECOMMERCE'), findsOneWidget);
    expect(find.text('4'), findsOneWidget);
    expect(find.text(customer.spentDisplay), findsOneWidget);
  });
}
