class TillListQuery {
  const TillListQuery({
    this.search,
    this.page = 1,
    this.pageSize = 10,
    this.status,
    this.sortBy = 'name',
    this.sortDirection = 'asc',
  });

  final String? search;
  final int page;
  final int pageSize;
  final String? status;
  final String sortBy;
  final String sortDirection;
}

class TillFormData {
  const TillFormData({
    required this.name,
    required this.code,
    required this.outletId,
    required this.status,
    this.deviceName,
    this.printerName,
    this.scannerName,
    this.cashDrawerName,
    this.cardReaderName,
    this.internalNote,
  });

  final String name;
  final String code;
  final String outletId;
  final String status;
  final String? deviceName;
  final String? printerName;
  final String? scannerName;
  final String? cashDrawerName;
  final String? cardReaderName;
  final String? internalNote;
}

class AddTillFormData {
  const AddTillFormData({
    required this.name,
    required this.code,
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

  final String name;
  final String code;
  final String outletId;
  final String status;
  final String defaultCashierTenantUserId;
  final String defaultOpeningFloatAmount;
  final String? posDeviceId;
  final List<TillHardwareSelection> hardwareAssignments;
  final String? deviceName;
  final String? printerName;
  final String? scannerName;
  final String? cashDrawerName;
  final String? cardReaderName;
}

class TillHardwareSelection {
  const TillHardwareSelection({
    required this.hardwareDeviceId,
    this.isPrimary = false,
  });

  final String hardwareDeviceId;
  final bool isPrimary;
}

class CreatedTill {
  const CreatedTill({
    required this.id,
    required this.outletId,
    required this.name,
    required this.code,
    required this.status,
    this.outletName,
    this.defaultOpeningFloatAmount,
    this.currencyCode,
    this.defaultCashier,
    this.posDevice,
    this.hardwareAssignments = const [],
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String outletId;
  final String name;
  final String code;
  final String status;
  final String? outletName;
  final double? defaultOpeningFloatAmount;
  final String? currencyCode;
  final CreatedTillCashier? defaultCashier;
  final CreatedTillPosDevice? posDevice;
  final List<CreatedTillHardwareAssignment> hardwareAssignments;
  final DateTime? createdAt;
  final DateTime? updatedAt;
}

class CreatedTillCashier {
  const CreatedTillCashier({
    required this.tenantUserId,
    required this.displayName,
  });

  final String tenantUserId;
  final String displayName;
}

class CreatedTillPosDevice {
  const CreatedTillPosDevice({
    required this.posDeviceId,
    required this.deviceName,
    required this.deviceCode,
  });

  final String posDeviceId;
  final String deviceName;
  final String deviceCode;
}

class CreatedTillHardwareAssignment {
  const CreatedTillHardwareAssignment({
    required this.hardwareDeviceId,
    required this.hardwareDeviceName,
    required this.hardwareDeviceCode,
    required this.hardwareDeviceType,
    required this.isPrimary,
  });

  final String hardwareDeviceId;
  final String hardwareDeviceName;
  final String hardwareDeviceCode;
  final String hardwareDeviceType;
  final bool isPrimary;
}

class OutletOption {
  const OutletOption({
    required this.id,
    required this.name,
    required this.code,
    required this.status,
  });

  final String id;
  final String name;
  final String code;
  final String status;
}

class TillDetail {
  const TillDetail({
    required this.id,
    required this.outletId,
    required this.outletName,
    required this.outletCode,
    required this.name,
    required this.code,
    required this.status,
    required this.deviceStatus,
    required this.needsAttention,
    this.lastActiveAt,
    this.deviceName,
    this.printerName,
    this.scannerName,
    this.cashDrawerName,
    this.cardReaderName,
    this.internalNote,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String outletId;
  final String outletName;
  final String outletCode;
  final String name;
  final String code;
  final String status;
  final String deviceStatus;
  final bool needsAttention;
  final DateTime? lastActiveAt;
  final String? deviceName;
  final String? printerName;
  final String? scannerName;
  final String? cashDrawerName;
  final String? cardReaderName;
  final String? internalNote;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  TillFormData toFormData() {
    return TillFormData(
      name: name,
      code: code,
      outletId: outletId,
      status: _statusFormValue(status),
      deviceName: deviceName,
      printerName: printerName,
      scannerName: scannerName,
      cashDrawerName: cashDrawerName,
      cardReaderName: cardReaderName,
      internalNote: internalNote,
    );
  }
}

String _statusFormValue(String apiStatus) {
  switch (apiStatus.trim().toLowerCase()) {
    case 'inactive':
      return 'inactive';
    case 'maintenance':
      return 'maintenance';
    default:
      return 'active';
  }
}
