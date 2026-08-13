import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nytroz_pos/core/network/dio_provider.dart';
import 'package:nytroz_pos/core/storage/app_secure_storage.dart';
import 'package:nytroz_pos/features/auth/data/datasources/auth_session_storage.dart';
import 'package:nytroz_pos/features/auth/domain/entities/auth_session.dart';
import 'package:nytroz_pos/features/auth/presentation/providers/session_provider.dart';
import 'package:nytroz_pos/features/cash_drawer/data/datasources/cash_drawer_remote_datasource.dart';
import 'package:nytroz_pos/features/cash_drawer/domain/entities/cash_drawer_summary.dart';
import 'package:nytroz_pos/features/cash_drawer/domain/entities/cash_movement.dart';
import 'package:nytroz_pos/features/cash_drawer/domain/repositories/cash_drawer_repository.dart';
import 'package:nytroz_pos/features/cash_drawer/presentation/providers/cash_drawer_provider.dart';
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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final device = PosDeviceContext(
    deviceId: 'device-1',
    deviceCode: 'POS-01',
    deviceName: 'Front Counter',
    deviceType: 'POS',
    platform: 'windows',
    deviceFingerprint: 'fp-1',
    isTrusted: true,
    tenantId: 'tenant-1',
    outletId: 'outlet-1',
    outletName: 'Main Outlet',
    tillId: 'till-1',
    tillCode: 'TILL-01',
    tillName: 'Till 01',
    pairedAt: DateTime.utc(2026, 8, 1),
  );

  AuthSession session() => const AuthSession(
        accessToken: 'token',
        userId: 'u1',
        userDisplayName: 'Kavin',
        permissionCodes: ['cash_drawer.view', 'cash_drawer.movement.create'],
      );

  test('cash in success refreshes summary and movements from backend',
      () async {
    final repository = _FakeCashDrawerRepository();
    final container = ProviderContainer(
      overrides: [
        cashDrawerRepositoryProvider.overrideWithValue(repository),
        appDioProvider.overrideWithValue(Dio()),
        authSessionProvider.overrideWith(
          (ref) => _PresetAuthSessionNotifier(session()),
        ),
        activateDeviceProvider.overrideWithValue(
          ActivateDevice(_FakeDeviceActivationRepository(device)),
        ),
        deviceContextStorageProvider.overrideWithValue(
          _TestDeviceContextStorage(device),
        ),
        deviceActivationProvider.overrideWith(
          (ref) => _PresetDeviceActivationController(
            ref.watch(activateDeviceProvider),
            ref.watch(deviceContextStorageProvider),
            device,
          ),
        ),
        openTillProvider.overrideWithValue(OpenTill(_FakeTillRepository())),
        tillSessionStorageProvider.overrideWithValue(_TestTillSessionStorage()),
        tillProvider.overrideWith((ref) => _OpenTillController()),
      ],
    );
    addTearDown(container.dispose);

    final controller = container.read(cashDrawerProvider.notifier);
    await controller.refresh();
    expect(repository.summaryCalls, greaterThanOrEqualTo(1));
    expect(repository.movementCalls, greaterThanOrEqualTo(1));
    final beforeExpected =
        container.read(cashDrawerProvider).summary!.currentExpectedCash;
    final summaryCallsBefore = repository.summaryCalls;
    final movementCallsBefore = repository.movementCalls;
    final movementCountBefore =
        container.read(cashDrawerProvider).movements.length;

    final ok = await controller.recordCashIn(
      amount: 500,
      reason: 'Float top-up',
    );

    expect(ok, isTrue);
    expect(container.read(cashDrawerProvider).errorMessage, isNull);
    expect(repository.createCalls, 1);
    expect(repository.summaryCalls, greaterThan(summaryCallsBefore));
    expect(repository.movementCalls, greaterThan(movementCallsBefore));
    expect(
      container.read(cashDrawerProvider).summary!.currentExpectedCash,
      beforeExpected + 500,
    );
    expect(
      container.read(cashDrawerProvider).movements.length,
      greaterThan(movementCountBefore),
    );
    expect(
      container.read(cashDrawerProvider).movements.any(
            (m) => m.id.startsWith('local-'),
          ),
      isFalse,
    );
  });

  test('cash in failure does not invent movement or change expected cash',
      () async {
    final repository = _FakeCashDrawerRepository(failCreate: true);
    final container = ProviderContainer(
      overrides: [
        cashDrawerRepositoryProvider.overrideWithValue(repository),
        appDioProvider.overrideWithValue(Dio()),
        authSessionProvider.overrideWith(
          (ref) => _PresetAuthSessionNotifier(session()),
        ),
        activateDeviceProvider.overrideWithValue(
          ActivateDevice(_FakeDeviceActivationRepository(device)),
        ),
        deviceContextStorageProvider.overrideWithValue(
          _TestDeviceContextStorage(device),
        ),
        deviceActivationProvider.overrideWith(
          (ref) => _PresetDeviceActivationController(
            ref.watch(activateDeviceProvider),
            ref.watch(deviceContextStorageProvider),
            device,
          ),
        ),
        openTillProvider.overrideWithValue(OpenTill(_FakeTillRepository())),
        tillSessionStorageProvider.overrideWithValue(_TestTillSessionStorage()),
        tillProvider.overrideWith((ref) => _OpenTillController()),
      ],
    );
    addTearDown(container.dispose);

    final controller = container.read(cashDrawerProvider.notifier);
    await controller.refresh();
    final before = container.read(cashDrawerProvider);
    final beforeExpected = before.summary!.currentExpectedCash;
    final beforeMovements = List<CashMovement>.from(before.movements);

    final ok = await controller.recordCashIn(
      amount: 500,
      reason: 'Float top-up',
    );

    expect(ok, isFalse);
    final after = container.read(cashDrawerProvider);
    expect(after.errorMessage, isNotNull);
    expect(after.summary!.currentExpectedCash, beforeExpected);
    expect(after.movements.length, beforeMovements.length);
    expect(after.movements.map((m) => m.id), beforeMovements.map((m) => m.id));
  });
}

