import '../../domain/entities/pos_device_context.dart';
import '../../domain/repositories/device_activation_repository.dart';

class ActivateDevice {
  const ActivateDevice(this._repository);

  final DeviceActivationRepository _repository;

  Future<PosDeviceContext> call(DeviceActivationForm form) {
    return _repository.activateDevice(form);
  }

  Future<PosDeviceContext?> currentDevice(DeviceActivationForm form) {
    return _repository.getCurrentDevice(form);
  }
}
