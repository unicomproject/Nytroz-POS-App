import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nytroz_pos/features/tenant_admin/tills/domain/entities/till_create_options.dart';
import 'package:nytroz_pos/features/tenant_admin/tills/presentation/providers/till_providers.dart';
import 'package:nytroz_pos/features/tenant_admin/tills/presentation/widgets/add_till_single_page_form.dart';

void main() {
  testWidgets('AddTillSinglePageForm handles outlet change without dropdown assertion', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    const baseOptions = TillCreateOptions(
      outlets: [
        TillOutletOption(id: 'out1', name: 'Outlet 1', code: 'O1', status: 'ACTIVE'),
        TillOutletOption(id: 'out2', name: 'Outlet 2', code: 'O2', status: 'ACTIVE'),
      ],
      cashiers: [
        TillCashierOption(id: 'c1', displayName: 'Cashier 1', outletIds: ['out1']),
        TillCashierOption(id: 'c2', displayName: 'Cashier 2', outletIds: ['out2']),
      ],
      posDevices: [
        TillPosDeviceOption(id: 'p1', code: 'P1', name: 'POS 1', outletId: 'out1', status: 'ACTIVE', isTrusted: true, isAssigned: false),
        TillPosDeviceOption(id: 'p1_dup', code: 'P1', name: 'POS 1 Dup', outletId: 'out1', status: 'ACTIVE', isTrusted: true, isAssigned: false),
      ],
      hardwareDevices: [
        TillHardwareDeviceOption(id: 'h1', code: 'H1', name: 'Scan 1', type: 'barcode_scanner', outletId: 'out1', status: 'ACTIVE', isAssigned: false, connectionStatus: 'ONLINE'),
        TillHardwareDeviceOption(id: 'h2', code: 'H2', name: 'Scan 2', type: 'barcode_scanner', outletId: 'out2', status: 'ACTIVE', isAssigned: false, connectionStatus: 'ONLINE'),
      ],
      statuses: ['ACTIVE', 'INACTIVE', 'ACTIVE'], // deliberate duplicate
      currencyCode: 'USD',
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          tillCreateOptionsProvider(null).overrideWith((ref) => baseOptions),
          tillCreateOptionsProvider('out1').overrideWith((ref) => baseOptions),
          tillCreateOptionsProvider('out2').overrideWith((ref) => baseOptions),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: AddTillSinglePageForm(
                options: baseOptions,
                canManageHardware: true,
                canViewHardware: true,
              ),
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify Outlet dropdown exists
    final outletDropdown = find.widgetWithText(DropdownButtonFormField<String>, 'Assign Outlet *');
    expect(outletDropdown, findsOneWidget);

    // Initial state: nothing selected, no assertion.
    // Let's tap the dropdown and select Outlet 1
    await tester.tap(outletDropdown);
    await tester.pumpAndSettle();
    
    // Select Outlet 1
    await tester.tap(find.text('Outlet 1').last);
    await tester.pumpAndSettle();

    // Now select Cashier 1
    final cashierDropdown = find.widgetWithText(DropdownButtonFormField<String>, 'Default Cashier *');
    await tester.tap(cashierDropdown);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cashier 1').last);
    await tester.pumpAndSettle();

    // Select POS Device 1 (has a duplicate ID test case)
    final posDropdown = find.widgetWithText(DropdownMenu<String>, 'Device Name');
    await tester.tap(posDropdown);
    await tester.pumpAndSettle();
    await tester.tap(find.text('POS 1').last);
    await tester.pumpAndSettle();

    // Now change Outlet to Outlet 2
    await tester.tap(outletDropdown);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Outlet 2').last);
    
    // Wait for rebuilds, which triggers the options reload and clears the dependent fields.
    // If there is a DropdownButton assertion, pumpAndSettle will fail with an exception.
    await tester.pumpAndSettle();
    
    // Ensure the dependent dropdowns did not crash and are available
    expect(find.widgetWithText(DropdownButtonFormField<String>, 'Assign Outlet *'), findsOneWidget);
    expect(find.widgetWithText(DropdownButtonFormField<String>, 'Default Cashier *'), findsOneWidget);
  });
}