class _FakeCashDrawerRepository implements CashDrawerRepository {
  _FakeCashDrawerRepository({this.failCreate = false});

  final bool failCreate;
  int summaryCalls = 0;
  int movementCalls = 0;
  int createCalls = 0;
  double expectedCash = 68000;
  final List<CashMovement> _movements = [
    CashMovement(
      id: 'backend-existing',
      type: CashMovementType.cashSale,
      amount: 12500,
      dateTime: DateTime.utc(2026, 8, 13, 11, 45),
      userName: 'Kavin',
    ),
  ];

  @override
  Future<CashDrawerSummary> getSummary(String deviceId) async {
    summaryCalls += 1;
    return CashDrawerSummary(
      tillSessionId: 'session-1',
      tillId: 'till-1',
      tillName: 'Till 01',
      status: 'OPEN',
      openedBy: 'Kavin',
      openedTime: DateTime.utc(2026, 8, 13, 8),
      openingCash: 25000,
      cashSales: 48750,
      cashRefunds: 1250,
      cashDrops: 2500,
      cashIns: expectedCash - 25000 - 48750 + 1250 + 2500 + 3000,
      cashOuts: 3000,
      currentExpectedCash: expectedCash,
      currencyCode: 'USD',
    );
  }

  @override
  Future<List<CashMovement>> getMovements(
    String deviceId, {
    int page = 1,
    int pageSize = 25,
  }) async {
    movementCalls += 1;
    return List<CashMovement>.from(_movements);
  }

  @override
  Future<CashMovement> createMovement({
    required String requestId,
    required String deviceId,
    required String tillSessionId,
    required CashMovementType type,
    required double amount,
    required String reason,
    String? referenceNumber,
  }) async {
    createCalls += 1;
    if (failCreate) {
      throw const CashDrawerException('Backend unavailable');
    }
    expectedCash += amount;
    final movement = CashMovement(
      id: 'backend-$createCalls',
      type: type,
      amount: amount,
      dateTime: DateTime.utc(2026, 8, 13, 12),
      userName: 'Kavin',
      reason: reason,
    );
    _movements.insert(0, movement);
    return movement;
  }
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

class _PresetDeviceActivationController extends DeviceActivationController {
  _PresetDeviceActivationController(
    super.activateDevice,
    super.storage,
    PosDeviceContext deviceContext,
  ) : super() {
    state = DeviceActivationState(deviceContext: deviceContext);
  }
}

class _FakeDeviceActivationRepository implements DeviceActivationRepository {
  _FakeDeviceActivationRepository(this.deviceContext);

  final PosDeviceContext deviceContext;

  @override
  Future<PosDeviceContext> activateDevice(DeviceActivationForm form) async =>
      deviceContext;

  @override
  Future<PosDeviceContext?> getCurrentDevice(DeviceActivationForm form) async =>
      deviceContext;
}

class _TestDeviceContextStorage extends DeviceContextStorage {
  _TestDeviceContextStorage(this._deviceContext)
      : super(const AppSecureStorage(FlutterSecureStorage()));

  final PosDeviceContext _deviceContext;

  @override
  Future<PosDeviceContext?> read() async => _deviceContext;

  @override
  Future<String> readOrCreateDeviceFingerprint() async =>
      _deviceContext.deviceFingerprint;

  @override
  Future<void> save(PosDeviceContext context) async {}

  @override
  Future<void> clear() async {}
}

class _OpenTillController extends TillController {
  _OpenTillController()
      : super(OpenTill(_FakeTillRepository()), _TestTillSessionStorage()) {
    state = TillState(
      session: TillSession(
        sessionId: 'session-1',
        tenantId: 'tenant-1',
        outletId: 'outlet-1',
        outletName: 'Main Outlet',
        tillId: 'till-1',
        tillCode: 'TILL-01',
        tillName: 'Till 01',
        openedDeviceId: 'device-1',
        openingFloat: 25000,
        status: 'open',
        openedAt: DateTime.utc(2026, 8, 13, 8),
      ),
    );
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
