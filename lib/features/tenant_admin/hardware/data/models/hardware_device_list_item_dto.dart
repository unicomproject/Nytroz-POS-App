class HardwareDeviceListItemDto {
  const HardwareDeviceListItemDto({
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

  factory HardwareDeviceListItemDto.fromJson(Map<String, dynamic> json) {
    return HardwareDeviceListItemDto(
      hardwareDeviceId: json['hardwareDeviceId'] as String,
      hardwareDeviceCode: json['hardwareDeviceCode'] as String,
      hardwareDeviceName: json['hardwareDeviceName'] as String,
      hardwareDeviceType: json['hardwareDeviceType'] as String,
      connectionType: json['connectionType'] as String,
      status: json['status'] as String,
      outletId: json['outletId'] as String,
      outletName: json['outletName'] as String,
      manufacturer: json['manufacturer'] as String?,
      model: json['model'] as String?,
      serialNumber: json['serialNumber'] as String?,
      lastSeenAt: json['lastSeenAt'] != null
          ? DateTime.tryParse(json['lastSeenAt'] as String)
          : null,
      isAssigned: json['isAssigned'] as bool? ?? false,
      assignedTillId: json['assignedTillId'] as String?,
      assignedPosDeviceId: json['assignedPosDeviceId'] as String?,
    );
  }
}
