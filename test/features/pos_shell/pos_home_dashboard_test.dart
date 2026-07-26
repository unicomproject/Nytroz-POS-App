import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nytroz_pos/features/pos_shell/application/state/pos_home_dashboard_state.dart';
import 'package:nytroz_pos/features/pos_shell/domain/entities/pos_home_action.dart';
import 'package:nytroz_pos/features/pos_shell/presentation/widgets/home/pos_home_dashboard.dart';

void main() {
  testWidgets('renders production home context and current-session summary',
      (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PosHomeDashboard(dashboard: _dashboard()),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('OneVerz Store'), findsOneWidget);
    expect(find.text('Main Outlet'), findsOneWidget);
    expect(find.text('Front Till'), findsOneWidget);
    expect(find.text('CURRENT SESSION SUMMARY'), findsOneWidget);
    expect(find.text('LKR 1250.00'), findsOneWidget);
    expect(find.byIcon(Icons.arrow_drop_down), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('disabled action exposes its reason and cannot be invoked',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 320,
            height: 180,
            child: PosHomeActionTile(
              title: 'Online Orders',
              assetPath: 'assets/images/not-present.png',
              fallbackIcon: Icons.phone_android,
              colors: [Colors.blue, Colors.indigo],
              accent: Colors.blue,
              enabled: false,
              onPressed: null,
              disabledReason: 'Online Orders is not available yet.',
            ),
          ),
        ),
      ),
    );

    expect(find.text('Online Orders'), findsOneWidget);
    expect(
      tester.getSemantics(find.text('Online Orders')).flagsCollection.isEnabled,
      Tristate.isFalse,
    );
    expect(tester.takeException(), isNull);
  });

  for (final viewport in const [
    (name: 'mobile portrait', size: Size(390, 844)),
    (name: 'wide desktop', size: Size(1600, 900)),
  ]) {
    testWidgets('renders without overflow on ${viewport.name}', (tester) async {
      tester.view.physicalSize = viewport.size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PosHomeDashboard(dashboard: _dashboard()),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('OneVerz Store'), findsOneWidget);
      expect(find.text('Start New Sale'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}

PosHomeDashboardState _dashboard() {
  return const PosHomeDashboardState(
    actions: [
      PosHomeAction(
        key: 'start-new-sale',
        label: 'Start New Sale',
        description: 'Begin a sale',
        iconKey: 'sale',
        targetRoute: '/pos/new-sale',
      ),
      PosHomeAction(
        key: 'returns-refunds',
        label: 'Returns & Exchanges',
        description: 'Return items',
        iconKey: 'returns',
        targetRoute: '/pos/returns-refunds',
      ),
      PosHomeAction(
        key: 'cash-drawer',
        label: 'Cash Drawer',
        description: 'Drawer',
        iconKey: 'cash',
        targetRoute: '/pos/cash-drawer',
      ),
      PosHomeAction(
        key: 'parked-sales',
        label: 'Resume Held Sales',
        description: 'Held sales',
        iconKey: 'held',
        targetRoute: '/pos/parked-sales',
        routeExists: false,
      ),
    ],
    fallbackUserDisplayName: 'Cashier One',
    cashierRoleLabel: 'Cashier',
    businessDisplayName: 'OneVerz Store',
    outletName: 'Main Outlet',
    deviceName: 'POS-01',
    deviceStatus: 'ACTIVE',
    tillLabel: 'Front Till',
    tillStatusLabel: 'Open',
    isTillOpen: true,
    statusMessage: 'Ready',
    isPosEnabled: true,
    isTrustedDevice: true,
    hasOpenTillSession: true,
    grantedPermissionKeys: {'pos.till.close'},
    summary: PosHomeSummaryState(
      scope: 'CURRENT_TILL_SESSION',
      currencyCode: 'LKR',
      grossSalesAmount: 1250,
      transactionCount: 4,
      refundAmount: 50,
      refundCount: 1,
      discountAmount: 20,
      netSalesAmount: 1180,
    ),
  );
}
