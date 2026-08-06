import '../../data/models/hardware_device_list_item_dto.dart';
import '../../domain/entities/hardware_device_list_item.dart';

extension HardwareDeviceListItemMapper on HardwareDeviceListItemDto {
  HardwareDeviceListItem toEntity() {
    return HardwareDeviceListItem(
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
      lastSeenAt: lastSeenAt,
      isAssigned: isAssigned,
      assignedTillId: assignedTillId,
      assignedPosDeviceId: assignedPosDeviceId,
    );
  }
}
