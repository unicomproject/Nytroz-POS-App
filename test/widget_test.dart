import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:nytroz_pos/app/app.dart';
import 'package:nytroz_pos/core/access/pos_access_codes.dart';
import 'package:nytroz_pos/core/network/dio_provider.dart';
import 'package:nytroz_pos/features/auth/data/datasources/auth_session_storage.dart';
import 'package:nytroz_pos/features/auth/domain/entities/auth_session.dart';
import 'package:nytroz_pos/shared/pos_session/pos_session_bootstrap_provider.dart';
import 'package:nytroz_pos/features/auth/presentation/providers/post_login_navigation_provider.dart';
import 'package:nytroz_pos/features/auth/presentation/providers/session_provider.dart';
import 'package:nytroz_pos/features/pos_shell/domain/entities/pos_home_action.dart';
import 'package:nytroz_pos/features/pos_shell/application/state/pos_home_dashboard_state.dart';
import 'package:nytroz_pos/features/pos_shell/presentation/providers/pos_home_dashboard_provider.dart';
import 'package:nytroz_pos/features/pos_shell/presentation/screens/pos_home_screen.dart';
import 'package:nytroz_pos/features/pos_shell/presentation/widgets/pos_mobile_top_bar.dart';
import 'package:nytroz_pos/features/pos_shell/presentation/widgets/pos_shell_nav_item.dart';
import 'package:nytroz_pos/features/pos_shell/presentation/widgets/pos_sidebar.dart';

void main() {
  group('POS Home', () {
    testWidgets('/pos/home renders the dashboard and Start Sale hero', (
      tester,
    ) async {
      await _pumpPosHome(tester, size: const Size(1200, 900));

      expect(find.byType(PosHomeScreen), findsOneWidget);
      expect(find.text('Hello, Cashier 👋'), findsOneWidget);
      expect(find.text('Start a Sale'), findsOneWidget);
      expect(find.text('Start New Sale'), findsOneWidget);
    });

    testWidgets('renders the complete reference dashboard cards', (
      tester,
    ) async {
      await _pumpPosHome(tester, size: const Size(1200, 900));

      expect(find.text('Manage Online Orders'), findsNothing);
      expect(find.text('Returns & Refunds'), findsOneWidget);
      expect(find.text('Add Customer'), findsWidgets);
      expect(find.text('Parked Sales'), findsOneWidget);
      expect(find.text('Cash Drawer'), findsWidgets);
      expect(find.text('Orders'), findsNothing);
    });

    testWidgets('tablet width shows the sidebar', (tester) async {
      await _pumpPosHome(tester, size: const Size(1024, 768));

      expect(find.byType(PosSidebar), findsOneWidget);
      expect(find.byType(PosMobileTopBar), findsNothing);
      final homeItem = tester.widget<PosShellNavItem>(
        find.widgetWithText(PosShellNavItem, 'Home'),
      );
      expect(homeItem.selected, isTrue);
    });

    testWidgets('Home remains on /pos/home when tapped', (tester) async {
      await _pumpPosHome(tester, size: const Size(1024, 768));

      await tester.tap(find.text('Home'));
      await tester.pumpAndSettle();

      expect(find.byType(PosHomeScreen), findsOneWidget);
      expect(find.byType(SnackBar), findsNothing);
    });

    testWidgets('sidebar hides destinations without permission', (
      tester,
    ) async {
      await _pumpPosHome(
        tester,
        size: const Size(1024, 768),
        permissionCodes: const [PosPermissionCodes.viewHome],
      );

      expect(find.text('Home'), findsOneWidget);
      expect(find.text('New Sale'), findsNothing);
      expect(find.text('Orders'), findsNothing);
      expect(find.text('Customers'), findsNothing);
      expect(find.text('Return & Refund'), findsNothing);
      expect(find.text('Cash Drawer'), findsNothing);
    });

    testWidgets('New Sale sidebar destination opens placeholder screen', (
      tester,
    ) async {
      await _pumpPosHome(
        tester,
        size: const Size(1024, 768),
        permissionCodes: [
          PosPermissionCodes.viewHome,
          PosPermissionCodes.startSale,
        ],
      );

      await tester.tap(find.text('New Sale'));
      await tester.pumpAndSettle();

      expect(find.text('Coming soon'), findsOneWidget);
      expect(find.byType(PosHomeScreen), findsNothing);
    });

    testWidgets('phone width shows the mobile top bar', (tester) async {
      await _pumpPosHome(tester, size: const Size(390, 844));

      expect(find.byType(PosMobileTopBar), findsOneWidget);
      expect(find.byType(PosSidebar), findsNothing);
    });
  });
}

