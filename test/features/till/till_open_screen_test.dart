import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nytroz_pos/core/network/dio_provider.dart';
import 'package:nytroz_pos/core/storage/app_secure_storage.dart';
import 'package:nytroz_pos/features/auth/data/datasources/auth_session_storage.dart';
import 'package:nytroz_pos/features/auth/domain/entities/auth_session.dart';
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
import 'package:nytroz_pos/features/till/presentation/screens/till_open_screen.dart';
import 'package:nytroz_pos/features/till/presentation/widgets/open_till_form.dart'
    as till_widget;

void main() {
  group('TillOpenScreen', () {
    testWidgets('blocks till open when device is not trusted', (tester) async {
      await _pumpTillOpenScreen(tester);

      expect(find.text('OneVerz'), findsOneWidget);
      expect(find.text('Device activation required'), findsOneWidget);
      expect(
        find.text(
          'This POS device must be trusted before a till can be opened.',
        ),
        findsOneWidget,
      );
      expect(find.text('Activate device'), findsOneWidget);
      expect(find.text('Open Till'), findsNothing);
      expect(find.text('Outlet Fetch'), findsNothing);
      expect(find.byIcon(Icons.arrow_back_ios_new_rounded), findsOneWidget);
      expect(find.byIcon(Icons.help_outline), findsNothing);
    });

    testWidgets('shows open till form when device is trusted', (tester) async {
      await _pumpTillOpenScreen(
        tester,
        deviceContext: _trustedDevice,
        authSession: _cashierSession,
      );

      expect(find.text('OneVerz'), findsOneWidget);
      expect(find.text('Open Till'), findsWidgets);
      expect(find.text('Front Till'), findsWidgets);
      expect(find.text('Main Outlet'), findsWidgets);
      expect(find.text('DEV-001'), findsOneWidget);
      expect(find.text('CASHIER001@GMAIL.COM'), findsOneWidget);
      expect(find.text('Device activation required'), findsNothing);
      expect(find.text('Nytroz'), findsNothing);
      expect(find.text('Outlet Fetch'), findsNothing);
      expect(find.text('Till Fetch'), findsNothing);
      expect(find.text('Step 3 of 3'), findsNothing);
      expect(find.text('Device trusted'), findsNothing);
      expect(find.byIcon(Icons.arrow_back_ios_new_rounded), findsOneWidget);
      expect(find.byIcon(Icons.help_outline), findsNothing);
      expect(find.text('Quick Amounts'), findsOneWidget);
      expect(find.text('100'), findsOneWidget);
      expect(find.text('500'), findsOneWidget);
      expect(find.text('1,000'), findsOneWidget);
    });

    testWidgets('keeps open till layout fixed on tablet height',
        (tester) async {
      tester.view.physicalSize = const Size(1280, 768);
      addTearDown(tester.view.resetPhysicalSize);

      await _pumpTillOpenScreen(
        tester,
        deviceContext: _trustedDevice,
        authSession: _cashierSession,
      );

      expect(find.text('1,000'), findsOneWidget);
      expect(tester.takeException(), isNull);
      expect(find.byType(FilledButton), findsOneWidget);
    });

    testWidgets('uses a wide form layout on tablet landscape', (tester) async {
      tester.view.physicalSize = const Size(1280, 768);
      addTearDown(tester.view.resetPhysicalSize);

      await _pumpTillOpenScreen(
        tester,
        deviceContext: _trustedDevice,
        authSession: _cashierSession,
      );

      final formWidth =
          tester.getSize(find.byType(till_widget.OpenTillForm)).width;
      expect(formWidth, greaterThan(1100));
      expect(formWidth, lessThanOrEqualTo(1200));
    });

    testWidgets('keeps till summary and submit button visible without overflow',
        (tester) async {
      tester.view.physicalSize = const Size(1280, 768);
      addTearDown(tester.view.resetPhysicalSize);

      await _pumpTillOpenScreen(
        tester,
        deviceContext: _trustedDeviceWithLongEmail,
        authSession: _cashierSession,
      );

      expect(find.text('Till Summary'), findsOneWidget);
      expect(find.text('CASHIER001@GMAIL.COM'), findsOneWidget);
      expect(find.text('The till will be opened and ready for transactions.'),
          findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}

Future<void> _pumpTillOpenScreen(
  WidgetTester tester, {
  PosDeviceContext? deviceContext,
  AuthSession? authSession,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(1200, 900);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        appDioProvider.overrideWithValue(
          Dio(BaseOptions(baseUrl: 'https://test.local')),
        ),
        authSessionProvider.overrideWith(
          (ref) => _PresetAuthSessionNotifier(
            authSession ?? _cashierSession,
          ),
        ),
        activateDeviceProvider.overrideWithValue(
          ActivateDevice(_FakeDeviceActivationRepository(deviceContext)),
        ),
        deviceContextStorageProvider.overrideWithValue(
          _TestDeviceContextStorage(deviceContext),
        ),
        deviceActivationProvider.overrideWith(
          (ref) => _ConfiguredDeviceActivationController(
            ref.watch(activateDeviceProvider),
            ref.watch(deviceContextStorageProvider),
            deviceContext,
          ),
        ),
        openTillProvider.overrideWithValue(
          OpenTill(_FakeTillRepository()),
        ),
        tillSessionStorageProvider.overrideWithValue(
          _TestTillSessionStorage(),
        ),
        tillProvider.overrideWith(
          (ref) => TillController(
            ref.watch(openTillProvider),
            ref.watch(tillSessionStorageProvider),
          ),
        ),
      ],
      child: const MaterialApp(
        home: TillOpenScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
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

class _ConfiguredDeviceActivationController extends DeviceActivationController {
  _ConfiguredDeviceActivationController(
    super.activateDevice,
    super.storage,
    PosDeviceContext? deviceContext,
  ) : super() {
    if (deviceContext != null) {
      state = DeviceActivationState(deviceContext: deviceContext);
    }
  }

  @override
  Future<bool> refreshCurrentDevice({required String deviceName}) async {
    return state.isTrusted;
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
  Future<void> save(PosDeviceContext context) async {}

  @override
  Future<void> clear() async {}
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

final _pairedAt = DateTime.utc(2026, 6, 16, 9);

const _cashierSession = AuthSession(
  accessToken: 'test-token',
  userId: 'cashier-1',
  userDisplayName: 'CASHIER001@GMAIL.COM',
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
  currencyCode: 'USD',
);

final _trustedDeviceWithLongEmail = PosDeviceContext(
  deviceId: 'device-1',
  deviceCode: 'POS-01',
  deviceName: 'Front POS',
  deviceType: 'fixed_pos_tablet',
  platform: 'web',
  deviceFingerprint: 'test-device-fingerprint',
  isTrusted: true,
  tenantId: 'tenant-1',
  outletId: 'outlet-1',
  outletName: 'Development Main Store',
  tillId: 'till-1',
  tillCode: 'TILL-001',
  tillName: 'Front Till 01',
  pairedAt: _pairedAt,
  currencyCode: 'LKR',
);
