import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nytroz_pos/features/customers/presentation/widgets/customer_table_row.dart';
import 'package:nytroz_pos/features/customers/presentation/widgets/customers_table_section.dart';
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

  testWidgets('four-row paginated table fits and aligns secondary headers',
      (tester) async {
    final customers = List.generate(
      4,
      (index) => PosCustomer(
        customerId: 'cust-$index',
        customerCode: 'CUS00000$index',
        fullName: 'Customer $index',
        phone: '+1555000000$index',
        email: 'customer$index@example.com',
        status: 'ACTIVE',
        sourceType: 'POS',
        totalOrderCount: index,
        totalSpentAmount: index * 100,
        currencyCode: 'LKR',
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 1200,
              height: 320,
              child: CustomersTableSection(
                customers: customers,
                selectedCustomerId: null,
                isLoading: false,
                errorMessage: null,
                query: '',
                page: 1,
                totalPages: 3,
                rangeStart: 1,
                rangeEnd: 4,
                totalCount: 12,
                useCardLayout: false,
                showSecondaryColumns: true,
                onSelect: (_) {},
                onRetry: () {},
                onPageChanged: (_) {},
              ),
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('Customer ID'), findsOneWidget);
    expect(find.text('Source'), findsOneWidget);
    expect(find.text('Status'), findsOneWidget);
    expect(find.text('Orders'), findsOneWidget);
    expect(find.text('Showing 1 to 4 of 12 customers'), findsOneWidget);
  });
}
