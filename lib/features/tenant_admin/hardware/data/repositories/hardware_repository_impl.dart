import '../datasources/hardware_remote_datasource.dart';
import '../mappers/hardware_device_mapper.dart';
import '../mappers/hardware_device_list_item_mapper.dart';
import '../../domain/entities/hardware_device.dart';
import '../../domain/entities/hardware_device_list_item.dart';
import '../../domain/repositories/hardware_repository.dart';

class HardwareRepositoryImpl implements HardwareRepository {
  const HardwareRepositoryImpl(this._remoteDataSource);

  final HardwareRemoteDataSource _remoteDataSource;

  @override
  Future<List<HardwareDeviceListItem>> getHardwareDevices({
    required int page,
    required int pageSize,
    String? outletId,
  }) async {
    final dtos = await _remoteDataSource.getHardwareDevices(
      page: page,
      pageSize: pageSize,
      outletId: outletId,
    );
    return dtos.map((dto) => dto.toEntity()).toList();
  }

  @override
  Future<HardwareDevice> getHardwareDevice(String hardwareDeviceId) async {
    final dto = await _remoteDataSource.getHardwareDevice(hardwareDeviceId);
    return dto.toEntity();
  }

  @override
  Future<HardwareDevice> createHardwareDevice(
      Map<String, dynamic> request) async {
    final dto = await _remoteDataSource.createHardwareDevice(request);
    return dto.toEntity();
  }

  @override
  Future<void> assignHardwareToTill({
    required String tillId,
    required Map<String, dynamic> request,
  }) async {
    await _remoteDataSource.assignHardwareToTill(tillId, request);
  }

  @override
  Future<void> assignHardwareToPosDevice({
    required String posDeviceId,
    required Map<String, dynamic> request,
  }) async {
    await _remoteDataSource.assignHardwareToPosDevice(posDeviceId, request);
  }

  @override
  Future<void> releaseHardwareAssignment({
    required String assignmentId,
    required Map<String, dynamic> request,
  }) async {
    await _remoteDataSource.releaseHardwareAssignment(assignmentId, request);
  }
}