Future<void> _pumpPosHome(
  WidgetTester tester, {
  required Size size,
  PosHomeDashboardState? dashboardState,
  List<String> permissionCodes = const [
    PosPermissionCodes.viewHome,
    PosPermissionCodes.startSale,
    PosPermissionCodes.processRefund,
    PosPermissionCodes.viewCustomers,
    PosPermissionCodes.recallSale,
    PosPermissionCodes.viewTill,
  ],
}) async {
  final dashboard = dashboardState ?? _referenceDashboardState(permissionCodes);
  final testDio = Dio(
    BaseOptions(
      baseUrl: 'https://test.local',
    ),
  );
  final testSession = AuthSession(
    accessToken: 'test-access-token',
    userId: 'test-user',
    userDisplayName: 'Cashier',
    permissionCodes: permissionCodes,
  );

  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        appDioProvider.overrideWithValue(testDio),
        authSessionStorageProvider.overrideWithValue(
          _TestAuthSessionStorage(testSession),
        ),
        postLoginRouteProvider.overrideWithValue(PostLoginRoute.posHome),
        posSessionBootstrapProvider.overrideWith((ref) {
          final notifier = PosSessionBootstrapNotifier(ref, autoStart: false);
          notifier.state = const PosSessionBootstrapState(isReady: true);
          return notifier;
        }),
        posHomeDashboardProvider.overrideWith(
          (ref) async => dashboard,
        ),
      ],
      child: const NytrozPosApp(),
    ),
  );
  await tester.pumpAndSettle();
}

class _TestAuthSessionStorage extends AuthSessionStorage {
  _TestAuthSessionStorage(this.session) : super(const FlutterSecureStorage());

  final AuthSession session;

  @override
  Future<AuthSession?> read() async => session;

  @override
  Future<void> save(AuthSession session) async {}

  @override
  Future<void> clear() async {}
}

PosHomeDashboardState _referenceDashboardState(List<String> permissionCodes) {
  final permissions = permissionCodes.toSet();

  return PosHomeDashboardState(
    fallbackUserDisplayName: 'Cashier',
    tillLabel: 'Front Till',
    tillStatusLabel: 'Open',
    isTillOpen: true,
    statusMessage: 'Ready for sales',
    startSaleButtonLabel: 'Start New Sale',
    isPosEnabled: true,
    isTrustedDevice: true,
    hasOpenTillSession: true,
    enabledFeatureKeys: const {
      PosFeatureCodes.sales,
      PosFeatureCodes.customers,
      PosFeatureCodes.returns,
      PosFeatureCodes.till,
    },
    grantedPermissionKeys: permissions,
    actions: [
      PosHomeAction(
        key: 'start-new-sale',
        label: 'Start New Sale',
        description: 'Begin a new in-store sale.',
        iconKey: 'new-sale',
        buttonLabel: 'Start New Sale',
        isEnabled: permissions.contains(PosPermissionCodes.startSale),
        targetRoute: '/pos/new-sale',
        featureKey: PosFeatureCodes.sales,
        permissionKey: PosPermissionCodes.startSale,
      ),
      PosHomeAction(
        key: 'manage-online-orders',
        label: 'Manage Online Orders',
        description: 'Review incoming online orders from one place.',
        iconKey: 'online-orders',
        buttonLabel: 'View Orders',
        isEnabled: permissions.contains(PosPermissionCodes.manageOnlineOrders),
        routeExists: false,
        onTapActionKey: 'manage-online-orders',
        permissionKey: PosPermissionCodes.manageOnlineOrders,
      ),
      PosHomeAction(
        key: 'returns-refunds',
        label: 'Returns & Refunds',
        description: 'Review eligible items for return or refund.',
        iconKey: 'return',
        buttonLabel: 'Start Return',
        isEnabled: permissions.contains(PosPermissionCodes.processRefund),
        targetRoute: '/pos/returns-refunds',
        featureKey: PosFeatureCodes.returns,
        permissionKey: PosPermissionCodes.processRefund,
        metricValue: '0',
        metricLabel: 'Pending today',
      ),
      PosHomeAction(
        key: 'add-customer',
        label: 'Add Customer',
        description: 'Create a customer profile for future visits.',
        iconKey: 'add-customer',
        buttonLabel: 'Add Customer',
        isEnabled: permissions.contains(PosPermissionCodes.viewCustomers),
        targetRoute: '/pos/customers',
        featureKey: PosFeatureCodes.customers,
        permissionKey: PosPermissionCodes.viewCustomers,
        metricValue: '0',
        metricLabel: 'Customer profiles',
      ),
      PosHomeAction(
        key: 'parked-sales',
        label: 'Parked Sales',
        description: 'View sales that were parked for later.',
        iconKey: 'parked-sales',
        buttonLabel: 'View Parked Sales',
        isEnabled: permissions.contains(PosPermissionCodes.recallSale),
        targetRoute: '/pos/parked-sales',
        featureKey: PosFeatureCodes.sales,
        permissionKey: PosPermissionCodes.recallSale,
        metricValue: '0',
        metricLabel: 'Waiting to resume',
      ),
      PosHomeAction(
        key: 'cash-drawer',
        label: 'Cash Drawer',
        description: 'View the current till cash summary.',
        iconKey: 'cash-drawer',
        buttonLabel: 'View Cash Drawer',
        isEnabled: permissions.contains(PosPermissionCodes.viewTill),
        targetRoute: '/pos/cash-drawer',
        featureKey: PosFeatureCodes.till,
        permissionKey: PosPermissionCodes.viewTill,
        metricValue: 'LKR 1000.00',
        metricLabel: 'Drawer balance',
      ),
    ],
  );
}
