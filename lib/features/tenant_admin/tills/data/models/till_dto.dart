class TillDto {
  const TillDto({
    required this.id,
    required this.outletId,
    required this.outletName,
    required this.name,
    required this.code,
    required this.status,
    required this.operationalStatus,
    required this.displayStatus,
    required this.needsAttention,
    required this.attentionReasonCount,
    this.currentSessionId,
    this.currentSessionStatus,
    this.currentCashierId,
    this.currentCashierName,
    this.currentCashierProfileImageId,
    this.assignedPosDeviceId,
    this.assignedPosDeviceName,
    this.isPosDeviceTrusted,
    this.lastDeviceSeenAt,
    this.lastSessionActivityAt,
    this.lastActiveAt,
  });

  factory TillDto.fromJson(Map<String, dynamic> json) {
    final legacyDeviceStatus =
        (json['deviceStatus'] as String? ?? '').toLowerCase();
    final apiOperationalStatus = json['operationalStatus'] as String?;
    final apiDisplayStatus = json['displayStatus'] as String?;
    final needsAttention = json['needsAttention'] == true;

    final operationalStatusStr =
        (apiOperationalStatus ?? legacyDeviceStatus).toLowerCase();

    String finalDisplayStatus = 'unknown';
    if (apiDisplayStatus != null && apiDisplayStatus.isNotEmpty) {
      finalDisplayStatus = apiDisplayStatus.toLowerCase();
    } else if (needsAttention) {
      finalDisplayStatus = 'needs_attention';
    } else {
      finalDisplayStatus = operationalStatusStr;
    }

    return TillDto(
      id: json['tillId']?.toString() ?? json['id']?.toString() ?? '',
      outletId: json['outletId']?.toString() ?? '',
      outletName: json['outletName'] as String? ?? '',
      name: json['tillName'] as String? ?? json['name'] as String? ?? '',
      code: json['tillCode'] as String? ?? json['code'] as String? ?? '',
      status: json['status'] as String? ?? '',
      operationalStatus: operationalStatusStr,
      displayStatus: finalDisplayStatus,
      needsAttention: needsAttention,
      attentionReasonCount: _intValue(json['attentionReasonCount']),
      currentSessionId: json['currentSessionId']?.toString(),
      currentSessionStatus: json['currentSessionStatus']?.toString(),
      currentCashierId: json['currentCashierId']?.toString(),
      currentCashierName: json['currentCashierName']?.toString(),
      currentCashierProfileImageId:
          json['currentCashierProfileImageId']?.toString(),
      assignedPosDeviceId: json['assignedPosDeviceId']?.toString(),
      assignedPosDeviceName: json['assignedPosDeviceName']?.toString(),
      isPosDeviceTrusted: json['isPosDeviceTrusted'] as bool?,
      lastDeviceSeenAt: _dateValue(json['lastDeviceSeenAt']),
      lastSessionActivityAt: _dateValue(json['lastSessionActivityAt']),
      lastActiveAt: _dateValue(json['lastActiveAt'] ?? json['lastSyncAt']),
    );
  }

  final String id;
  final String outletId;
  final String outletName;
  final String name;
  final String code;
  final String status;
  final String operationalStatus;
  final String displayStatus;
  final bool needsAttention;
  final int attentionReasonCount;
  final String? currentSessionId;
  final String? currentSessionStatus;
  final String? currentCashierId;
  final String? currentCashierName;
  final String? currentCashierProfileImageId;
  final String? assignedPosDeviceId;
  final String? assignedPosDeviceName;
  final bool? isPosDeviceTrusted;
  final DateTime? lastDeviceSeenAt;
  final DateTime? lastSessionActivityAt;
  final DateTime? lastActiveAt;
}

class TillListSummaryDto {
  const TillListSummaryDto({
    required this.totalTills,
    required this.onlineCount,
    required this.offlineCount,
    required this.inactiveCount,
    required this.needsAttentionCount,
  });

  factory TillListSummaryDto.fromJson(Map<String, dynamic> json) {
    return TillListSummaryDto(
      totalTills: _intValue(json['totalTills']),
      onlineCount: _intValue(json['onlineTills'] ?? json['onlineCount']),
      offlineCount: _intValue(json['offlineTills'] ?? json['offlineCount']),
      inactiveCount: _intValue(json['inactiveTills'] ?? json['inactiveCount']),
      needsAttentionCount: _intValue(
        json['needsAttentionTills'] ?? json['needsAttentionCount'],
      ),
    );
  }

