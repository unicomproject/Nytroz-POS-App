class TillCreateOptionsDto {
  const TillCreateOptionsDto({
    required this.outlets,
    required this.cashiers,
    required this.posDevices,
    required this.hardwareDevices,
    required this.statuses,
    required this.currencyCode,
  });

  factory TillCreateOptionsDto.fromJson(Map<String, dynamic> json) {
    return TillCreateOptionsDto(
      outlets: _parseList(json['outlets'], TillOutletOptionDto.fromJson),
      cashiers: _parseList(json['cashiers'], TillCashierOptionDto.fromJson),
      posDevices:
          _parseList(json['posDevices'], TillPosDeviceOptionDto.fromJson),
      hardwareDevices: _parseList(
          json['hardwareDevices'], TillHardwareDeviceOptionDto.fromJson),
      statuses: (json['statuses'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      currencyCode: json['currencyCode']?.toString() ?? 'USD',
    );
  }

  final List<TillOutletOptionDto> outlets;
  final List<TillCashierOptionDto> cashiers;
  final List<TillPosDeviceOptionDto> posDevices;
  final List<TillHardwareDeviceOptionDto> hardwareDevices;
  final List<String> statuses;
  final String currencyCode;

  static List<T> _parseList<T>(
      dynamic data, T Function(Map<String, dynamic>) fromJson) {
    if (data is! List) return [];
    // ignore: avoid_dynamic_calls
    return data
        .whereType<Map<dynamic, dynamic>>()
        .map((e) => fromJson(Map<String, dynamic>.from(e)))
        .toList(growable: false);
  }
}

class TillOutletOptionDto {
  const TillOutletOptionDto({
    required this.id,
    required this.name,
    required this.code,
    required this.status,
  });

  factory TillOutletOptionDto.fromJson(Map<String, dynamic> json) {
    return TillOutletOptionDto(
      id: json['outletId']?.toString() ?? json['id']?.toString() ?? '',
      name: json['outletName']?.toString() ?? json['name']?.toString() ?? '',
      code: json['outletCode']?.toString() ?? json['code']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
    );
  }

  final String id;
  final String name;
  final String code;
  final String status;
}

class TillCashierOptionDto {
  const TillCashierOptionDto({
    required this.id,
    required this.displayName,
    required this.outletIds,
  });

  factory TillCashierOptionDto.fromJson(Map<String, dynamic> json) {
    return TillCashierOptionDto(
      id: json['id']?.toString() ?? '',
      displayName: json['displayName']?.toString() ?? '',
      outletIds: (json['outletIds'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }

  final String id;
  final String displayName;
  final List<String> outletIds;
}

class TillPosDeviceOptionDto {
  const TillPosDeviceOptionDto({
    required this.id,
    required this.code,
    required this.name,
    required this.outletId,
    required this.status,
    required this.isTrusted,
    required this.isAssigned,
    this.lastSeenAt,
  });

  factory TillPosDeviceOptionDto.fromJson(Map<String, dynamic> json) {
    return TillPosDeviceOptionDto(
      id: json['id']?.toString() ?? '',
      code: json['code']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      outletId: json['outletId']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      isTrusted: json['isTrusted'] == true,
      isAssigned: json['isAssigned'] == true,
      lastSeenAt: json['lastSeenAt'] != null
          ? DateTime.tryParse(json['lastSeenAt'].toString())
          : null,
    );
  }

  final String id;
  final String code;
  final String name;
  final String outletId;
  final String status;
  final bool isTrusted;
  final bool isAssigned;
  final DateTime? lastSeenAt;
}

class TillHardwareDeviceOptionDto {
  const TillHardwareDeviceOptionDto({
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

  factory TillHardwareDeviceOptionDto.fromJson(Map<String, dynamic> json) {
    return TillHardwareDeviceOptionDto(
      id: json['id']?.toString() ?? '',
      code: json['code']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      type: json['type']?.toString() ?? '',
      outletId: json['outletId']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      isAssigned: json['isAssigned'] == true,
      connectionType: json['connectionType']?.toString(),
      lastSeenAt: json['lastSeenAt'] != null
          ? DateTime.tryParse(json['lastSeenAt'].toString())
          : null,
      connectionStatus: json['connectionStatus']?.toString(),
    );
  }

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
