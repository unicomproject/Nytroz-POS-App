class CreateTillRequestDto {
  const CreateTillRequestDto({
    required this.tillName,
    required this.tillCode,
    required this.outletId,
    required this.status,
    this.deviceName,
    this.printerName,
    this.scannerName,
    this.cashDrawerName,
    this.cardReaderName,
    this.internalNote,
  });

  Map<String, dynamic> toJson() {
    return {
      'tillName': tillName.trim(),
      'tillCode': tillCode.trim(),
      'outletId': outletId,
      'status': _normalizeStatus(status),
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
      if (internalNote != null && internalNote!.trim().isNotEmpty)
        'internalNote': internalNote!.trim(),
    };
  }

  final String tillName;
  final String tillCode;
  final String outletId;
  final String status;
  final String? deviceName;
  final String? printerName;
  final String? scannerName;
  final String? cashDrawerName;
  final String? cardReaderName;
  final String? internalNote;

  static String _normalizeStatus(String value) {
    switch (value.trim().toLowerCase()) {
      case 'active':
        return 'ACTIVE';
      case 'inactive':
        return 'INACTIVE';
      case 'maintenance':
        return 'MAINTENANCE';
      default:
        return value.trim().toUpperCase();
    }
  }
}

typedef UpdateTillRequestDto = CreateTillRequestDto;
