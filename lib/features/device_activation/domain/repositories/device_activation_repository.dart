import '../entities/pos_device_context.dart';

abstract class DeviceActivationRepository {
  Future<PosDeviceContext> activateDevice(DeviceActivationForm form);
  Future<PosDeviceContext?> getCurrentDevice(DeviceActivationForm form);
}
