import 'dart:async';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nytroz_pos/core/storage/app_secure_storage.dart';
import 'package:nytroz_pos/features/device_activation/application/usecases/activate_device.dart';
import 'package:nytroz_pos/features/device_activation/data/datasources/device_context_storage.dart';
import 'package:nytroz_pos/features/device_activation/domain/entities/pos_device_context.dart';
import 'package:nytroz_pos/features/device_activation/domain/repositories/device_activation_repository.dart';
import 'package:nytroz_pos/features/device_activation/presentation/providers/device_activation_provider.dart';

void main() {
  test('successful activation persists trusted context and tenantSlug',
      () async {
    final repository = _ActivationRepository(result: _trustedContext);
    final storage = _MemoryDeviceContextStorage();
    final controller = DeviceActivationController(
      ActivateDevice(repository),
      storage,
    );
    await Future<void>.delayed(Duration.zero);

    final activated = await controller.activate(
      activationCode: '  TILL-TEST  ',
      deviceName: 'Test POS',
    );

    expect(activated, isTrue);
    expect(repository.calls, 1);
    expect(storage.saved?.tenantSlug, 'arenasports');
    expect(controller.state.deviceContext?.isTrusted, isTrue);
  });

  test('duplicate submission while loading calls repository exactly once',
      () async {
    final completer = Completer<PosDeviceContext>();
    final repository = _ActivationRepository(completer: completer);
    final controller = DeviceActivationController(
      ActivateDevice(repository),
      _MemoryDeviceContextStorage(),
    );
    await Future<void>.delayed(Duration.zero);

    final first = controller.activate(
      activationCode: 'TILL-TEST',
      deviceName: 'Test POS',
    );
    final second = await controller.activate(
      activationCode: 'TILL-TEST',
      deviceName: 'Test POS',
    );

    expect(second, isFalse);
    expect(repository.calls, 1);
    completer.complete(_trustedContext);
    expect(await first, isTrue);
  });

  test('failed request leaves form state reusable', () async {
    final repository = _ActivationRepository(
      error: const DeviceActivationException(
        'This activation code has already been used.',
      ),
    );
    final controller = DeviceActivationController(
      ActivateDevice(repository),
      _MemoryDeviceContextStorage(),
    );
    await Future<void>.delayed(Duration.zero);

    expect(
      await controller.activate(
        activationCode: 'TILL-USED',
        deviceName: 'Test POS',
      ),
      isFalse,
    );
    expect(controller.state.isSubmitting, isFalse);
    expect(
      controller.state.errorMessage,
      'This activation code has already been used.',
    );
  });

  test('trusted current-device recovery persists recovered context', () async {
    final repository = _ActivationRepository(current: _trustedContext);
    final storage = _MemoryDeviceContextStorage();
    final controller = DeviceActivationController(
      ActivateDevice(repository),
      storage,
    );
    await Future<void>.delayed(Duration.zero);

    expect(
      await controller.refreshCurrentDevice(deviceName: 'Test POS'),
      isTrue,
    );
    expect(storage.saved?.deviceId, 'device-1');
    expect(controller.state.deviceContext?.tenantSlug, 'arenasports');
  });
}

class _ActivationRepository implements DeviceActivationRepository {
  _ActivationRepository({
    this.result,
    this.current,
    this.completer,
    this.error,
  });

  final PosDeviceContext? result;
  final PosDeviceContext? current;
  final Completer<PosDeviceContext>? completer;
  final Object? error;
  int calls = 0;

  @override
  Future<PosDeviceContext> activateDevice(DeviceActivationForm form) async {
    calls += 1;
    if (error != null) throw error!;
    if (completer != null) return completer!.future;
    return result!;
  }

  @override
  Future<PosDeviceContext?> getCurrentDevice(DeviceActivationForm form) async =>
      current;
}

class _MemoryDeviceContextStorage extends DeviceContextStorage {
  _MemoryDeviceContextStorage()
      : super(const AppSecureStorage(FlutterSecureStorage()));

  PosDeviceContext? saved;

  @override
  Future<PosDeviceContext?> read() async => null;

  @override
  Future<String> readOrCreateDeviceFingerprint() async => 'fingerprint-test';

  @override
  Future<List<String>> readDeviceFingerprintCandidates() async =>
      const ['fingerprint-test'];

  @override
  Future<void> save(PosDeviceContext context) async => saved = context;

  @override
  Future<void> clearContext() async {}
}

final _trustedContext = PosDeviceContext(
  deviceId: 'device-1',
  deviceCode: 'POS-01',
  deviceName: 'Test POS',
  deviceType: 'fixed_pos_tablet',
  platform: 'android',
  deviceFingerprint: 'fingerprint-test',
  isTrusted: true,
  tenantId: 'tenant-1',
  tenantSlug: 'arenasports',
  outletId: 'outlet-1',
  outletName: 'Main Outlet',
  tillId: 'till-1',
  tillCode: 'T01',
  tillName: 'Till 01',
  pairedAt: DateTime.utc(2026, 8, 11),
);
