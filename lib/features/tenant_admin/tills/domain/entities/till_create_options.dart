class TillCreateOptions {
  const TillCreateOptions({
    required this.outlets,
    required this.cashiers,
    required this.posDevices,
    required this.hardwareDevices,
    required this.statuses,
    required this.currencyCode,
  });

  final List<TillOutletOption> outlets;
  final List<TillCashierOption> cashiers;
  final List<TillPosDeviceOption> posDevices;
  final List<TillHardwareDeviceOption> hardwareDevices;
  final List<String> statuses;
  final String currencyCode;
}

class TillOutletOption {
  const TillOutletOption({
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

class TillCashierOption {
  const TillCashierOption({
    required this.id,
    required this.displayName,
    required this.outletIds,
  });

  final String id;
  final String displayName;
  final List<String> outletIds;
}

class TillPosDeviceOption {
  const TillPosDeviceOption({
    required this.id,
    required this.code,
    required this.name,
    required this.outletId,
    required this.status,
    required this.isTrusted,
    required this.isAssigned,
    this.lastSeenAt,
  });

  final String id;
  final String code;
  final String name;
  final String outletId;
  final String status;
  final bool isTrusted;
  final bool isAssigned;
  final DateTime? lastSeenAt;
}

class TillHardwareDeviceOption {
  const TillHardwareDeviceOption({
    required this.id,
    required this.code,
    required this.name,
    required this.type,
    required this.outletId,
    required this.status,
    required this.isAssigned,
    this.connectionType,
    this.lastSeenAt,
    this.connectionStatus,
  });

  final String id;
  final String code;
  final String name;
  final String type;
  final String outletId;
  final String status;
  final bool isAssigned;
  final String? connectionType;
  final DateTime? lastSeenAt;
  final String? connectionStatus;
}
