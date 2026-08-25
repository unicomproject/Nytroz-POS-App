enum TillLifecycleStatus {
  active,
  inactive,
  maintenance,
  deleted,
  unknown,
}

enum TillOperationalStatus {
  online,
  offline,
  unknown,
}

enum TillDisplayStatus {
  online,
  offline,
  needsAttention,
  unknown,
}

class TillCurrentSession {
  const TillCurrentSession({
    required this.id,
    required this.sessionNumber,
    required this.status,
    required this.openedAt,
    this.businessDate,
  });

  final String id;
  final String sessionNumber;
  final String status;
  final DateTime openedAt;
  final DateTime? businessDate;
}

class TillCurrentCashier {
  const TillCurrentCashier({
    required this.id,
    required this.displayName,
    this.profileImageId,
  });

  final String id;
  final String displayName;
  final String? profileImageId;
}

class TillAssignedPosDevice {
  const TillAssignedPosDevice({
    required this.id,
    required this.deviceCode,
    required this.deviceName,
    this.deviceType,
    this.platform,
    this.appVersion,
    required this.status,
    required this.isTrusted,
    this.lastSeenAt,
    this.isHeartbeatFresh,
  });

  final String id;
  final String deviceCode;
  final String deviceName;
  final String? deviceType;
  final String? platform;
  final String? appVersion;
  final String status;
  final bool isTrusted;
  final DateTime? lastSeenAt;
  final bool? isHeartbeatFresh;
}

class TillMonitoringItem {
  const TillMonitoringItem({
    required this.id,
    required this.outletId,
    required this.outletName,
    required this.name,
    required this.code,
    required this.lifecycleStatus,
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

  final String id;
  final String outletId;
  final String outletName;
  final String name;
  final String code;
  final TillLifecycleStatus lifecycleStatus;
  final TillOperationalStatus operationalStatus;
  final TillDisplayStatus displayStatus;
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

class TillMonitoringSummary {
  const TillMonitoringSummary({
    required this.totalTills,
    required this.onlineCount,
    required this.offlineCount,
    required this.inactiveCount,
    required this.needsAttentionCount,
  });

  final int totalTills;
  final int onlineCount;
  final int offlineCount;
  final int inactiveCount;
  final int needsAttentionCount;
}

class TillMonitoringResult {
  const TillMonitoringResult({
    required this.items,
    this.page = 1,
    this.pageSize = 5,
    this.totalCount = 0,
  });

  final List<TillMonitoringItem> items;
  final int page;
  final int pageSize;
  final int totalCount;

  int get totalPages {
    if (pageSize <= 0 || totalCount <= 0) {
      return totalCount > 0 ? 1 : 0;
    }
    return (totalCount / pageSize).ceil();
  }

  int get rangeStart {
    if (totalCount == 0) return 0;
    return ((page - 1) * pageSize) + 1;
  }

  int get rangeEnd {
    if (totalCount == 0) return 0;
    return (page * pageSize).clamp(0, totalCount);
  }
}
