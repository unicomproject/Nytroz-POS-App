enum OfflineOperationStatus { pending, syncing, synced, failed, conflict }

class OfflineOperation {
  const OfflineOperation({
    required this.localId,
    required this.type,
    required this.idempotencyKey,
    required this.createdAt,
    required this.payload,
    this.status = OfflineOperationStatus.pending,
    this.retryCount = 0,
    this.lastErrorCode,
    this.canonicalId,
  });

  final String localId;
  final String type;
  final String idempotencyKey;
  final DateTime createdAt;
  final Map<String, dynamic> payload;
  final OfflineOperationStatus status;
  final int retryCount;
  final String? lastErrorCode;
  final String? canonicalId;

  OfflineOperation copyWith({
    OfflineOperationStatus? status,
    int? retryCount,
    String? lastErrorCode,
    String? canonicalId,
  }) =>
      OfflineOperation(
        localId: localId,
        type: type,
        idempotencyKey: idempotencyKey,
        createdAt: createdAt,
        payload: payload,
        status: status ?? this.status,
        retryCount: retryCount ?? this.retryCount,
        lastErrorCode: lastErrorCode,
        canonicalId: canonicalId ?? this.canonicalId,
      );

  Map<String, dynamic> toJson() => {
        'localId': localId,
        'type': type,
        'idempotencyKey': idempotencyKey,
        'createdAt': createdAt.toUtc().toIso8601String(),
        'payload': payload,
        'status': status.name,
        'retryCount': retryCount,
        if (lastErrorCode != null) 'lastErrorCode': lastErrorCode,
        if (canonicalId != null) 'canonicalId': canonicalId,
      };

  factory OfflineOperation.fromJson(Map<String, dynamic> json) =>
      OfflineOperation(
        localId: json['localId']?.toString() ?? '',
        type: json['type']?.toString() ?? '',
        idempotencyKey: json['idempotencyKey']?.toString() ?? '',
        createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
        payload: json['payload'] is Map
            ? Map<String, dynamic>.from(json['payload'] as Map)
            : const {},
        status: OfflineOperationStatus.values.firstWhere(
          (value) => value.name == json['status'],
          orElse: () => OfflineOperationStatus.pending,
        ),
        retryCount: (json['retryCount'] as num?)?.toInt() ?? 0,
        lastErrorCode: json['lastErrorCode']?.toString(),
        canonicalId: json['canonicalId']?.toString(),
      );
}
