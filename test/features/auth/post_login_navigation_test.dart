import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nytroz_pos/core/network/dio_provider.dart';
import 'package:nytroz_pos/core/storage/app_secure_storage.dart';
import 'package:nytroz_pos/features/auth/data/datasources/auth_session_storage.dart';
import 'package:nytroz_pos/features/auth/domain/entities/auth_session.dart';
import 'package:nytroz_pos/features/auth/presentation/providers/post_login_navigation_provider.dart';
import 'package:nytroz_pos/features/auth/presentation/providers/session_provider.dart';
import 'package:nytroz_pos/features/device_activation/application/usecases/activate_device.dart';
import 'package:nytroz_pos/features/device_activation/data/datasources/device_context_storage.dart';
import 'package:nytroz_pos/features/device_activation/domain/entities/pos_device_context.dart';
import 'package:nytroz_pos/features/device_activation/domain/repositories/device_activation_repository.dart';
import 'package:nytroz_pos/features/device_activation/presentation/providers/device_activation_provider.dart';
import 'package:nytroz_pos/features/till/application/usecases/open_till.dart';
import 'package:nytroz_pos/features/till/data/datasources/till_session_storage.dart';
import 'package:nytroz_pos/features/till/domain/entities/open_till.dart';
import 'package:nytroz_pos/features/till/domain/repositories/till_repository.dart';
import 'package:nytroz_pos/features/till/presentation/providers/till_provider.dart';
import 'package:nytroz_pos/shared/pos_session/pos_session_bootstrap_provider.dart';

void main() {
  group('Post-login navigation', () {
    test('routes cashier without trusted device to device activation', () {
      final container = _createContainer(session: _cashierSession);

      final route = container.read(postLoginRouteProvider);

      expect(route, PostLoginRoute.deviceActivation);
      container.dispose();
    });

    test('routes to device activation when device is not trusted', () {
      final container = _createContainer(session: _posOperatorSession);

      final route = container.read(postLoginRouteProvider);

      expect(route, PostLoginRoute.deviceActivation);
      container.dispose();
    });

    test('routes to open till when device is trusted but session is closed',
        () {
      final container = _createContainer(
        session: _posOperatorSession,
        deviceContext: _trustedDevice,
      );

      final route = container.read(postLoginRouteProvider);

      expect(route, PostLoginRoute.openTill);
      container.dispose();
    });

    test('routes to POS home when till session is open', () {
      final container = _createContainer(
        session: _posOperatorSession,
        deviceContext: _trustedDevice,
        tillSession: _openTillSession,
      );

      final route = container.read(postLoginRouteProvider);

      expect(route, PostLoginRoute.posHome);
      container.dispose();
    });

    test('routes tenant admin to dashboard without device activation', () {
      final container = _createContainer(session: _tenantAdminSession);
      addTearDown(container.dispose);

      final route = container.read(postLoginRouteProvider);

      expect(route, PostLoginRoute.tenantAdminDashboard);
    });

    test('routes tenant admin with role permissions to tenant admin shell', () {
      final container = _createContainer(session: _tenantAdminRoleSession);
      addTearDown(container.dispose);

      final route = container.read(postLoginRouteProvider);

      expect(route, PostLoginRoute.tenantAdminRoot);
    });

    test('routes tenant context only sessions to tenant admin shell', () {
      final container = _createContainer(session: _tenantAdminContextSession);
      addTearDown(container.dispose);

      final route = container.read(postLoginRouteProvider);

      expect(route, PostLoginRoute.tenantAdminNoAccess);
    });

    test('routes cashier sale permission to POS new sale, not tenant admin',
        () {
      final container = _createContainer(session: _cashierSaleSession);
      addTearDown(container.dispose);

      final route = container.read(postLoginRouteProvider);

      expect(route, PostLoginRoute.posNewSale);
    });

    test('routes POS identity with no usable route to POS no-access', () {
      final container = _createContainer(session: _posNoUsableRouteSession);
      addTearDown(container.dispose);

      final route = container.read(postLoginRouteProvider);

      expect(route, PostLoginRoute.posNoAccess);
    });

    test('routes sessions with no usable app route to tenant no-access', () {
      final container = _createContainer(session: _noUsableRouteSession);
      addTearDown(container.dispose);

      final route = container.read(postLoginRouteProvider);

      expect(route, PostLoginRoute.tenantAdminNoAccess);
    });

    test('bootstrap exposes device API failures instead of becoming ready',
        () async {
      final container = _createContainer(
        session: _posOperatorSession,
        deviceRepository: _ThrowingDeviceActivationRepository(),
        markBootstrapReady: false,
      );
      addTearDown(container.dispose);

      await container
          .read(posSessionBootstrapProvider.notifier)
          .bootstrap(force: true);
      final state = container.read(posSessionBootstrapProvider);

      expect(state.isReady, isFalse);
      expect(state.hasError, isTrue);
      expect(state.failedStep, 'refresh-current-device');
      expect(state.errorMessage, contains('Device API timed out'));
    });
  });
}