  final int totalTills;
  final int onlineCount;
  final int offlineCount;
  final int inactiveCount;
  final int needsAttentionCount;
}

class TillListResultDto {
  const TillListResultDto({
    required this.summary,
    required this.items,
    this.page = 1,
    this.pageSize = 5,
    this.totalCount = 0,
  });

  factory TillListResultDto.fromJson(
    Map<String, dynamic> json, {
    TillListSummaryDto? summary,
  }) {
    final rawItems = json['items'];
    final items = _mapList(rawItems, TillDto.fromJson);
    final page = _intValue(json['page'], fallback: 1);
    final pageSize = _intValue(json['pageSize'], fallback: 5);
    final totalCount = _intValue(json['totalCount'], fallback: items.length);

    return TillListResultDto(
      summary: summary ??
          (json['summary'] is Map
              ? TillListSummaryDto.fromJson(
                  Map<String, dynamic>.from(json['summary'] as Map),
                )
              : TillListSummaryDto(
                  totalTills: totalCount,
                  onlineCount: 0,
                  offlineCount: 0,
                  inactiveCount: 0,
                  needsAttentionCount: 0,
                )),
      items: items,
      page: page,
      pageSize: pageSize,
      totalCount: totalCount,
    );
  }

  final TillListSummaryDto summary;
  final List<TillDto> items;
  final int page;
  final int pageSize;
  final int totalCount;
}

class TillDetailDto {
  const TillDetailDto({
    required this.id,
    required this.outletId,
    required this.outletName,
    required this.outletCode,
    required this.name,
    required this.code,
    required this.status,
    required this.operationalStatus,
    required this.displayStatus,
    required this.needsAttention,
    this.attentionReasonCount = 0,
    this.lastActiveAt,
    this.currentCashierName,
    this.lastDeviceSeenAt,
    this.hasActiveAssignment = false,
    this.deviceName,
    this.printerName,
    this.scannerName,
    this.cashDrawerName,
    this.cardReaderName,
    this.internalNote,
    this.createdAt,
    this.updatedAt,
  });

  factory TillDetailDto.fromJson(Map<String, dynamic> json) {
    final legacyDeviceStatus =
        (json['deviceStatus'] as String? ?? '').toLowerCase();
    final apiOperationalStatus = json['operationalStatus'] as String?;
    final apiDisplayStatus = json['displayStatus'] as String?;
    final needsAttention = json['needsAttention'] == true;

    final operationalStatusStr =
        (apiOperationalStatus ?? legacyDeviceStatus).toLowerCase();

    String finalDisplayStatus = 'unknown';
    if (apiDisplayStatus != null && apiDisplayStatus.isNotEmpty) {
      finalDisplayStatus = apiDisplayStatus.toLowerCase();
    } else if (needsAttention) {
      finalDisplayStatus = 'needs_attention';
    } else {
      finalDisplayStatus = operationalStatusStr;
    }

    return TillDetailDto(
      id: json['tillId']?.toString() ?? json['id']?.toString() ?? '',
      outletId: json['outletId']?.toString() ?? '',
      outletName: json['outletName'] as String? ?? '',
      outletCode: json['outletCode'] as String? ?? '',
      name: json['tillName'] as String? ?? json['name'] as String? ?? '',
      code: json['tillCode'] as String? ?? json['code'] as String? ?? '',
      status: json['status'] as String? ?? '',
      operationalStatus: operationalStatusStr,
      displayStatus: finalDisplayStatus,
      needsAttention: needsAttention,
      attentionReasonCount: _intValue(json['attentionReasonCount']),
      lastActiveAt: _dateValue(json['lastActiveAt']),
      currentCashierName: json['currentCashierName'] as String?,
      lastDeviceSeenAt: _dateValue(json['lastDeviceSeenAt']),
      hasActiveAssignment: json['hasActiveAssignment'] == true,
      deviceName: json['deviceName'] as String?,
      printerName: json['printerName'] as String?,
      scannerName: json['scannerName'] as String?,
      cashDrawerName: json['cashDrawerName'] as String?,
      cardReaderName: json['cardReaderName'] as String?,
      internalNote: json['internalNote'] as String?,
      createdAt: _dateValue(json['createdAt']),
      updatedAt: _dateValue(json['updatedAt']),
    );
  }

