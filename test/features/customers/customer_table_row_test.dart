import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nytroz_pos/core/access/effective_permission_set.dart';
import 'package:nytroz_pos/core/access/permission_access_providers.dart';
import 'package:nytroz_pos/core/access/pos_access_codes.dart';
import 'package:nytroz_pos/features/customers/presentation/widgets/customer_table_row.dart';
import 'package:nytroz_pos/features/customers/presentation/widgets/customers_table_section.dart';
import 'package:nytroz_pos/features/sale/domain/entities/pos_customer.dart';

/// Secondary-column list fields needed for row/header assertions.
final _fullListColumnPermissions = EffectivePermissionSet.fromIterable({
  PosPermissionCodes.customersListId,
  PosPermissionCodes.customersListName,
  PosPermissionCodes.customersListPhone,
  PosPermissionCodes.customersListEmail,
  PosPermissionCodes.customersListSource,
  PosPermissionCodes.customersListStatus,
  PosPermissionCodes.customersListOrderCount,
  PosPermissionCodes.customersListTotalSpend,
});

void main() {
  Future<void> pumpWithPermissions(
    WidgetTester tester,
    Widget child, {
    EffectivePermissionSet? permissions,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          effectivePermissionSetProvider.overrideWithValue(
            permissions ?? _fullListColumnPermissions,
          ),
        ],
        child: MaterialApp(
          home: Scaffold(body: child),
        ),
      ),
    );
  }

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

    await pumpWithPermissions(
      tester,
      CustomerTableRow(
        customer: customer,
        selected: false,
        showSecondaryColumns: true,
        onSelect: () {},
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

    await pumpWithPermissions(
      tester,
      CustomerTableRow(
        customer: customer,
        selected: false,
        showSecondaryColumns: true,
        onSelect: () {},
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

    await pumpWithPermissions(
      tester,
      Center(
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
    );

    expect(tester.takeException(), isNull);
    expect(find.text('Customer ID'), findsOneWidget);
    expect(find.text('Source'), findsOneWidget);
    expect(find.text('Status'), findsOneWidget);
    expect(find.text('Orders'), findsOneWidget);
    expect(find.text('Showing 1 to 4 of 12 customers'), findsOneWidget);
  });
}
