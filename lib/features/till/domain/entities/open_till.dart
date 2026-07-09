import '../../../device_activation/domain/entities/pos_device_context.dart';

class OpenTillForm {
  const OpenTillForm({
    required this.deviceContext,
    required this.openingFloat,
    required this.openingNote,
  });

  final PosDeviceContext deviceContext;
  final double openingFloat;
  final String openingNote;
}

class TillSession {
  const TillSession({
    required this.sessionId,
    required this.tenantId,
    required this.outletId,
    required this.outletName,
    required this.tillId,
    required this.tillCode,
    required this.tillName,
    required this.openedDeviceId,
    required this.openingFloat,
    required this.status,
    required this.openedAt,
    this.openingNote,
  });

  final String sessionId;
  final String tenantId;
  final String outletId;
  final String outletName;
  final String tillId;
  final String tillCode;
  final String tillName;
  final String openedDeviceId;
  final double openingFloat;
  final String status;
  final DateTime openedAt;
  final String? openingNote;

  Map<String, dynamic> toJson() {
    return {
      'sessionId': sessionId,
      'tenantId': tenantId,
      'outletId': outletId,
      'outletName': outletName,
      'tillId': tillId,
      'tillCode': tillCode,
      'tillName': tillName,
      'openedDeviceId': openedDeviceId,
      'openingFloat': openingFloat,
      'status': status,
      'openedAt': openedAt.toIso8601String(),
      'openingNote': openingNote,
    };
  }

  factory TillSession.fromJson(Map<String, dynamic> json) {
    return TillSession(
      sessionId: json['sessionId'] as String? ?? '',
      tenantId: json['tenantId'] as String? ?? '',
      outletId: json['outletId'] as String? ?? '',
      outletName: json['outletName'] as String? ?? '',
      tillId: json['tillId'] as String? ?? '',
      tillCode: json['tillCode'] as String? ?? '',
      tillName: json['tillName'] as String? ?? '',
      openedDeviceId: json['openedDeviceId'] as String? ?? '',
      openingFloat: (json['openingFloat'] as num?)?.toDouble() ?? 0,
      status: json['status'] as String? ?? '',
      openedAt: DateTime.tryParse(json['openedAt']?.toString() ?? '') ??
          DateTime.now(),
      openingNote: json['openingNote'] as String?,
    );
  }
}

class TillException implements Exception {
  const TillException(this.message);

  final String message;
}

class CloseTillForm {
  const CloseTillForm({
    required this.deviceContext,
    required this.countedCash,
    required this.expectedCash,
    this.mismatchReason,
    this.closingNote,
  });

  final PosDeviceContext deviceContext;
  final double countedCash;
  final double expectedCash;
  final String? mismatchReason;
  final String? closingNote;
}

class ClosedTillSession {
  const ClosedTillSession({
    required this.sessionId,
    required this.tillId,
    required this.openingFloat,
    required this.expectedCash,
    required this.countedCash,
    required this.cashDifference,
    required this.status,
    required this.openedAt,
    required this.closedAt,
    this.closingNote,
  });

  final String sessionId;
  final String tillId;
  final double openingFloat;
  final double expectedCash;
  final double countedCash;
  final double cashDifference;
  final String status;
  final DateTime openedAt;
  final DateTime closedAt;
  final String? closingNote;
}
