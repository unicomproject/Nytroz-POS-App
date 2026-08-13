import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:nytroz_pos/core/access/pos_access_codes.dart';
import 'package:nytroz_pos/core/storage/app_secure_storage.dart';
import 'package:nytroz_pos/features/auth/data/datasources/auth_session_storage.dart';
import 'package:nytroz_pos/features/auth/domain/entities/auth_session.dart';
import 'package:nytroz_pos/features/auth/presentation/providers/session_provider.dart';
import 'package:nytroz_pos/features/cash_drawer/domain/entities/cash_drawer_summary.dart';
import 'package:nytroz_pos/features/cash_drawer/domain/entities/cash_movement.dart';
import 'package:nytroz_pos/features/cash_drawer/presentation/providers/cash_drawer_provider.dart';
import 'package:nytroz_pos/features/cash_drawer/presentation/screens/pos_cash_drawer_screen.dart';
import 'package:nytroz_pos/features/hardware/receipt_printer/presentation/providers/cash_drawer_controller.dart'
    as hardware;
import 'package:nytroz_pos/features/till/application/usecases/open_till.dart';
import 'package:nytroz_pos/features/till/data/datasources/till_session_storage.dart';
import 'package:nytroz_pos/features/till/domain/entities/open_till.dart';
import 'package:nytroz_pos/features/till/domain/repositories/till_repository.dart';
import 'package:nytroz_pos/features/till/presentation/providers/till_provider.dart';
import 'package:nytroz_pos/features/tenant_admin/presentation/screens/tenant_admin_forbidden_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  CashDrawerSummary openSummary({
    String tillName = 'Till 01',
    String status = 'OPEN',
    double expected = 68000,
  }) {
    return CashDrawerSummary(
      tillSessionId: 'session-1',
      tillId: 'till-1',
      tillName: tillName,
      status: status,
      openedBy: 'Kavin',
      openedTime: DateTime.utc(2026, 8, 13, 8),
      openingCash: 25000,
      cashSales: 48750,
      cashRefunds: 1250,
      cashDrops: 2500,
      cashIns: 5000,
      cashOuts: 3000,
      currentExpectedCash: expected,
      currencyCode: 'LKR',
    );
  }

  AuthSession session(Set<String> permissions) => AuthSession(
        accessToken: 'token',
        userId: 'u1',
        userDisplayName: 'Cashier',
        permissionCodes: permissions.toList(),
      );

  List<Override> overrides({
    required Set<String> permissions,
    CashDrawerState? drawerState,
    bool tillOpen = true,
  }) {
    return [
      authSessionProvider.overrideWith(
        (ref) => _PresetAuthSessionNotifier(session(permissions)),
      ),
      openTillProvider.overrideWithValue(OpenTill(_FakeTillRepository())),
      tillSessionStorageProvider.overrideWithValue(_TestTillSessionStorage()),
      tillProvider.overrideWith(
        (ref) => _PresetTillController(open: tillOpen),
      ),
      cashDrawerProvider.overrideWith(
        (ref) => _FakeCashDrawerController(
          ref,
          drawerState ??
              CashDrawerState(
                summary: openSummary(),
                movements: [
                  CashMovement(
                    id: 'm1',
                    type: CashMovementType.cashSale,
                    amount: 12500,
                    dateTime: DateTime.utc(2026, 8, 13, 11, 45),
                    userName: 'Kavin',
                  ),
                ],
              ),
        ),
      ),
      hardware.cashDrawerControllerProvider.overrideWith(
        _IdleHardwareDrawerController.new,
      ),
    ];
  }

  Future<void> pumpScreen(
    WidgetTester tester, {
    required List<Override> overrides,
    Size size = const Size(1280, 800),
  }) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = size;
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (_, __) => const PosCashDrawerScreen(),
        ),
        GoRoute(
          path: '/pos/cash-drawer/cash-in',
          builder: (_, __) => const Scaffold(body: Text('Cash In Route')),
        ),
        GoRoute(
          path: '/pos/cash-drawer/cash-drop',
          builder: (_, __) => const Scaffold(body: Text('Cash Drop Route')),
        ),
        GoRoute(
          path: '/pos/cash-drawer/close-till',
          builder: (_, __) => const Scaffold(body: Text('Close Till Route')),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: overrides,
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
  }

  testWidgets('renders title subtitle summary actions and movements',
      (tester) async {
    await pumpScreen(
      tester,
      overrides: overrides(
        permissions: {
          PosPermissionCodes.viewCashDrawer,
          PosPermissionCodes.manageCashDrawer,
          PosPermissionCodes.createCashDrawerMovement,
          PosPermissionCodes.closeTill,
        },
      ),
    );

    expect(find.text('Cash Drawer'), findsOneWidget);
    expect(
      find.text('Monitor the till cash position and perform drawer actions.'),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.arrow_back_rounded), findsNothing);
    expect(find.text('Continue'), findsNothing);
    expect(find.text('TILL SUMMARY'), findsOneWidget);
    expect(find.text('Current Expected Cash'), findsOneWidget);
    expect(find.textContaining('68,000.00'), findsWidgets);
    expect(find.text('Open Drawer'), findsOneWidget);
    expect(find.text('Cash In'), findsOneWidget);
    expect(find.text('Cash Out / Drop'), findsOneWidget);
    expect(find.text('Close Till'), findsOneWidget);
    expect(find.text('RECENT CASH MOVEMENTS'), findsOneWidget);
    expect(find.text('Cash Sale'), findsOneWidget);
  });

  testWidgets('forbidden without cash_drawer.view', (tester) async {
    await pumpScreen(tester, overrides: overrides(permissions: {}));
    expect(find.byType(TenantAdminForbiddenScreen), findsOneWidget);
  });

  testWidgets('empty movements state', (tester) async {
    await pumpScreen(
      tester,
      overrides: overrides(
        permissions: {PosPermissionCodes.viewCashDrawer},
        drawerState:
            CashDrawerState(summary: openSummary(), movements: const []),
      ),
    );
    expect(find.text('No cash movements yet'), findsOneWidget);
  });

  testWidgets('loading state', (tester) async {
    await pumpScreen(
      tester,
      overrides: overrides(
        permissions: {PosPermissionCodes.viewCashDrawer},
        drawerState: const CashDrawerState(isLoading: true),
      ),
    );
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('error state with retry', (tester) async {
    await pumpScreen(
      tester,
      overrides: overrides(
        permissions: {PosPermissionCodes.viewCashDrawer},
        drawerState: const CashDrawerState(errorMessage: 'Backend unavailable'),
      ),
    );
    expect(find.textContaining('Backend unavailable'), findsWidgets);
    expect(find.text('Retry'), findsWidgets);
  });

  testWidgets('till closed banner', (tester) async {
    await pumpScreen(
      tester,
      overrides: overrides(
        permissions: {PosPermissionCodes.viewCashDrawer},
        tillOpen: false,
        drawerState: CashDrawerState(
          summary: openSummary(status: 'CLOSED'),
        ),
      ),
    );
    expect(
      find.text(
        'Till is not open. Open a till session to perform drawer actions.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('permission disables movement and manage actions',
      (tester) async {
    await pumpScreen(
      tester,
      overrides: overrides(
        permissions: {PosPermissionCodes.viewCashDrawer},
      ),
    );

    InkWell inkFor(String label) => tester.widget<InkWell>(
          find
              .ancestor(of: find.text(label), matching: find.byType(InkWell))
              .first,
        );

    expect(inkFor('Cash In').onTap, isNull);
    expect(inkFor('Cash Out / Drop').onTap, isNull);
    expect(inkFor('Open Drawer').onTap, isNull);
    expect(inkFor('Close Till').onTap, isNull);
  });

  testWidgets('cash in navigation', (tester) async {
    await pumpScreen(
      tester,
      overrides: overrides(
        permissions: {
          PosPermissionCodes.viewCashDrawer,
          PosPermissionCodes.createCashDrawerMovement,
        },
      ),
    );
    await tester.tap(find.text('Cash In'));
    await tester.pumpAndSettle();
    expect(find.text('Cash In Route'), findsOneWidget);
  });

  testWidgets('cash out navigation', (tester) async {
    await pumpScreen(
      tester,
      overrides: overrides(
        permissions: {
          PosPermissionCodes.viewCashDrawer,
          PosPermissionCodes.createCashDrawerMovement,
        },
      ),
    );
    await tester.tap(find.text('Cash Out / Drop'));
    await tester.pumpAndSettle();
    expect(find.text('Cash Drop Route'), findsOneWidget);
  });

  testWidgets('close till navigation', (tester) async {
    await pumpScreen(
      tester,
      overrides: overrides(
        permissions: {
          PosPermissionCodes.viewCashDrawer,
          PosPermissionCodes.closeTill,
        },
      ),
    );
    await tester.tap(find.text('Close Till'));
    await tester.pumpAndSettle();
    expect(find.text('Close Till Route'), findsOneWidget);
  });

  testWidgets('phone layout has no overflow', (tester) async {
    await pumpScreen(
      tester,
      size: const Size(390, 844),
      overrides: overrides(
        permissions: {
          PosPermissionCodes.viewCashDrawer,
          PosPermissionCodes.manageCashDrawer,
          PosPermissionCodes.createCashDrawerMovement,
          PosPermissionCodes.closeTill,
        },
      ),
    );
    expect(find.text('Cash Drawer'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('tablet and desktop layouts have no overflow', (tester) async {
    for (final size in const [
      Size(800, 1200),
      Size(1024, 768),
      Size(1280, 800),
      Size(1920, 1080),
    ]) {
      await pumpScreen(
        tester,
        size: size,
        overrides: overrides(
          permissions: {
            PosPermissionCodes.viewCashDrawer,
            PosPermissionCodes.manageCashDrawer,
            PosPermissionCodes.createCashDrawerMovement,
            PosPermissionCodes.closeTill,
          },
          drawerState: CashDrawerState(
            summary: openSummary(
              tillName: 'Very Long Till Name For Layout Testing 01',
            ),
            movements: [
              CashMovement(
                id: 'm1',
                type: CashMovementType.cashIn,
                amount: 1234567.89,
                dateTime: DateTime.utc(2026, 8, 13, 10, 30),
                userName: 'Very Long Cashier Display Name',
              ),
            ],
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('Cash Drawer'), findsOneWidget);
    }
  });
}

class _PresetAuthSessionNotifier extends AuthSessionNotifier {
  _PresetAuthSessionNotifier(AuthSession session)
      : super(_TestAuthSessionStorage()) {
    state = session;
  }
}

class _TestAuthSessionStorage extends AuthSessionStorage {
  _TestAuthSessionStorage()
      : super(const AppSecureStorage(FlutterSecureStorage()));

  @override
  Future<AuthSession?> read() async => null;

  @override
  Future<void> save(AuthSession session) async {}

  @override
  Future<void> clear() async {}
}

class _FakeCashDrawerController extends CashDrawerController {
  _FakeCashDrawerController(super.ref, CashDrawerState initial) {
    state = initial;
  }

  @override
  Future<void> refresh() async {}
}

class _IdleHardwareDrawerController extends hardware.CashDrawerController {
  @override
  hardware.CashDrawerState build() => const hardware.CashDrawerState();

  @override
  Future<bool> triggerManualNoSaleOpen({
    required String reason,
    String? managerEmail,
    String? managerPassword,
  }) async =>
      true;
}

class _PresetTillController extends TillController {
  _PresetTillController({required bool open})
      : super(OpenTill(_FakeTillRepository()), _TestTillSessionStorage()) {
    if (open) {
      state = TillState(
        session: TillSession(
          sessionId: 's1',
          tenantId: 'tenant',
          outletId: 'outlet',
          outletName: 'Main Outlet',
          tillId: 'till',
          tillCode: 'TILL-01',
          tillName: 'Till 01',
          openedDeviceId: 'device',
          openingFloat: 25000,
          status: 'open',
          openedAt: DateTime.utc(2026, 8, 13, 8),
        ),
      );
    }
  }
}

class _FakeTillRepository implements TillRepository {
  @override
  Future<TillSession> openTill(OpenTillForm form) async {
    throw UnimplementedError();
  }

  @override
  Future<TillSession?> getCurrentSession(OpenTillForm form) async => null;

  @override
  Future<ClosedTillSession> closeTill(CloseTillForm form) async {
    throw UnimplementedError();
  }
}

class _TestTillSessionStorage extends TillSessionStorage {
  _TestTillSessionStorage()
      : super(const AppSecureStorage(FlutterSecureStorage()));

  @override
  Future<TillSession?> read() async => null;

  @override
  Future<void> save(TillSession session) async {}

  @override
  Future<void> clear() async {}
}
