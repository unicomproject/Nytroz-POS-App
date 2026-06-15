import '../../domain/entities/pos_device_context.dart';
import '../../domain/repositories/device_activation_repository.dart';
import '../datasources/device_activation_remote_datasource.dart';

class DeviceActivationRepositoryImpl implements DeviceActivationRepository {
  const DeviceActivationRepositoryImpl(this._datasource);

  final DeviceActivationRemoteDatasource _datasource;

  @override
  Future<PosDeviceContext> activateDevice(DeviceActivationForm form) {
    return _datasource.activateDevice(form);
  }

  @override
  Future<PosDeviceContext?> getCurrentDevice(DeviceActivationForm form) {
    return _datasource.getCurrentDevice(form);
  }
}
