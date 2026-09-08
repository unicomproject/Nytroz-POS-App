import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nytroz_pos/features/tenant_admin/tills/domain/entities/till_create_options.dart';
import 'package:nytroz_pos/features/tenant_admin/tills/presentation/providers/till_providers.dart';
import 'package:nytroz_pos/features/tenant_admin/tills/presentation/widgets/add_till_setup_wizard.dart';

void main() {
  testWidgets('renders professional three-step till setup', (tester) async {
    await _pumpWizard(tester);

    expect(find.text('Till Details'), findsWidgets);
    expect(find.text('Hardware Setup'), findsOneWidget);
    expect(find.text('Review & Create'), findsOneWidget);
    expect(find.text('Continue'), findsOneWidget);
    expect(find.text('Zebra Barcode Scanner'), findsNothing);
  });

  testWidgets('configures real outlet hardware and reviews readiness',
      (tester) async {
    await _pumpWizard(tester);

    await tester.enterText(find.byType(TextFormField).at(0), 'Front Till');
    await tester.enterText(find.byType(TextFormField).at(1), 'FRONT-01');
    await tester.tap(find.byKey(const ValueKey('outlet_dropdown')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Main Outlet').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('cashier_dropdown_outlet-1')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Kavin').last);
    await tester.pumpAndSettle();

    await _tapVisible(tester, find.text('Continue'));
    await tester.pumpAndSettle();

    expect(find.text('Configure hardware now'), findsOneWidget);
    expect(find.text('Set up later'), findsOneWidget);
    expect(find.text('Refresh devices'), findsOneWidget);
    expect(find.byKey(const ValueKey('Scanner_outlet-1')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('Scanner_outlet-1')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Counter Scanner').last);
    await tester.pumpAndSettle();
    await _tapVisible(tester, find.text('Continue'));
    await tester.pumpAndSettle();

    expect(find.text('Hardware readiness'), findsOneWidget);
    expect(find.text('1 device selected'), findsOneWidget);
    expect(find.text('Counter Scanner (SCAN-01)'), findsOneWidget);
    expect(find.text('Create Till'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('allows setup later when hardware permission is unavailable',
      (tester) async {
    await _pumpWizard(
      tester,
      canViewHardware: false,
      canManageHardware: false,
    );

    await tester.enterText(find.byType(TextFormField).at(0), 'Front Till');
    await tester.enterText(find.byType(TextFormField).at(1), 'FRONT-01');
    await tester.tap(find.byKey(const ValueKey('outlet_dropdown')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Main Outlet').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('cashier_dropdown_outlet-1')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Kavin').last);
    await tester.pumpAndSettle();
    await _tapVisible(tester, find.text('Continue'));
    await tester.pumpAndSettle();

    expect(find.text('Hardware access is not available'), findsOneWidget);
    expect(find.text('Continue'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

Future<void> _tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
}

Future<void> _pumpWizard(
  WidgetTester tester, {
  bool canViewHardware = true,
  bool canManageHardware = true,
}) async {
  await tester.binding.setSurfaceSize(const Size(1200, 1000));
  addTearDown(() => tester.binding.setSurfaceSize(null));

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        tillCreateOptionsProvider(null).overrideWith((ref) async => _options),
        tillCreateOptionsProvider('outlet-1')
            .overrideWith((ref) async => _options),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: AddTillSetupWizard(
              options: _options,
              canViewHardware: canViewHardware,
              canManageHardware: canManageHardware,
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

const _options = TillCreateOptions(
  outlets: [
    TillOutletOption(
      id: 'outlet-1',
      name: 'Main Outlet',
      code: 'MAIN',
      status: 'ACTIVE',
    ),
  ],
  cashiers: [
    TillCashierOption(
      id: 'cashier-1',
      displayName: 'Kavin',
      outletIds: ['outlet-1'],
    ),
  ],
  posDevices: [
    TillPosDeviceOption(
      id: 'pos-device-1',
      code: 'POS-01',
      name: 'Counter Tablet',
      outletId: 'outlet-1',
      status: 'ACTIVE',
      isTrusted: true,
      isAssigned: false,
    ),
  ],
  hardwareDevices: [
    TillHardwareDeviceOption(
      id: 'hardware-1',
      code: 'SCAN-01',
      name: 'Counter Scanner',
      type: 'barcode_scanner',
      outletId: 'outlet-1',
      status: 'ACTIVE',
      isAssigned: false,
      connectionStatus: 'CONNECTED',
    ),
  ],
  statuses: ['ACTIVE', 'INACTIVE'],
  currencyCode: 'LKR',
);