ProviderContainer _createContainer({
  required AuthSession session,
  PosDeviceContext? deviceContext,
  TillSession? tillSession,
  DeviceActivationRepository? deviceRepository,
  bool markBootstrapReady = true,
}) {
  return ProviderContainer(
    overrides: [
      appDioProvider.overrideWithValue(
        Dio(BaseOptions(baseUrl: 'https://test.local')),
      ),
      authSessionStorageProvider.overrideWithValue(_TestAuthSessionStorage()),
      authSessionProvider.overrideWith(
        (ref) => _PresetAuthSessionNotifier(session),
      ),
      deviceContextStorageProvider.overrideWithValue(
        _TestDeviceContextStorage(null),
      ),
      tillSessionStorageProvider.overrideWithValue(
        _TestTillSessionStorage(null),
      ),
      activateDeviceProvider.overrideWithValue(
        ActivateDevice(
          deviceRepository ?? _FakeDeviceActivationRepository(deviceContext),
        ),
      ),
      openTillProvider.overrideWithValue(
        OpenTill(_FakeTillRepository(tillSession)),
      ),
      deviceActivationProvider.overrideWith(
        (ref) => _PresetDeviceActivationController(
          ref.watch(activateDeviceProvider),
          ref.watch(deviceContextStorageProvider),
          deviceContext,
        ),
      ),
      tillProvider.overrideWith(
        (ref) => _PresetTillController(
          ref.watch(openTillProvider),
          ref.watch(tillSessionStorageProvider),
          tillSession,
        ),
      ),
      posSessionBootstrapProvider.overrideWith((ref) {
        final notifier = PosSessionBootstrapNotifier(ref, autoStart: false);
        if (markBootstrapReady) {
          notifier.state = const PosSessionBootstrapState(isReady: true);
        }
        return notifier;
      }),
    ],
  );
}

class _PresetAuthSessionNotifier extends AuthSessionNotifier {
  _PresetAuthSessionNotifier(AuthSession session)
      : super(_TestAuthSessionStorage()) {
    state = session;
  }
}

class _PresetDeviceActivationController extends DeviceActivationController {
  _PresetDeviceActivationController(
    super.activateDevice,
    super.storage,
    PosDeviceContext? deviceContext,
  ) : super() {
    if (deviceContext != null) {
      state = DeviceActivationState(deviceContext: deviceContext);
    }
  }
}

class _PresetTillController extends TillController {
  _PresetTillController(
    super.openTill,
    super.storage,
    TillSession? session,
  ) : super() {
    if (session != null) {
      state = TillState(session: session);
    }
  }
}

class _FakeDeviceActivationRepository implements DeviceActivationRepository {
  _FakeDeviceActivationRepository(this.deviceContext);

  final PosDeviceContext? deviceContext;

  @override
  Future<PosDeviceContext> activateDevice(DeviceActivationForm form) async {
    return deviceContext!;
  }

  @override
  Future<PosDeviceContext?> getCurrentDevice(DeviceActivationForm form) async {
    return deviceContext;
  }
}

class _ThrowingDeviceActivationRepository
    implements DeviceActivationRepository {
  @override
  Future<PosDeviceContext> activateDevice(DeviceActivationForm form) async {
    throw StateError('Device API timed out');
  }

  @override
  Future<PosDeviceContext?> getCurrentDevice(
    DeviceActivationForm form,
  ) async {
    throw StateError('Device API timed out');
  }
}

class _FakeTillRepository implements TillRepository {
  _FakeTillRepository(this.session);

  final TillSession? session;

  @override
  Future<TillSession> openTill(OpenTillForm form) async {
    return session!;
  }

  @override
  Future<TillSession?> getCurrentSession(OpenTillForm form) async {
    return session;
  }

