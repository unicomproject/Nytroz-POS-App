import '../../data/models/hardware_device_dto.dart';
import '../../domain/entities/hardware_device.dart';

extension HardwareDeviceMapper on HardwareDeviceDto {
  HardwareDevice toEntity() {
    return HardwareDevice(
      hardwareDeviceId: hardwareDeviceId,
      hardwareDeviceCode: hardwareDeviceCode,
      hardwareDeviceName: hardwareDeviceName,
      hardwareDeviceType: hardwareDeviceType,
      connectionType: connectionType,
      status: status,
      outletId: outletId,
      outletName: outletName,
      manufacturer: manufacturer,
      model: model,
      serialNumber: serialNumber,
      assetTag: assetTag,
      firmwareVersion: firmwareVersion,
      configJson: configJson,
      lastSeenAt: lastSeenAt,
      createdAt: createdAt,
      updatedAt: updatedAt,
      isAssigned: isAssigned,
      activeAssignmentId: activeAssignmentId,
      assignedTillId: assignedTillId,
      assignedPosDeviceId: assignedPosDeviceId,
    );
  }
}
