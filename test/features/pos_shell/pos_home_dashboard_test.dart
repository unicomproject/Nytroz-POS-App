import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nytroz_pos/core/access/effective_permission_set.dart';
import 'package:nytroz_pos/core/access/permission_access_providers.dart';
import 'package:nytroz_pos/core/access/pos_access_codes.dart';
import 'package:nytroz_pos/features/pos_shell/application/state/pos_home_dashboard_state.dart';
import 'package:nytroz_pos/features/pos_shell/data/datasources/pos_home_remote_datasource.dart';
import 'package:nytroz_pos/features/pos_shell/domain/entities/pos_home_action.dart';
import 'package:nytroz_pos/features/pos_shell/presentation/widgets/home/cashier_profile_card.dart';
import 'package:nytroz_pos/features/pos_shell/presentation/widgets/home/pos_home_dashboard.dart';
import 'package:nytroz_pos/features/pos_shell/presentation/widgets/home/session_summary_card.dart';

Widget _wrapWithProfileAccess(Widget child) {
  return _wrapWithPermissions(child, const [
    PosPermissionCodes.homeProfileView,
    PosPermissionCodes.homeProfileAvatar,
    PosPermissionCodes.homeProfileName,
    PosPermissionCodes.homeProfileRole,
    PosPermissionCodes.homeSessionSummaryView,
    PosPermissionCodes.homeSessionSummaryTotalSales,
    PosPermissionCodes.homeSessionSummaryTransactionCount,
    PosPermissionCodes.homeSessionSummaryReturns,
    PosPermissionCodes.homeSessionSummaryDiscounts,
    PosPermissionCodes.homeSessionSummaryNetSales,
    PosPermissionCodes.salesNewSaleView,
    PosPermissionCodes.homeActionsReturnsEntry,
    PosPermissionCodes.cashDrawerPositionView,
    PosPermissionCodes.homeActionsOnlineOrdersEntry,
    PosPermissionCodes.heldSalesView,
    PosPermissionCodes.tillSessionClose,
  ]);
}

Widget _wrapWithPermissions(Widget child, List<String> permissions) {
  return ProviderScope(
    overrides: [
      effectivePermissionSetProvider.overrideWithValue(
        EffectivePermissionSet.fromIterable(permissions),
      ),
    ],
    child: child,
  );
}

