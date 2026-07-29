import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nytroz_pos/features/pos_shell/application/state/pos_home_dashboard_state.dart';
import 'package:nytroz_pos/features/pos_shell/data/datasources/pos_home_remote_datasource.dart';
import 'package:nytroz_pos/features/pos_shell/domain/entities/pos_home_action.dart';
import 'package:nytroz_pos/features/pos_shell/presentation/widgets/home/cashier_profile_card.dart';
import 'package:nytroz_pos/features/pos_shell/presentation/widgets/home/pos_home_dashboard.dart';

void main() {
  test('successful payload without summary uses zero current-session values',
      () {
    final payload = PosHomeDashboardPayload.fromJson(
      _successfulPayload(),
    );

    expect(payload.summary, isNotNull);
    expect(payload.summary!.scope, 'CURRENT_TILL_SESSION');
    expect(payload.summary!.currencyCode, 'LKR');
    expect(payload.summary!.grossSalesAmount, 0);
    expect(payload.summary!.transactionCount, 0);
    expect(payload.summary!.refundAmount, 0);
    expect(payload.summary!.refundCount, 0);
    expect(payload.summary!.discountAmount, 0);
    expect(payload.summary!.netSalesAmount, 0);
  });

  test('successful payload preserves backend summary values', () {
    final payload = PosHomeDashboardPayload.fromJson(
      _successfulPayload(
        summary: {
          'scope': 'CURRENT_TILL_SESSION',
          'currencyCode': 'LKR',
          'grossSalesAmount': 125450,
          'transactionCount': 18,
          'refundAmount': 3250,
          'refundCount': 2,
          'discountAmount': 2150,
          'netSalesAmount': 120050,
        },
      ),
    );

    expect(payload.summary!.grossSalesAmount, 125450);
    expect(payload.summary!.transactionCount, 18);
    expect(payload.summary!.refundAmount, 3250);
    expect(payload.summary!.refundCount, 2);
    expect(payload.summary!.discountAmount, 2150);
    expect(payload.summary!.netSalesAmount, 120050);
  });

  test('successful payload maps cashier profile image URL', () {
    final payload = PosHomeDashboardPayload.fromJson({
      ..._successfulPayload(),
      'cashier': {
        'displayName': 'Cashier',
        'profileImageUrl': 'https://cdn.example.test/cashier.jpg',
      },
    });

    expect(
      payload.cashierProfileImageUrl,
      'https://cdn.example.test/cashier.jpg',
    );
  });

  test('successful payload resolves relative tenant branding logo URL', () {
    final payload = PosHomeDashboardPayload.fromJson(
      {
        ..._successfulPayload(),
        'branding': {
          'displayName': 'OneVerz POS',
          'logoUrl': '/branding/oneverz-pos-bag.png',
        },
      },
      apiBaseUrl: 'http://10.0.2.2:5150',
      replaceLoopbackHost: true,
    );

    expect(payload.businessDisplayName, 'OneVerz POS');
    expect(
      payload.businessLogoUrl,
      'http://10.0.2.2:5150/branding/oneverz-pos-bag.png',
    );
  });

  testWidgets('cashier card uses network image with initials fallback',
      (tester) async {
    const imageUrl = 'https://cdn.example.test/cashier.jpg';
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 320,
            height: 500,
            child: CashierProfileCard(
              dashboard: _dashboard(profileImageUrl: imageUrl),
            ),
          ),
        ),
      ),
    );

    final avatar = tester.widget<CircleAvatar>(
      find.byKey(const Key('cashier-profile-avatar')),
    );
    expect(avatar.foregroundImage, isA<NetworkImage>());
    expect((avatar.foregroundImage! as NetworkImage).url, imageUrl);
    expect(find.text('CO'), findsOneWidget);
  });

  testWidgets('cashier image request failure removes image and shows initials',
      (tester) async {
    const imageUrl = 'https://cdn.example.test/missing-cashier.jpg';
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 320,
            height: 500,
            child: CashierProfileCard(
              dashboard: _dashboard(profileImageUrl: imageUrl),
            ),
          ),
        ),
      ),
    );

    var avatar = tester.widget<CircleAvatar>(
      find.byKey(const Key('cashier-profile-avatar')),
    );
    avatar.onForegroundImageError!(
      NetworkImageLoadException(statusCode: 404, uri: Uri()),
      StackTrace.empty,
    );
    await tester.pump();

    avatar = tester.widget<CircleAvatar>(
      find.byKey(const Key('cashier-profile-avatar')),
    );
    expect(avatar.foregroundImage, isNull);
    expect(find.text('CO'), findsOneWidget);
  });

  testWidgets('unavailable summary shows Retry without zero cards', (
    tester,
  ) async {
    var retries = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PosHomeSummarySection(
            summary: null,
            onRetry: () => retries++,
          ),
        ),
      ),
    );

    expect(
      find.text('Current session summary is unavailable.'),
      findsOneWidget,
    );
    expect(find.text('LKR 0.00'), findsNothing);

    await tester.tap(find.byKey(const Key('pos-home-summary-retry')));
    expect(retries, 1);
  });

  testWidgets('empty successful summary renders all five zero-value cards', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 300);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: PosHomeSummarySection(
            summary: PosHomeSummaryState(
              scope: 'CURRENT_TILL_SESSION',
              currencyCode: 'LKR',
              grossSalesAmount: 0,
              transactionCount: 0,
              refundAmount: 0,
              refundCount: 0,
              discountAmount: 0,
              netSalesAmount: 0,
            ),
          ),
        ),
      ),
    );

    for (final label in const [
      'Total Sales',
      'Transactions',
      'Returns',
      'Discounts',
      'Net Sales',
    ]) {
      expect(find.text(label), findsOneWidget);
    }
    expect(find.text('LKR 0.00'), findsNWidgets(4));
    expect(find.text('0'), findsOneWidget);
    expect(
      find.text('Current session summary is unavailable.'),
      findsNothing,
    );
  });

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

Map<String, dynamic> _successfulPayload({
  Map<String, dynamic>? summary,
}) {
  return {
    'contextResolved': true,
    'user': {'fullName': 'Cashier'},
    'context': {
      'outletName': 'Main Outlet',
      'tillName': 'Front Till',
    },
    'till': {
      'name': 'Front Till',
      'status': 'Open',
      'currencyCode': 'LKR',
    },
    'cards': const {},
    if (summary != null) 'summary': summary,
  };
}

PosHomeDashboardState _dashboard({String? profileImageUrl}) {
  return PosHomeDashboardState(
    actions: const [
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
    cashierProfileImageUrl: profileImageUrl,
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
    summary: const PosHomeSummaryState(
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