  final String id;
  final String outletId;
  final String outletName;
  final String outletCode;
  final String name;
  final String code;
  final String status;
  final String operationalStatus;
  final String displayStatus;
  final bool needsAttention;
  final int attentionReasonCount;
  final DateTime? lastActiveAt;
  final String? currentCashierName;
  final DateTime? lastDeviceSeenAt;
  final bool hasActiveAssignment;
  final String? deviceName;
  final String? printerName;
  final String? scannerName;
  final String? cashDrawerName;
  final String? cardReaderName;
  final String? internalNote;
  final DateTime? createdAt;
  final DateTime? updatedAt;
}

class TillHardwareCashierDto {
  const TillHardwareCashierDto({
    required this.tenantUserId,
    required this.displayName,
  });

  factory TillHardwareCashierDto.fromJson(Map<String, dynamic> json) {
    return TillHardwareCashierDto(
      tenantUserId: json['tenantUserId']?.toString() ?? '',
      displayName: json['displayName'] as String? ?? '',
    );
  }

  final String tenantUserId;
  final String displayName;
}

class TillHardwarePosDeviceDto {
  const TillHardwarePosDeviceDto({
    required this.posDeviceId,
    required this.deviceCode,
    required this.deviceName,
    required this.deviceStatus,
    required this.isTrusted,
    this.lastSeenAt,
  });

  factory TillHardwarePosDeviceDto.fromJson(Map<String, dynamic> json) {
    return TillHardwarePosDeviceDto(
      posDeviceId: json['posDeviceId']?.toString() ?? '',
      deviceCode: json['deviceCode'] as String? ?? '',
      deviceName: json['deviceName'] as String? ?? '',
      deviceStatus: json['deviceStatus'] as String? ?? '',
      isTrusted: json['isTrusted'] == true,
      lastSeenAt: _dateValue(json['lastSeenAt']),
    );
  }

  final String posDeviceId;
  final String deviceCode;
  final String deviceName;
  final String deviceStatus;
  final bool isTrusted;
  final DateTime? lastSeenAt;
}

class TillAttentionReasonDto {
  const TillAttentionReasonDto({
    required this.code,
    required this.severity,
    required this.message,
    this.hardwareDeviceId,
    this.hardwareType,
    this.observedAt,
  });

  factory TillAttentionReasonDto.fromJson(Map<String, dynamic> json) {
    return TillAttentionReasonDto(
      code: json['code'] as String? ?? '',
      severity: json['severity'] as String? ?? '',
      message: json['message'] as String? ?? '',
      hardwareDeviceId: json['hardwareDeviceId']?.toString(),
      hardwareType: json['hardwareType'] as String?,
      observedAt: _dateValue(json['observedAt']),
    );
  }

  final String code;
  final String severity;
  final String message;
  final String? hardwareDeviceId;
  final String? hardwareType;
  final DateTime? observedAt;
}

class TillHardwareReadinessDto {
  const TillHardwareReadinessDto({
    required this.tillId,
    required this.tillName,
    required this.tillCode,
    required this.outletId,
    required this.outletName,
    required this.connections,
    this.tillStatus,
    this.operationalStatus,
    this.cashier,
    this.lastActivityAt,
    this.posDevice,
    this.attentionReasons = const [],
    this.alertCount = 0,
  });

  factory TillHardwareReadinessDto.fromJson(Map<String, dynamic> json) {
    return TillHardwareReadinessDto(
      tillId: json['tillId']?.toString() ?? json['id']?.toString() ?? '',
      tillName: json['tillName'] as String? ?? '',
      tillCode: json['tillCode'] as String? ?? '',
      outletId: json['outletId']?.toString() ?? '',
      outletName: json['outletName'] as String? ?? '',
      tillStatus: json['tillStatus'] as String?,
      operationalStatus: json['operationalStatus'] as String?,
      cashier: json['cashier'] is Map
          ? TillHardwareCashierDto.fromJson(
              Map<String, dynamic>.from(json['cashier'] as Map),
            )
          : null,
      lastActivityAt: _dateValue(json['lastActivityAt']),
      posDevice: json['posDevice'] is Map
          ? TillHardwarePosDeviceDto.fromJson(
              Map<String, dynamic>.from(json['posDevice'] as Map),
            )
          : null,
      connections: _mapRequiredList(
        json['connections'] ?? json['hardwareConnections'],
        TillHardwareConnectionDto.fromJson,
        fieldName: 'connections',
        allowMissing: true,
      ),
      attentionReasons: _mapRequiredList(
        json['attentionReasons'],
        TillAttentionReasonDto.fromJson,
        fieldName: 'attentionReasons',
        allowMissing: true,
      ),
      alertCount: _intValue(json['alertCount']),
    );
  }