  @override
  Future<ClosedTillSession> closeTill(CloseTillForm form) async {
    throw UnimplementedError();
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

class _TestDeviceContextStorage extends DeviceContextStorage {
  _TestDeviceContextStorage(this._deviceContext)
      : super(const AppSecureStorage(FlutterSecureStorage()));

  final PosDeviceContext? _deviceContext;

  @override
  Future<PosDeviceContext?> read() async => _deviceContext;

  @override
  Future<String> readOrCreateDeviceFingerprint() async {
    return _deviceContext?.deviceFingerprint ?? 'test-device-fingerprint';
  }

  @override
  Future<List<String>> readDeviceFingerprintCandidates() async {
    return [_deviceContext?.deviceFingerprint ?? 'test-device-fingerprint'];
  }

  @override
  Future<void> save(PosDeviceContext context) async {}

  @override
  Future<void> clear() async {}
}

class _TestTillSessionStorage extends TillSessionStorage {
  _TestTillSessionStorage(this._session)
      : super(const AppSecureStorage(FlutterSecureStorage()));

  final TillSession? _session;

  @override
  Future<TillSession?> read() async => _session;

  @override
  Future<void> save(TillSession session) async {}

  @override
  Future<void> clear() async {}
}

final _pairedAt = DateTime.utc(2026, 6, 16, 9);

const _posOperatorSession = AuthSession(
  accessToken: 'token',
  userId: 'cashier-1',
  userDisplayName: 'Cashier',
  userType: 'cashier',
  permissionCodes: [
    'tenant.till.manage',
    'pos.till.open',
    'pos.home.view',
  ],
);

const _cashierSession = AuthSession(
  accessToken: 'token',
  userId: 'cashier-1',
  userDisplayName: 'Cashier',
  userType: 'cashier',
  permissionCodes: [
    'pos.till.open',
    'pos.home.view',
  ],
);

const _tenantAdminSession = AuthSession(
  accessToken: 'token',
  userId: 'tenant-admin-1',
  userDisplayName: 'Tenant Admin',
  userType: 'admin',
  permissionCodes: [
    'tenant.context.view',
    'dashboard.view',
    'tills.view',
  ],
);

const _tenantAdminRoleSession = AuthSession(
  accessToken: 'token',
  userId: 'tenant-admin-role-1',
  userDisplayName: 'Tenant Admin',
  userType: 'admin',
  permissionCodes: [
    'tenant.role.manage',
  ],
);

const _tenantAdminContextSession = AuthSession(
  accessToken: 'token',
  userId: 'tenant-admin-context-1',
  userDisplayName: 'Tenant Admin',
  userType: 'admin',
  permissionCodes: [
    'tenant.context.view',
  ],
);

const _cashierSaleSession = AuthSession(
  accessToken: 'token',
  userId: 'cashier-sale-1',
  userDisplayName: 'Cashier',
  userType: 'cashier',
  permissionCodes: [
    'pos.sale.create',
  ],
);

const _posNoUsableRouteSession = AuthSession(
  accessToken: 'token',
  userId: 'cashier-orders-1',
  userDisplayName: 'Cashier',
  userType: 'cashier',
  permissionCodes: [
    'pos.orders.manage',
  ],
);

const _noUsableRouteSession = AuthSession(
  accessToken: 'token',
  userId: 'limited-1',
  userDisplayName: 'Limited User',
  permissionCodes: [
    'audit.read',
  ],
);

final _trustedDevice = PosDeviceContext(
  deviceId: 'device-1',
  deviceCode: 'DEV-001',
  deviceName: 'Front POS',
  deviceType: 'fixed_pos_tablet',
  platform: 'web',
  deviceFingerprint: 'test-device-fingerprint',
  isTrusted: true,
  tenantId: 'tenant-1',
  outletId: 'outlet-1',
  outletName: 'Main Outlet',
  tillId: 'till-1',
  tillCode: 'TILL-001',
  tillName: 'Front Till',
  pairedAt: _pairedAt,
);

final _openTillSession = TillSession(
  sessionId: 'session-1',
  tenantId: 'tenant-1',
  outletId: 'outlet-1',
  outletName: 'Main Outlet',
  tillId: 'till-1',
  tillCode: 'TILL-001',
  tillName: 'Front Till',
  openedDeviceId: 'device-1',
  openingFloat: 150,
  status: 'open',
  openedAt: _pairedAt,
);
