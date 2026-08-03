enum DrawerOperationState {
  pendingRegister,
  registering,
  opening,
  agentAccepted,
  opened,
  failed,
  unknown,
  requiresOperatorDecision,
  cancelled,
}

class DrawerOperation {
  const DrawerOperation({
    required this.operationId,
    required this.requestId,
    required this.posDeviceId,
    required this.drawerPurpose,
    required this.state,
    required this.createdAt,
    required this.updatedAt,
    this.reason,
    this.businessReferenceId,
    required this.drawerPort,
    required this.pulseOnMilliseconds,
    required this.pulseOffMilliseconds,
    this.linkedReceiptPrinterId,
    this.failureCategory,
    this.failureMessage,
    this.physicalAttemptCount = 0,
    this.finalizeAttemptCount = 0,
  });

  final String operationId;
  final String requestId;
  final String posDeviceId;
  final String drawerPurpose;
  final DrawerOperationState state;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? reason;
  final String? businessReferenceId;
  final String drawerPort;
  final int pulseOnMilliseconds;
  final int pulseOffMilliseconds;
  final String? linkedReceiptPrinterId;
  final String? failureCategory;
  final String? failureMessage;
  final int physicalAttemptCount;
  final int finalizeAttemptCount;

  DrawerOperation copyWith({
    DrawerOperationState? state,
    String? failureCategory,
    String? failureMessage,
    int? physicalAttemptCount,
    int? finalizeAttemptCount,
  }) =>
      DrawerOperation(
        operationId: operationId,
        requestId: requestId,
        posDeviceId: posDeviceId,
        drawerPurpose: drawerPurpose,
        state: state ?? this.state,
        createdAt: createdAt,
        updatedAt: DateTime.now().toUtc(),
        reason: reason,
        businessReferenceId: businessReferenceId,
        drawerPort: drawerPort,
        pulseOnMilliseconds: pulseOnMilliseconds,
        pulseOffMilliseconds: pulseOffMilliseconds,
        linkedReceiptPrinterId: linkedReceiptPrinterId,
        failureCategory: failureCategory ?? this.failureCategory,
        failureMessage: failureMessage ?? this.failureMessage,
        physicalAttemptCount: physicalAttemptCount ?? this.physicalAttemptCount,
        finalizeAttemptCount: finalizeAttemptCount ?? this.finalizeAttemptCount,
      );

  Map<String, dynamic> toJson() => {
        'operationId': operationId,
        'requestId': requestId,
        'posDeviceId': posDeviceId,
        'drawerPurpose': drawerPurpose,
        'state': state.name,
        'createdAt': createdAt.toUtc().toIso8601String(),
        'updatedAt': updatedAt.toUtc().toIso8601String(),
        'reason': reason,
        'businessReferenceId': businessReferenceId,
        'drawerPort': drawerPort,
        'pulseOnMilliseconds': pulseOnMilliseconds,
        'pulseOffMilliseconds': pulseOffMilliseconds,
        'linkedReceiptPrinterId': linkedReceiptPrinterId,
        'failureCategory': failureCategory,
        'failureMessage': failureMessage,
        'physicalAttemptCount': physicalAttemptCount,
        'finalizeAttemptCount': finalizeAttemptCount,
      };

  factory DrawerOperation.fromJson(Map<String, dynamic> json) {
    return DrawerOperation(
      operationId: json['operationId'].toString(),
      requestId: json['requestId'].toString(),
      posDeviceId: json['posDeviceId']?.toString() ?? '',
      drawerPurpose: json['drawerPurpose']?.toString() ?? 'hardwareTest',
      state: DrawerOperationState.values.firstWhere(
        (value) => value.name == json['state'],
        orElse: () => DrawerOperationState.requiresOperatorDecision,
      ),
      createdAt: DateTime.parse(json['createdAt'].toString()).toUtc(),
      updatedAt: DateTime.parse(json['updatedAt'].toString()).toUtc(),
      reason: json['reason']?.toString(),
      businessReferenceId: json['businessReferenceId']?.toString(),
      drawerPort: json['drawerPort']?.toString() ?? 'drawerPin2',
      pulseOnMilliseconds:
          (json['pulseOnMilliseconds'] as num?)?.toInt() ?? 100,
      pulseOffMilliseconds:
          (json['pulseOffMilliseconds'] as num?)?.toInt() ?? 200,
      linkedReceiptPrinterId: json['linkedReceiptPrinterId']?.toString(),
      failureCategory: json['failureCategory']?.toString(),
      failureMessage: json['failureMessage']?.toString(),
      physicalAttemptCount:
          (json['physicalAttemptCount'] as num?)?.toInt() ?? 0,
      finalizeAttemptCount:
          (json['finalizeAttemptCount'] as num?)?.toInt() ?? 0,
    );
  }
}