  final String tillId;
  final String tillName;
  final String tillCode;
  final String outletId;
  final String outletName;
  final String? tillStatus;
  final String? operationalStatus;
  final TillHardwareCashierDto? cashier;
  final DateTime? lastActivityAt;
  final TillHardwarePosDeviceDto? posDevice;
  final List<TillHardwareConnectionDto> connections;
  final List<TillAttentionReasonDto> attentionReasons;
  final int alertCount;
}

class TillHardwareConnectionDto {
  const TillHardwareConnectionDto({
    required this.hardwareDeviceId,
    required this.hardwareDeviceName,
    required this.hardwareDeviceType,
    required this.hardwareDeviceCode,
    required this.operationalStatus,
    required this.connectionStatus,
    this.lastTestStatus,
    this.lastTestAt,
    this.lastSeenAt,
    this.assignmentId,
    this.connectionType,
    this.manufacturer,
    this.model,
    this.healthStatus,
    this.warningCode,
    this.warningMessage,
    this.isPrimary = false,
    this.assignmentSource,
  });

  factory TillHardwareConnectionDto.fromJson(Map<String, dynamic> json) {
    return TillHardwareConnectionDto(
      hardwareDeviceId: json['hardwareDeviceId']?.toString() ?? '',
      hardwareDeviceName: json['hardwareDeviceName'] as String? ?? '',
      hardwareDeviceType: json['hardwareDeviceType'] as String? ?? '',
      hardwareDeviceCode: json['hardwareDeviceCode'] as String? ?? '',
      operationalStatus: json['operationalStatus'] as String? ?? '',
      connectionStatus: json['connectionStatus'] as String? ?? '',
      lastTestStatus: json['lastTestStatus'] as String?,
      lastTestAt: _dateValue(json['lastTestAt']),
      lastSeenAt: _dateValue(json['lastSeenAt']),
      assignmentId: json['assignmentId']?.toString(),
      connectionType: json['connectionType'] as String?,
      manufacturer: json['manufacturer'] as String?,
      model: json['model'] as String?,
      healthStatus: json['healthStatus'] as String?,
      warningCode: json['warningCode'] as String?,
      warningMessage: json['warningMessage'] as String?,
      isPrimary: json['isPrimary'] == true,
      assignmentSource: json['assignmentSource'] as String?,
    );
  }

  final String hardwareDeviceId;
  final String hardwareDeviceName;
  final String hardwareDeviceType;
  final String hardwareDeviceCode;
  final String operationalStatus;
  final String connectionStatus;
  final String? lastTestStatus;
  final DateTime? lastTestAt;
  final DateTime? lastSeenAt;
  final String? assignmentId;
  final String? connectionType;
  final String? manufacturer;
  final String? model;
  final String? healthStatus;
  final String? warningCode;
  final String? warningMessage;
  final bool isPrimary;
  final String? assignmentSource;
}

