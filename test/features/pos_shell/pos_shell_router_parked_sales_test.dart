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
import 'package:nytroz_pos/features/cart/data/models/pos_parked_sale_dtos.dart';
import 'package:nytroz_pos/features/cart/domain/repositories/pos_parked_sale_repository.dart';
import 'package:nytroz_pos/features/cart/presentation/providers/pos_parked_sale_provider.dart';
import 'package:nytroz_pos/features/pos_shell/pos_shell_router.dart';
import 'package:nytroz_pos/features/pos_shell/presentation/screens/pos_placeholder_screen.dart';
import 'package:nytroz_pos/features/sale/presentation/screens/pos_parked_sales_screen.dart';

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

/// Wraps [posShellRoutes] so the test can obtain a [Ref] (posShellRoutes
/// expects a real provider Ref, not a bare [ProviderContainer]) via
/// `container.read(...)`, exactly as [appRouterProvider] does in production.
final _testPosShellRoutesProvider = Provider<List<RouteBase>>(
  (ref) => posShellRoutes(ref),
);

const _session = AuthSession(
  accessToken: 'test-token',
  userId: 'user-1',
  userDisplayName: 'Test Cashier',
  permissionCodes: [
    PosPermissionCodes.viewHome,
    PosPermissionCodes.viewBackendParkedSales,
    PosPermissionCodes.recallBackendParkedSale,
    PosPermissionCodes.createParkedSale,
  ],
);

void main() {
  testWidgets(
      '/pos/parked-sales route renders the real Parked Sales screen, '
      'not the generic placeholder', (tester) async {
    tester.view.physicalSize = const Size(800, 600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final container = ProviderContainer(overrides: [
      authSessionProvider.overrideWith(
        (ref) => _PresetAuthSessionNotifier(_session),
      ),
      posParkedSaleRepositoryProvider.overrideWithValue(
        _Repo(const []),
      ),
      posParkedSaleAccessContextProvider.overrideWithValue(
        const PosParkedSaleAccessContext(
          authenticated: true,
          trustedDevice: true,
          deviceId: 'device-1',
          permissions: {
            PosPermissionCodes.viewBackendParkedSales,
            PosPermissionCodes.recallBackendParkedSale,
            PosPermissionCodes.createParkedSale,
          },
        ),
      ),
    ]);
    addTearDown(container.dispose);

    final router = GoRouter(
      initialLocation: '/pos/parked-sales',
      routes: container.read(_testPosShellRoutesProvider),
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(PosPlaceholderScreen), findsNothing);
    expect(find.text('Coming soon'), findsNothing);
    expect(find.byType(PosParkedSalesScreen), findsOneWidget);
    expect(
        find.byKey(const ValueKey('pos-parked-sales-screen')), findsOneWidget);
    expect(find.text('Parked Sales'), findsWidgets);
    expect(find.text('No parked sales available'), findsOneWidget);
  });
}

class _Repo implements PosParkedSaleRepository {
  _Repo(this.holds);
  final List<PosHoldDto> holds;

  @override
  Future<PosHoldListDto> list(
          {required String deviceId,
          required String scope,
          required int page,
          required int pageSize}) async =>
      PosHoldListDto(holds, holds.length);
  @override
  Future<void> cancel(String holdId, {String? reason}) async {}
  @override
  Future<PosRecallHoldDto> recall(String holdId, String deviceId) =>
      throw UnimplementedError();
  @override
  Future<PosHoldDto> create(PosCreateHoldRequestDto request) =>
      throw UnimplementedError();
}
