import 'till_monitoring.dart';

/// Canonical Backend connection-status vocabulary for Till hardware readiness.
enum TillHardwareConnectionStatus {
  connected,
  disconnected,
  needsAttention,
  maintenance,
  notAssigned,
  unknown,
}

enum TillAlertSeverity {
  info,
  warning,
  error,
  critical,
  unknown,
}

class TillHardwareConnection {
  const TillHardwareConnection({
    required this.id,
    required this.code,
    required this.name,
    required this.type,
    this.assignmentId,
    this.connectionType,
    this.manufacturer,
    this.model,
    this.serialNumber,
    this.firmwareVersion,
    this.isPrimary = false,
    this.assignmentSource,
    this.healthStatus,
    this.warningCode,
    required this.deviceStatus,
    this.lastSeenAt,
    required this.connectionStatus,
    this.latestTest,
    this.warningMessage,
  });

  final String id;
  final String code;
  final String name;
  final String type;
  final String? assignmentId;
  final String? connectionType;
  final String? manufacturer;
  final String? model;
  final String? serialNumber;
  final String? firmwareVersion;
  final bool isPrimary;
  final String? assignmentSource;
  final String? healthStatus;
  final String? warningCode;
  final String deviceStatus;
  final DateTime? lastSeenAt;
  final TillHardwareConnectionStatus connectionStatus;
  final TillHardwareTest? latestTest;
  final String? warningMessage;
}

class TillHardwareTest {
  const TillHardwareTest({
    required this.id,
    required this.testType,
    required this.testStatus,
    this.resultMessage,
    required this.testedAt,
  });

  final String id;
  final String testType;
  final String testStatus;
  final String? resultMessage;
  final DateTime testedAt;
}

class TillAttentionReason {
  const TillAttentionReason({
    required this.code,
    required this.severity,
    required this.message,
    this.hardwareDeviceId,
    this.hardwareDeviceType,
    this.detectedAt,
  });

  final String code;
  final TillAlertSeverity severity;
  final String message;
  final String? hardwareDeviceId;
  final String? hardwareDeviceType;
  final DateTime? detectedAt;
}

class TillHardwareReadiness {
  const TillHardwareReadiness({
    required this.tillId,
    required this.tillName,
    required this.tillCode,
    required this.outletId,
    required this.outletName,
    required this.lifecycleStatus,
    required this.operationalStatus,
    required this.displayStatus,
    this.currentSession,
    this.currentCashier,
    this.assignedPosDevice,
    this.lastActivityAt,
    required this.hardwareConnections,
    required this.alertCount,
    required this.attentionReasons,
  });

  final String tillId;
  final String tillName;
  final String tillCode;
  final String outletId;
  final String outletName;
  final TillLifecycleStatus lifecycleStatus;
  final TillOperationalStatus operationalStatus;
  final TillDisplayStatus displayStatus;

  final TillCurrentSession? currentSession;
  final TillCurrentCashier? currentCashier;
  final TillAssignedPosDevice? assignedPosDevice;
  final DateTime? lastActivityAt;

  final List<TillHardwareConnection> hardwareConnections;
  final int alertCount;
  final List<TillAttentionReason> attentionReasons;
}