class CreatedTillDto {
  const CreatedTillDto({
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

  factory CreatedTillDto.fromJson(Map<String, dynamic> json) {
    return CreatedTillDto(
      id: json['tillId']?.toString() ?? json['id']?.toString() ?? '',
      outletId: json['outletId']?.toString() ?? '',
      name: json['tillName'] as String? ?? json['name'] as String? ?? '',
      code: json['tillCode'] as String? ?? json['code'] as String? ?? '',
      status: json['status'] as String? ?? '',
      outletName: json['outletName']?.toString(),
      defaultOpeningFloatAmount: json['defaultOpeningFloatAmount'] is num
          ? (json['defaultOpeningFloatAmount'] as num).toDouble()
          : null,
      currencyCode: json['currencyCode']?.toString(),
      defaultCashier: json['defaultCashier'] is Map
          ? CreatedTillCashierDto.fromJson(
              Map<String, dynamic>.from(json['defaultCashier'] as Map))
          : null,
      posDevice: json['posDevice'] is Map
          ? CreatedTillPosDeviceDto.fromJson(
              Map<String, dynamic>.from(json['posDevice'] as Map))
          : null,
      hardwareAssignments: _mapList(json['hardwareAssignments'],
          CreatedTillHardwareAssignmentDto.fromJson),
      createdAt: _dateValue(json['createdAt']),
      updatedAt: _dateValue(json['updatedAt']),
    );
  }

  final String id;
  final String outletId;
  final String name;
  final String code;
  final String status;
  final String? outletName;
  final double? defaultOpeningFloatAmount;
  final String? currencyCode;
  final CreatedTillCashierDto? defaultCashier;
  final CreatedTillPosDeviceDto? posDevice;
  final List<CreatedTillHardwareAssignmentDto> hardwareAssignments;
  final DateTime? createdAt;
  final DateTime? updatedAt;
}

class CreatedTillCashierDto {
  const CreatedTillCashierDto({
    required this.tenantUserId,
    required this.displayName,
  });

  factory CreatedTillCashierDto.fromJson(Map<String, dynamic> json) {
    return CreatedTillCashierDto(
      tenantUserId: json['tenantUserId']?.toString() ?? '',
      displayName: json['displayName']?.toString() ?? '',
    );
  }

  final String tenantUserId;
  final String displayName;
}

class CreatedTillPosDeviceDto {
  const CreatedTillPosDeviceDto({
    required this.posDeviceId,
    required this.deviceName,
    required this.deviceCode,
  });

  factory CreatedTillPosDeviceDto.fromJson(Map<String, dynamic> json) {
    return CreatedTillPosDeviceDto(
      posDeviceId: json['posDeviceId']?.toString() ?? '',
      deviceName: json['deviceName']?.toString() ?? '',
      deviceCode: json['deviceCode']?.toString() ?? '',
    );
  }

  final String posDeviceId;
  final String deviceName;
  final String deviceCode;
}

class CreatedTillHardwareAssignmentDto {
  const CreatedTillHardwareAssignmentDto({
    required this.hardwareDeviceId,
    required this.hardwareDeviceName,
    required this.hardwareDeviceCode,
    required this.hardwareDeviceType,
    required this.isPrimary,
  });

  factory CreatedTillHardwareAssignmentDto.fromJson(Map<String, dynamic> json) {
    return CreatedTillHardwareAssignmentDto(
      hardwareDeviceId: json['hardwareDeviceId']?.toString() ?? '',
      hardwareDeviceName: json['hardwareDeviceName']?.toString() ?? '',
      hardwareDeviceCode: json['hardwareDeviceCode']?.toString() ?? '',
      hardwareDeviceType: json['hardwareDeviceType']?.toString() ?? '',
      isPrimary: json['isPrimary'] == true,
    );
  }

  final String hardwareDeviceId;
  final String hardwareDeviceName;
  final String hardwareDeviceCode;
  final String hardwareDeviceType;
  final bool isPrimary;
}

class OutletOptionDto {
  const OutletOptionDto({
    required this.id,
    required this.name,
    required this.code,
    required this.status,
  });

  factory OutletOptionDto.fromJson(Map<String, dynamic> json) {
    return OutletOptionDto(
      id: json['outletId']?.toString() ?? json['id']?.toString() ?? '',
      name: json['outletName'] as String? ?? json['name'] as String? ?? '',
      code: json['outletCode'] as String? ?? json['code'] as String? ?? '',
      status: json['status'] as String? ?? '',
    );
  }

  final String id;
  final String name;
  final String code;
  final String status;
}

int _intValue(dynamic value, {int fallback = 0}) {
  if (value is int) {
    return value;
  }

  if (value is num) {
    return value.toInt();
  }

  return int.tryParse(value?.toString() ?? '') ?? fallback;
}

DateTime? _dateValue(dynamic value) {
  if (value == null) {
    return null;
  }

  return DateTime.tryParse(value.toString());
}

List<T> _mapList<T>(
  dynamic raw,
  T Function(Map<String, dynamic> json) mapper,
) {
  if (raw is! List) {
    return const [];
  }

  return raw
      .whereType<Map>()
      .map((item) => mapper(Map<String, dynamic>.from(item)))
      .toList(growable: false);
}

/// Strict list mapper for readiness contracts.
///
/// Throws [FormatException] when a list item is not a JSON object so callers
/// do not silently drop invalid hardware/attention rows into an empty list.
List<T> _mapRequiredList<T>(
  dynamic raw,
  T Function(Map<String, dynamic> json) mapper, {
  required String fieldName,
  bool allowMissing = false,
}) {
  if (raw == null) {
    if (allowMissing) {
      return const [];
    }
    throw FormatException('Missing required list field "$fieldName".');
  }

  if (raw is! List) {
    throw FormatException('Field "$fieldName" must be a JSON array.');
  }

  final items = <T>[];
  for (var index = 0; index < raw.length; index++) {
    final item = raw[index];
    if (item is! Map) {
      throw FormatException(
        'Invalid item at $fieldName[$index]: expected a JSON object.',
      );
    }
    items.add(mapper(Map<String, dynamic>.from(item)));
  }
  return List<T>.unmodifiable(items);
}
