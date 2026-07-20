import '../../domain/entities/return_resolution_type.dart';

class ReturnResolution {
  const ReturnResolution({
    required this.saleId,
    required this.draftId,
    required this.resolution,
    required this.selectedAt,
    required this.selectedByTenantUserId,
    required this.version,
    required this.draftStatus,
    required this.expiresAt,
    required this.availableOptions,
    required this.refundAllowed,
    required this.exchangeAllowed,
    required this.requiresManagerApproval,
    required this.requiresInspection,
    required this.canChange,
    required this.nextStep,
  });

  final String saleId;
  final String draftId;
  final String? resolution;
  final DateTime? selectedAt;
  final String? selectedByTenantUserId;
  final int version;
  final String draftStatus;
  final DateTime expiresAt;
  final List<ReturnResolutionOption> availableOptions;
  final bool refundAllowed;
  final bool exchangeAllowed;
  final bool requiresManagerApproval;
  final bool requiresInspection;
  final bool canChange;
  final String nextStep;

  ReturnResolutionType? get resolutionType {
    switch (resolution?.trim().toUpperCase()) {
      case 'EXCHANGE':
        return ReturnResolutionType.exchange;
      case 'REFUND':
        return ReturnResolutionType.refund;
      default:
        return null;
    }
  }

  factory ReturnResolution.fromJson(Map<String, dynamic> json) {
    final optionsJson = json['availableOptions'];
    return ReturnResolution(
      saleId: json['saleId']?.toString() ?? '',
      draftId: json['draftId']?.toString() ?? '',
      resolution: (json['resolutionType'] ?? json['resolution'])?.toString(),
      selectedAt: DateTime.tryParse(
        (json['resolutionSelectedAt'] ?? json['selectedAt'])?.toString() ?? '',
      ),
      selectedByTenantUserId:
          json['resolutionSelectedByTenantUserId']?.toString(),
      version: (json['version'] as num?)?.toInt() ?? 0,
      draftStatus: json['draftStatus']?.toString() ?? '',
      expiresAt: DateTime.tryParse(json['expiresAt']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      availableOptions: optionsJson is List
          ? optionsJson
              .whereType<Map>()
              .map(
                (item) => ReturnResolutionOption.fromJson(
                  Map<String, dynamic>.from(item),
                ),
              )
              .toList(growable: false)
          : const [],
      refundAllowed: json['refundAllowed'] == true,
      exchangeAllowed: json['exchangeAllowed'] == true,
      requiresManagerApproval: json['requiresManagerApproval'] == true,
      requiresInspection: json['requiresInspection'] == true,
      canChange: json['canChange'] == true,
      nextStep: json['nextStep']?.toString() ?? 'CHOOSE_OPTION',
    );
  }

  bool get isValidated =>
      draftStatus.toUpperCase() == 'VALIDATED' &&
      expiresAt.isAfter(DateTime.now().toUtc());
}

class ReturnResolutionOption {
  const ReturnResolutionOption({
    required this.resolutionType,
    required this.allowed,
    this.unavailableReasonCode,
  });

  final String resolutionType;
  final bool allowed;
  final String? unavailableReasonCode;

  factory ReturnResolutionOption.fromJson(Map<String, dynamic> json) {
    return ReturnResolutionOption(
      resolutionType: json['resolutionType']?.toString() ?? '',
      allowed: json['allowed'] == true,
      unavailableReasonCode: json['unavailableReasonCode']?.toString(),
    );
  }
}
