import '../models/completed_sale_receipt.dart';

enum PrintOperationState {
  pendingPrint,
  printing,
  printSucceeded,
  printFailedConfirmed,
  printOutcomeUnknown,
  pendingAudit,
  auditing,
  auditFailed,
  completed,
  cancelled,
  requiresOperatorDecision,
}

class PrintOperation {
  const PrintOperation({
    required this.operationId,
    required this.receipt,
    required this.printRequestId,
    required this.operatorUserId,
    required this.deviceId,
    required this.createdAt,
    required this.updatedAt,
    required this.state,
    this.audit,
    this.failureCategory,
    this.failureMessage,
    this.physicalAttemptCount = 0,
    this.auditAttemptCount = 0,
  });

  final String operationId;
  final CompletedSaleReceipt receipt;
  final String printRequestId;
  final String operatorUserId;
  final String deviceId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final PrintOperationState state;
  final Map<String, dynamic>? audit;
  final String? failureCategory;
  final String? failureMessage;
  final int physicalAttemptCount;
  final int auditAttemptCount;

  PrintOperation copyWith({
    PrintOperationState? state,
    Map<String, dynamic>? audit,
    String? failureCategory,
    String? failureMessage,
    int? physicalAttemptCount,
    int? auditAttemptCount,
  }) =>
      PrintOperation(
        operationId: operationId,
        receipt: receipt,
        printRequestId: printRequestId,
        operatorUserId: operatorUserId,
        deviceId: deviceId,
        createdAt: createdAt,
        updatedAt: DateTime.now().toUtc(),
        state: state ?? this.state,
        audit: audit ?? this.audit,
        failureCategory: failureCategory ?? this.failureCategory,
        failureMessage: failureMessage ?? this.failureMessage,
        physicalAttemptCount: physicalAttemptCount ?? this.physicalAttemptCount,
        auditAttemptCount: auditAttemptCount ?? this.auditAttemptCount,
      );

  Map<String, dynamic> toJson() => {
        'operationId': operationId,
        'receipt': receipt.toJson(),
        'printRequestId': printRequestId,
        'operatorUserId': operatorUserId,
        'deviceId': deviceId,
        'createdAt': createdAt.toUtc().toIso8601String(),
        'updatedAt': updatedAt.toUtc().toIso8601String(),
        'state': state.name,
        'audit': audit,
        'failureCategory': failureCategory,
        'failureMessage': failureMessage,
        'physicalAttemptCount': physicalAttemptCount,
        'auditAttemptCount': auditAttemptCount,
      };

  factory PrintOperation.fromJson(Map<String, dynamic> json) {
    final receiptJson = (json['receipt'] as Map)
        .map((key, value) => MapEntry(key.toString(), value));
    return PrintOperation(
      operationId: json['operationId'].toString(),
      receipt: CompletedSaleReceipt.fromJson(receiptJson),
      printRequestId: json['printRequestId'].toString(),
      operatorUserId: json['operatorUserId']?.toString() ?? '',
      deviceId: json['deviceId']?.toString() ?? '',
      createdAt: DateTime.parse(json['createdAt'].toString()).toUtc(),
      updatedAt: DateTime.parse(json['updatedAt'].toString()).toUtc(),
      state: PrintOperationState.values.firstWhere(
        (value) => value.name == json['state'],
        orElse: () => PrintOperationState.requiresOperatorDecision,
      ),
      audit: (json['audit'] as Map?)
          ?.map((key, value) => MapEntry(key.toString(), value)),
      failureCategory: json['failureCategory']?.toString(),
      failureMessage: json['failureMessage']?.toString(),
      physicalAttemptCount:
          (json['physicalAttemptCount'] as num?)?.toInt() ?? 0,
      auditAttemptCount: (json['auditAttemptCount'] as num?)?.toInt() ?? 0,
    );
  }
}
