import 'package:flutter_test/flutter_test.dart';
import 'package:nytroz_pos/features/device_activation/application/usecases/activate_device.dart';
import 'package:nytroz_pos/features/device_activation/domain/entities/pos_device_context.dart';
import 'package:nytroz_pos/features/device_activation/domain/repositories/device_activation_repository.dart';

void main() {
  group('ActivateDevice use case', () {
    test('returns activated device context from repository', () async {
      final expectedDevice = PosDeviceContext(
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
      final repository = _FakeDeviceActivationRepository(
        activatedDevice: expectedDevice,
      );
      final activateDevice = ActivateDevice(repository);
      const form = DeviceActivationForm(
        activationCode: 'TILL-8K92-POS',
        deviceName: 'Front POS',
        deviceFingerprint: 'test-device-fingerprint',
        deviceType: 'fixed_pos_tablet',
        platform: 'web',
        appVersion: 'dev',
      );

      final result = await activateDevice(form);

      expect(result, expectedDevice);
      expect(repository.lastActivationCode, 'TILL-8K92-POS');
    });

    test('returns current trusted device when already paired', () async {
      final currentDevice = PosDeviceContext(
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
      final repository = _FakeDeviceActivationRepository(
        currentDevice: currentDevice,
      );
      final activateDevice = ActivateDevice(repository);
      const form = DeviceActivationForm(
        activationCode: '',
        deviceName: 'Front POS',
        deviceFingerprint: 'test-device-fingerprint',
        deviceType: 'fixed_pos_tablet',
        platform: 'web',
        appVersion: 'dev',
      );

      final result = await activateDevice.currentDevice(form);

      expect(result, currentDevice);
    });
  });
}

class _FakeDeviceActivationRepository implements DeviceActivationRepository {
  _FakeDeviceActivationRepository({
    this.activatedDevice,
    this.currentDevice,
  });

  final PosDeviceContext? activatedDevice;
  final PosDeviceContext? currentDevice;
  String? lastActivationCode;

  @override
  Future<PosDeviceContext> activateDevice(DeviceActivationForm form) async {
    lastActivationCode = form.activationCode;
    return activatedDevice!;
  }

  @override
  Future<PosDeviceContext?> getCurrentDevice(DeviceActivationForm form) async {
    return currentDevice;
  }
}

final _pairedAt = DateTime.utc(2026, 6, 16, 9);