void main() {
  test('successful payload without summary preserves unavailable state', () {
    final payload = PosHomeDashboardPayload.fromJson(
      _successfulPayload(),
    );

    expect(payload.summary, isNull);
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
          'returnsApplicable': true,
          'discountAmount': 2150,
          'discountsApplicable': true,
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
    await tester.pumpWidget(_wrapWithProfileAccess(
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
    ));

    final image = tester.widget<Image>(
      find.byKey(const Key('cashier-profile-image')),
    );
    expect((image.image as NetworkImage).url, imageUrl);
    expect(find.text('CO'), findsOneWidget);
  });

  testWidgets('cashier image request failure keeps image request retryable',
      (tester) async {
    const imageUrl = 'https://cdn.example.test/missing-cashier.jpg';
    await tester.pumpWidget(_wrapWithProfileAccess(
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
    ));

    final image = tester.widget<Image>(
      find.byKey(const Key('cashier-profile-image')),
    );
    image.errorBuilder!(
      tester.element(find.byKey(const Key('cashier-profile-image'))),
      NetworkImageLoadException(statusCode: 404, uri: Uri()),
      StackTrace.empty,
    );
    await tester.pump();

    expect(find.byKey(const Key('cashier-profile-image')), findsOneWidget);
    expect(find.text('CO'), findsOneWidget);
  });

  testWidgets('cashier image remains active after intermittent load failure',
      (tester) async {
    const imageUrl = 'https://cdn.example.test/cashier-retry.jpg';
    await tester.pumpWidget(_wrapWithProfileAccess(
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
    ));

    var image = tester.widget<Image>(
      find.byKey(const Key('cashier-profile-image')),
    );
    image.errorBuilder!(
      tester.element(find.byKey(const Key('cashier-profile-image'))),
      NetworkImageLoadException(statusCode: 503, uri: Uri.parse(imageUrl)),
      StackTrace.empty,
    );
    await tester.pump();

    image = tester.widget<Image>(
      find.byKey(const Key('cashier-profile-image')),
    );
    expect((image.image as NetworkImage).url, imageUrl);
    expect(find.text('CO'), findsOneWidget);
  });

  testWidgets(
      'cashier image remains active when dashboard refreshes with same URL',
      (tester) async {
    const imageUrl = 'https://cdn.example.test/cashier-refresh.jpg';
    final firstDashboard = _dashboard(profileImageUrl: imageUrl);
    final secondDashboard = _dashboard(profileImageUrl: imageUrl);
    expect(identical(firstDashboard, secondDashboard), isFalse);

    await tester.pumpWidget(_wrapWithProfileAccess(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 320,
            height: 500,
            child: CashierProfileCard(dashboard: firstDashboard),
          ),
        ),
      ),
    ));

    final image = tester.widget<Image>(
      find.byKey(const Key('cashier-profile-image')),
    );
    image.errorBuilder!(
      tester.element(find.byKey(const Key('cashier-profile-image'))),
      NetworkImageLoadException(statusCode: 503, uri: Uri.parse(imageUrl)),
      StackTrace.empty,
    );
    await tester.pump();
    expect(find.byKey(const Key('cashier-profile-image')), findsOneWidget);

    // Update the same card element in place (POS home refresh).
    await tester.pumpWidget(_wrapWithProfileAccess(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 320,
            height: 500,
            child: CashierProfileCard(dashboard: secondDashboard),
          ),
        ),
      ),
    ));

    final refreshed = tester.widget<Image>(
      find.byKey(const Key('cashier-profile-image')),
    );
    expect((refreshed.image as NetworkImage).url, imageUrl);
  });

  testWidgets('unavailable summary shows Retry without zero cards', (
    tester,
  ) async {
    var retries = 0;
    await tester.pumpWidget(_wrapWithProfileAccess(
      MaterialApp(
        home: Scaffold(
          body: PosHomeSummarySection(
            summary: null,
            onRetry: () => retries++,
          ),
        ),
      ),
    ));

    expect(
      find.text('Current session summary is unavailable.'),
      findsOneWidget,
    );
    expect(find.text('LKR 0.00'), findsNothing);

    await tester.tap(find.byKey(const Key('pos-home-summary-retry')));
    expect(retries, 1);
  });

  testWidgets('real zero base metrics remain while optional metrics are hidden',
      (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 300);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      _wrapWithProfileAccess(
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
                returnsApplicable: false,
                discountAmount: 0,
                discountsApplicable: false,
                netSalesAmount: 0,
              ),
            ),
          ),
        ),
      ),
    );

    for (final label in const [
      'Total Sales',
      'Transactions',
      'Net Sales',
    ]) {
      expect(find.text(label), findsOneWidget);
    }
    expect(find.text('Returns'), findsNothing);
    expect(find.text('Discounts'), findsNothing);
    expect(find.text('LKR 0.00'), findsNWidgets(2));
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

    await tester.pumpWidget(_wrapWithProfileAccess(
      MaterialApp(
        home: Scaffold(
          body: PosHomeDashboard(dashboard: _dashboard()),
        ),
      ),
    ));
    await tester.pump();

    expect(find.byType(PosHomeDashboard), findsOneWidget);
    expect(find.text('CURRENT SESSION SUMMARY'), findsOneWidget);
    expect(find.text('LKR 1250.00'), findsOneWidget);
    expect(find.byIcon(Icons.arrow_drop_down), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('section permission denial removes the complete summary',
      (tester) async {
    await tester.pumpWidget(_wrapWithPermissions(
      const MaterialApp(
        home: Scaffold(body: PosHomeSummarySection(summary: _summaryFixture)),
      ),
      const [PosPermissionCodes.homeSessionSummaryTotalSales],
    ));

    expect(find.text('CURRENT SESSION SUMMARY'), findsNothing);
    expect(find.text('Total Sales'), findsNothing);
  });

  for (final width in const [1280.0, 1180.0, 1100.0]) {
    for (final metricCount in const [1, 2, 3, 4, 5]) {
      testWidgets('$metricCount summary cards reflow at ${width.toInt()} width',
          (tester) async {
        tester.view.physicalSize = Size(width, 300);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        const metricPermissions = [
          PosPermissionCodes.homeSessionSummaryTotalSales,
          PosPermissionCodes.homeSessionSummaryTransactionCount,
          PosPermissionCodes.homeSessionSummaryReturns,
          PosPermissionCodes.homeSessionSummaryDiscounts,
          PosPermissionCodes.homeSessionSummaryNetSales,
        ];

        await tester.pumpWidget(_wrapWithPermissions(
          const MaterialApp(
            home:
                Scaffold(body: PosHomeSummarySection(summary: _summaryFixture)),
          ),
          [
            PosPermissionCodes.homeSessionSummaryView,
            ...metricPermissions.take(metricCount),
          ],
        ));

        expect(find.byType(SessionSummaryCard), findsNWidgets(metricCount));
        expect(tester.takeException(), isNull);
        final widths = find
            .byType(SessionSummaryCard)
            .evaluate()
            .map((element) =>
                tester.getSize(find.byWidget(element.widget)).width)
            .toSet();
        expect(widths, hasLength(1));
      });
    }
  }

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

      await tester.pumpWidget(_wrapWithProfileAccess(
        MaterialApp(
          home: Scaffold(
            body: PosHomeDashboard(dashboard: _dashboard()),
          ),
        ),
      ));
      await tester.pump();

      expect(find.byType(PosHomeDashboard), findsOneWidget);
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

const _summaryFixture = PosHomeSummaryState(
  scope: 'CURRENT_TILL_SESSION',
  currencyCode: 'LONG-CURRENCY-CODE',
  grossSalesAmount: 999999999.99,
  transactionCount: 999999,
  refundAmount: 1250,
  refundCount: 2,
  returnsApplicable: true,
  discountAmount: 500,
  discountsApplicable: true,
  netSalesAmount: 999998249.99,
);

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
      returnsApplicable: true,
      discountAmount: 20,
      discountsApplicable: true,
      netSalesAmount: 1180,
    ),
  );
}
