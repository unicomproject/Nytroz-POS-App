import '../../domain/entities/till.dart';
import '../../domain/entities/till_monitoring.dart';
import '../../domain/entities/till_hardware_readiness.dart';
import '../models/till_dto.dart';

class TillMapper {
  const TillMapper._();

  static TillMonitoringItem toMonitoringItem(TillDto dto) {
    return TillMonitoringItem(
      id: dto.id,
      outletId: dto.outletId,
      outletName: dto.outletName,
      name: dto.name,
      code: dto.code,
      lifecycleStatus: _parseLifecycleStatus(dto.status),
      operationalStatus: _parseOperationalStatus(dto.operationalStatus),
      displayStatus: _parseDisplayStatus(dto.displayStatus),
      needsAttention: dto.needsAttention,
      attentionReasonCount: dto.attentionReasonCount,
      currentSessionId: dto.currentSessionId,
      currentSessionStatus: dto.currentSessionStatus,
      currentCashierId: dto.currentCashierId,
      currentCashierName: dto.currentCashierName,
      currentCashierProfileImageId: dto.currentCashierProfileImageId,
      assignedPosDeviceId: dto.assignedPosDeviceId,
      assignedPosDeviceName: dto.assignedPosDeviceName,
      isPosDeviceTrusted: dto.isPosDeviceTrusted,
      lastDeviceSeenAt: dto.lastDeviceSeenAt,
      lastSessionActivityAt: dto.lastSessionActivityAt,
      lastActiveAt: dto.lastActiveAt,
    );
  }

  static TillMonitoringSummary toSummaryEntity(TillListSummaryDto dto) {
    return TillMonitoringSummary(
      totalTills: dto.totalTills,
      onlineCount: dto.onlineCount,
      offlineCount: dto.offlineCount,
      inactiveCount: dto.inactiveCount,
      needsAttentionCount: dto.needsAttentionCount,
    );
  }

  static TillMonitoringResult toListResult(TillListResultDto dto) {
    return TillMonitoringResult(
      items: dto.items.map(toMonitoringItem).toList(growable: false),
      page: dto.page,
      pageSize: dto.pageSize,
      totalCount: dto.totalCount,
    );
  }

  static CreatedTill toCreatedEntity(CreatedTillDto dto) {
    return CreatedTill(
      id: dto.id,
      outletId: dto.outletId,
      name: dto.name,
      code: dto.code,
      status: dto.status,
      outletName: dto.outletName,
      defaultOpeningFloatAmount: dto.defaultOpeningFloatAmount,
      currencyCode: dto.currencyCode,
      defaultCashier: dto.defaultCashier == null
          ? null
          : CreatedTillCashier(
              tenantUserId: dto.defaultCashier!.tenantUserId,
              displayName: dto.defaultCashier!.displayName,
            ),
      posDevice: dto.posDevice == null
          ? null
          : CreatedTillPosDevice(
              posDeviceId: dto.posDevice!.posDeviceId,
              deviceName: dto.posDevice!.deviceName,
              deviceCode: dto.posDevice!.deviceCode,
            ),
      hardwareAssignments: dto.hardwareAssignments
          .map((e) => CreatedTillHardwareAssignment(
                hardwareDeviceId: e.hardwareDeviceId,
                hardwareDeviceName: e.hardwareDeviceName,
                hardwareDeviceCode: e.hardwareDeviceCode,
                hardwareDeviceType: e.hardwareDeviceType,
                isPrimary: e.isPrimary,
              ))
          .toList(growable: false),
      createdAt: dto.createdAt,
      updatedAt: dto.updatedAt,
    );
  }

  static TillDetail toDetailEntity(TillDetailDto dto) {
    return TillDetail(
      id: dto.id,
      outletId: dto.outletId,
      outletName: dto.outletName,
      outletCode: dto.outletCode,
      name: dto.name,
      code: dto.code,
      status: dto.status,
      deviceStatus: dto.operationalStatus,
      needsAttention: dto.needsAttention,
      lastActiveAt: dto.lastActiveAt,
      deviceName: dto.deviceName,
      printerName: dto.printerName,
      scannerName: dto.scannerName,
      cashDrawerName: dto.cashDrawerName,
      cardReaderName: dto.cardReaderName,
      internalNote: dto.internalNote,
      createdAt: dto.createdAt,
      updatedAt: dto.updatedAt,
    );
  }

