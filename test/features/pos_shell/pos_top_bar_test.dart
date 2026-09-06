import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nytroz_pos/core/access/pos_access_codes.dart';
import 'package:nytroz_pos/core/network/dio_provider.dart';
import 'package:nytroz_pos/core/storage/app_secure_storage.dart';
import 'package:nytroz_pos/features/auth/data/datasources/auth_session_storage.dart';
import 'package:nytroz_pos/features/auth/domain/entities/auth_session.dart';
import 'package:nytroz_pos/features/auth/presentation/providers/session_provider.dart';
import 'package:nytroz_pos/features/pos_shell/application/state/pos_home_dashboard_state.dart';
import 'package:nytroz_pos/features/pos_shell/presentation/providers/pos_home_dashboard_provider.dart';
import 'package:nytroz_pos/features/pos_shell/presentation/widgets/common/pos_top_bar.dart';
import 'package:nytroz_pos/features/pos_shell/presentation/widgets/common/pos_top_bar_notification_button.dart';
import 'package:nytroz_pos/features/pos_shell/presentation/widgets/home/pos_branding.dart';
import 'package:nytroz_pos/features/pos_shell/presentation/widgets/home/pos_dashboard_top_bar_content.dart';
import 'package:nytroz_pos/features/pos/presentation/widgets/new_sale/pos_new_sale_top_bar_content.dart';

class _FakeAuthSessionStorage extends AuthSessionStorage {
  _FakeAuthSessionStorage()
      : super(const AppSecureStorage(FlutterSecureStorage()));

  @override
  Future<AuthSession?> read() async => null;

  @override
  Future<void> save(AuthSession session) async {}

  @override
  Future<void> clear() async {}
}

class _PresetAuthSessionNotifier extends AuthSessionNotifier {
  _PresetAuthSessionNotifier(AuthSession session)
      : super(_FakeAuthSessionStorage()) {
    state = session;
  }
}

const _testSession = AuthSession(
  accessToken: 'test-token',
  userId: 'user-1',
  userDisplayName: 'Test Cashier',
  permissionCodes: [
    PosPermissionCodes.shellTopbarBrand,
    PosPermissionCodes.shellTopbarContainer,
    PosPermissionCodes.shellTopbarSessionStatus,
    PosPermissionCodes.shellTopbarOutlet,
    PosPermissionCodes.shellTopbarTill,
    PosPermissionCodes.viewNotifications,
    PosPermissionCodes.shellTopbarNotificationBell,
    PosPermissionCodes.shellTopbarConnectivity,
    PosPermissionCodes.shellTopbarClock,
    PosPermissionCodes.searchProducts,
    PosPermissionCodes.catalogSearchBar,
    PosPermissionCodes.catalogSearchScannerHint,
    PosPermissionCodes.viewTillSession,
  ],
);

const _testDashboardState = PosHomeDashboardState(
  actions: [],
  fallbackUserDisplayName: 'Test Cashier',
  businessDisplayName: 'OneVerz POS',
  outletName: 'Main Outlet',
  tillLabel: 'Front Till',
  tillStatusLabel: 'Closed',
  isTillOpen: false,
  statusMessage: 'Session Closed',
  notificationCount: 5,
);

void main() {
  group('PosTopBar Widget Tests', () {
    testWidgets('renders brand section once and dynamic content area',
        (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(1280, 800);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authSessionProvider.overrideWith(
              (ref) => _PresetAuthSessionNotifier(_testSession),
            ),
            posHomeDashboardProvider.overrideWith(
              (ref) => _testDashboardState,
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: PosTopBar(
                content: Text('Dashboard Custom Content'),
              ),
            ),
          ),
        ),
      );

      // Verify PosBranding is rendered
      expect(find.byType(PosBranding), findsOneWidget);
      expect(find.text('OneVerz POS', findRichText: true), findsOneWidget);

      // Verify dynamic content slot is populated
      expect(find.text('Dashboard Custom Content'), findsOneWidget);

      // Verify notification button is rendered
      expect(find.byType(PosTopBarNotificationButton), findsOneWidget);
    });

    testWidgets(
        'Start New Sale top bar content displays search field and online chip',
        (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(1280, 800);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authSessionProvider.overrideWith(
              (ref) => _PresetAuthSessionNotifier(_testSession),
            ),
            posHomeDashboardProvider.overrideWith(
              (ref) => _testDashboardState,
            ),
            appDioProvider.overrideWithValue(Dio()),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: PosTopBar(
                content: PosNewSaleTopBarContent(),
              ),
            ),
          ),
        ),
      );

      expect(find.byType(PosBranding), findsOneWidget);
      expect(find.byType(PosNewSaleTopBarContent), findsOneWidget);
      expect(find.text('Scan barcode or search products'), findsOneWidget);
      expect(find.text('OFFLINE'), findsOneWidget);
    });

    testWidgets('Dashboard top bar content displays status, outlet, and till',
        (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(1280, 800);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authSessionProvider.overrideWith(
              (ref) => _PresetAuthSessionNotifier(_testSession),
            ),
            posHomeDashboardProvider.overrideWith(
              (ref) => _testDashboardState,
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: PosTopBar(
                content: PosDashboardTopBarContent(),
              ),
            ),
          ),
        ),
      );

      expect(find.byType(PosBranding), findsOneWidget);
      expect(find.byType(PosDashboardTopBarContent), findsOneWidget);
      expect(find.text('CLOSED'), findsOneWidget);
      expect(find.text('Main Outlet'), findsOneWidget);
      expect(find.text('Front Till'), findsOneWidget);
    });
  });
}
