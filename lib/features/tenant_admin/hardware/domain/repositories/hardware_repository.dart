import '../entities/hardware_device.dart';
import '../entities/hardware_device_list_item.dart';

abstract class HardwareRepository {
  Future<List<HardwareDeviceListItem>> getHardwareDevices({
    required int page,
    required int pageSize,
    String? outletId,
  });

  Future<HardwareDevice> getHardwareDevice(String hardwareDeviceId);

  Future<HardwareDevice> createHardwareDevice(Map<String, dynamic> request);

  Future<void> assignHardwareToTill({
    required String tillId,
    required Map<String, dynamic> request,
  });

  Future<void> assignHardwareToPosDevice({
    required String posDeviceId,
    required Map<String, dynamic> request,
  });

  Future<void> releaseHardwareAssignment({
    required String assignmentId,
    required Map<String, dynamic> request,
  });
}
