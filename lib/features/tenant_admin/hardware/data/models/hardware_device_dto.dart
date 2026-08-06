class HardwareDeviceDto {
  const HardwareDeviceDto({
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

  factory HardwareDeviceDto.fromJson(Map<String, dynamic> json) {
    return HardwareDeviceDto(
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
      assetTag: json['assetTag'] as String?,
      firmwareVersion: json['firmwareVersion'] as String?,
      configJson: json['configJson'] as String?,
      lastSeenAt: json['lastSeenAt'] != null
          ? DateTime.tryParse(json['lastSeenAt'] as String)
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String)
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'] as String)
          : null,
      isAssigned: json['isAssigned'] as bool? ?? false,
      activeAssignmentId: json['activeAssignmentId'] as String?,
      assignedTillId: json['assignedTillId'] as String?,
      assignedPosDeviceId: json['assignedPosDeviceId'] as String?,
    );
  }
}
