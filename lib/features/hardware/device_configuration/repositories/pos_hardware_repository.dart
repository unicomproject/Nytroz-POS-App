import '../data/pos_hardware_remote_datasource.dart';
import '../models/pos_hardware_models.dart';

class PosHardwareRepository {
  const PosHardwareRepository(this._remote);

  final PosHardwareRemoteDatasource _remote;

  Future<List<PosHardwareConfiguration>> getConfigurations(String deviceId) =>
      _remote.getConfigurations(deviceId);

  Future<PosHardwareConfiguration> saveConfiguration(
          Map<String, dynamic> request) =>
      _remote.saveConfiguration(request);

  Future<HardwareTestOperation> createTest(Map<String, dynamic> request) =>
      _remote.createTest(request);

  Future<HardwareTestOperation> submitResult(
          String testId, Map<String, dynamic> request) =>
      _remote.submitResult(testId, request);

  Future<List<HardwareTestOperation>> getHistory(String deviceId) =>
      _remote.getHistory(deviceId);
}