  static TillHardwareReadiness toHardwareReadiness(
    TillHardwareReadinessDto dto,
  ) {
    final operationalStatus =
        _parseOperationalStatus(dto.operationalStatus ?? '');
    final lifecycleStatus = _parseLifecycleStatus(dto.tillStatus ?? '');
    final displayStatus = _deriveDisplayStatus(
      operationalStatus: operationalStatus,
      alertCount: dto.alertCount,
      attentionReasons: dto.attentionReasons,
    );

    return TillHardwareReadiness(
      tillId: dto.tillId,
      tillName: dto.tillName,
      tillCode: dto.tillCode,
      outletId: dto.outletId,
      outletName: dto.outletName,
      lifecycleStatus: lifecycleStatus,
      operationalStatus: operationalStatus,
      displayStatus: displayStatus,
      currentCashier: dto.cashier == null
          ? null
          : TillCurrentCashier(
              id: dto.cashier!.tenantUserId,
              displayName: dto.cashier!.displayName,
            ),
      assignedPosDevice: dto.posDevice == null
          ? null
          : TillAssignedPosDevice(
              id: dto.posDevice!.posDeviceId,
              deviceCode: dto.posDevice!.deviceCode,
              deviceName: dto.posDevice!.deviceName,
              status: dto.posDevice!.deviceStatus,
              isTrusted: dto.posDevice!.isTrusted,
              lastSeenAt: dto.posDevice!.lastSeenAt,
            ),
      lastActivityAt: dto.lastActivityAt,
      hardwareConnections:
          dto.connections.map(_toHardwareConnection).toList(growable: false),
      alertCount: dto.alertCount,
      attentionReasons: dto.attentionReasons
          .map(
            (reason) => TillAttentionReason(
              code: reason.code,
              severity: _parseAlertSeverity(reason.severity),
              message: reason.message,
              hardwareDeviceId: reason.hardwareDeviceId,
              hardwareDeviceType: reason.hardwareType,
              detectedAt: reason.observedAt,
            ),
          )
          .toList(growable: false),
    );
  }

  static TillHardwareConnection _toHardwareConnection(
    TillHardwareConnectionDto dto,
  ) {
    return TillHardwareConnection(
      id: dto.hardwareDeviceId,
      code: dto.hardwareDeviceCode,
      name: dto.hardwareDeviceName,
      type: dto.hardwareDeviceType,
      assignmentId: dto.assignmentId,
      connectionType: dto.connectionType,
      manufacturer: dto.manufacturer,
      model: dto.model,
      isPrimary: dto.isPrimary,
      assignmentSource: dto.assignmentSource,
      healthStatus: dto.healthStatus,
      warningCode: dto.warningCode,
      deviceStatus: dto.operationalStatus,
      lastSeenAt: dto.lastSeenAt,
      connectionStatus: _parseConnectionStatus(dto.connectionStatus),
      warningMessage: dto.warningMessage,
      latestTest: dto.lastTestStatus == null
          ? null
          : TillHardwareTest(
              id: dto.hardwareDeviceId,
              testType: dto.lastTestStatus ?? 'unknown',
              testStatus: dto.lastTestStatus!,
              testedAt:
                  dto.lastTestAt ?? DateTime.fromMillisecondsSinceEpoch(0),
            ),
    );
  }

  static TillDisplayStatus _deriveDisplayStatus({
    required TillOperationalStatus operationalStatus,
    required int alertCount,
    required List<TillAttentionReasonDto> attentionReasons,
  }) {
    if (alertCount > 0 || attentionReasons.isNotEmpty) {
      return TillDisplayStatus.needsAttention;
    }
    switch (operationalStatus) {
      case TillOperationalStatus.online:
        return TillDisplayStatus.online;
      case TillOperationalStatus.offline:
        return TillDisplayStatus.offline;
      case TillOperationalStatus.unknown:
        return TillDisplayStatus.unknown;
    }
  }

  static TillLifecycleStatus _parseLifecycleStatus(String status) {
    switch (status.trim().toLowerCase()) {
      case 'active':
        return TillLifecycleStatus.active;
      case 'inactive':
        return TillLifecycleStatus.inactive;
      case 'maintenance':
        return TillLifecycleStatus.maintenance;
      case 'deleted':
        return TillLifecycleStatus.deleted;
      default:
        return TillLifecycleStatus.unknown;
    }
  }

  static TillOperationalStatus _parseOperationalStatus(String status) {
    switch (status.trim().toLowerCase()) {
      case 'online':
        return TillOperationalStatus.online;
      case 'offline':
        return TillOperationalStatus.offline;
      default:
        return TillOperationalStatus.unknown;
    }
  }

  static TillDisplayStatus _parseDisplayStatus(String status) {
    switch (status.trim().toLowerCase()) {
      case 'online':
        return TillDisplayStatus.online;
      case 'offline':
        return TillDisplayStatus.offline;
      case 'needs_attention':
      case 'needsattention':
        return TillDisplayStatus.needsAttention;
      default:
        return TillDisplayStatus.unknown;
    }
  }

  /// Parses Backend canonical connection statuses.
  ///
  /// Also accepts legacy lowercase values for older payloads.
  static TillHardwareConnectionStatus _parseConnectionStatus(String status) {
    switch (status.trim().toUpperCase()) {
      case 'CONNECTED':
        return TillHardwareConnectionStatus.connected;
      case 'DISCONNECTED':
      case 'OFFLINE':
      case 'FAILED':
        return TillHardwareConnectionStatus.disconnected;
      case 'NEEDS_ATTENTION':
      case 'WARNING':
        return TillHardwareConnectionStatus.needsAttention;
      case 'MAINTENANCE':
        return TillHardwareConnectionStatus.maintenance;
      case 'NOT_ASSIGNED':
        return TillHardwareConnectionStatus.notAssigned;
      default:
        return TillHardwareConnectionStatus.unknown;
    }
  }

  static TillAlertSeverity _parseAlertSeverity(String severity) {
    switch (severity.trim().toUpperCase()) {
      case 'INFO':
        return TillAlertSeverity.info;
      case 'WARNING':
        return TillAlertSeverity.warning;
      case 'ERROR':
        return TillAlertSeverity.error;
      case 'CRITICAL':
        return TillAlertSeverity.critical;
      default:
        return TillAlertSeverity.unknown;
    }
  }
}
