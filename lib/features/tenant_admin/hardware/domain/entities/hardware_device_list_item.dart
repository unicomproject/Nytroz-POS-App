class HardwareDeviceListItem {
  const HardwareDeviceListItem({
    required this.hardwareDeviceId,
    required this.hardwareDeviceCode,
    required this.hardwareDeviceName,
    required this.hardwareDeviceType,
    required this.connectionType,
    required this.status,
    required this.outletId,
    required this.outletName,
    this.manufacturer,
    this.model,
    this.serialNumber,
    this.lastSeenAt,
    required this.isAssigned,
    this.assignedTillId,
    this.assignedPosDeviceId,
  });

  final String hardwareDeviceId;
  final String hardwareDeviceCode;
  final String hardwareDeviceName;
  final String hardwareDeviceType;
  final String connectionType;
  final String status;
  final String outletId;
  final String outletName;
  final String? manufacturer;
  final String? model;
  final String? serialNumber;
  final DateTime? lastSeenAt;
  final bool isAssigned;
  final String? assignedTillId;
  final String? assignedPosDeviceId;
}
