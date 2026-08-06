class HardwareDevice {
  const HardwareDevice({
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
    this.assetTag,
    this.firmwareVersion,
    this.configJson,
    this.lastSeenAt,
    this.createdAt,
    this.updatedAt,
    required this.isAssigned,
    this.activeAssignmentId,
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
  final String? assetTag;
  final String? firmwareVersion;
  final String? configJson;
  final DateTime? lastSeenAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final bool isAssigned;
  final String? activeAssignmentId;
  final String? assignedTillId;
  final String? assignedPosDeviceId;
}
