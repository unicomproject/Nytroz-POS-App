class CreateTillSetupRequestDto {
  const CreateTillSetupRequestDto({
    required this.tillName,
    required this.tillCode,
    required this.outletId,
    required this.status,
    required this.defaultCashierTenantUserId,
    required this.defaultOpeningFloatAmount,
    this.posDeviceId,
    this.hardwareAssignments = const [],
    this.deviceName,
    this.printerName,
    this.scannerName,
    this.cashDrawerName,
    this.cardReaderName,
  });

  final String tillName;
  final String tillCode;
  final String outletId;
  final String status;
  final String defaultCashierTenantUserId;
  final String defaultOpeningFloatAmount;
  final String? posDeviceId;
  final List<CreateTillHardwareAssignmentDto> hardwareAssignments;
  final String? deviceName;
  final String? printerName;
  final String? scannerName;
  final String? cashDrawerName;
  final String? cardReaderName;

  Map<String, dynamic> toJson() {
    return {
      'tillName': tillName.trim(),
      'tillCode': tillCode.trim().toUpperCase(),
      'outletId': outletId,
      'status': status.trim().toUpperCase(),
      'defaultCashierTenantUserId': defaultCashierTenantUserId,
      'defaultOpeningFloatAmount': double.parse(defaultOpeningFloatAmount),
      if (posDeviceId != null && posDeviceId!.trim().isNotEmpty)
        'posDeviceId': posDeviceId!.trim(),
      if (hardwareAssignments.isNotEmpty)
        'hardwareAssignments':
            hardwareAssignments.map((e) => e.toJson()).toList(growable: false),
      if (deviceName != null && deviceName!.trim().isNotEmpty)
        'deviceName': deviceName!.trim(),
      if (printerName != null && printerName!.trim().isNotEmpty)
        'printerName': printerName!.trim(),
      if (scannerName != null && scannerName!.trim().isNotEmpty)
        'scannerName': scannerName!.trim(),
      if (cashDrawerName != null && cashDrawerName!.trim().isNotEmpty)
        'cashDrawerName': cashDrawerName!.trim(),
      if (cardReaderName != null && cardReaderName!.trim().isNotEmpty)
        'cardReaderName': cardReaderName!.trim(),
    };
  }
}

class CreateTillHardwareAssignmentDto {
  const CreateTillHardwareAssignmentDto({
    required this.hardwareDeviceId,
    this.isPrimary = false,
  });

  final String hardwareDeviceId;
  final bool isPrimary;

  Map<String, dynamic> toJson() {
    return {
      'hardwareDeviceId': hardwareDeviceId,
      'isPrimary': isPrimary,
    };
  }
}
