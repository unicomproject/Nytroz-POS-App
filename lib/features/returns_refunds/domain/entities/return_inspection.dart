/// Inspection condition option loaded from tenant inspection-condition catalog.
class InspectionConditionOption {
  const InspectionConditionOption({
    required this.id,
    required this.code,
    required this.displayName,
    this.description,
    required this.statusCategory,
    required this.sortOrder,
    required this.isResellable,
    required this.refundImpact,
    required this.requiresNotes,
    required this.requiresPhoto,
    required this.requiresApproval,
  });

  final String id;
  final String code;
  final String displayName;
  final String? description;
  final String statusCategory;
  final int sortOrder;
  final bool isResellable;
  final String refundImpact;
  final bool requiresNotes;
  final bool requiresPhoto;
  final bool requiresApproval;

  factory InspectionConditionOption.fromJson(Map<String, dynamic> json) {
    return InspectionConditionOption(
      id: _readString(json, 'id'),
      code: _readString(json, 'code'),
      displayName: _readString(json, 'displayName'),
      description: _readNullableString(json, 'description'),
      statusCategory: _readString(json, 'statusCategory'),
      sortOrder: _readInt(json, 'sortOrder'),
      isResellable: json['isResellable'] == true,
      refundImpact: _readString(json, 'refundImpact'),
      requiresNotes: json['requiresNotes'] == true,
      requiresPhoto: json['requiresPhoto'] == true,
      requiresApproval: json['requiresApproval'] == true,
    );
  }
}

enum InspectionMediaUploadStatus {
  idle,
  uploading,
  uploaded,
  failed,
}

class InspectionMediaItem {
  const InspectionMediaItem({
    required this.mediaId,
    required this.previewUrl,
    this.localPath,
    this.uploadStatus = InspectionMediaUploadStatus.uploaded,
    this.errorMessage,
  });

  final String mediaId;
  final String previewUrl;
  final String? localPath;
  final InspectionMediaUploadStatus uploadStatus;
  final String? errorMessage;

  InspectionMediaItem copyWith({
    String? mediaId,
    String? previewUrl,
    String? localPath,
    InspectionMediaUploadStatus? uploadStatus,
    String? errorMessage,
  }) {
    return InspectionMediaItem(
      mediaId: mediaId ?? this.mediaId,
      previewUrl: previewUrl ?? this.previewUrl,
      localPath: localPath ?? this.localPath,
      uploadStatus: uploadStatus ?? this.uploadStatus,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class ReturnLineInspection {
  const ReturnLineInspection({
    required this.saleLineId,
    this.conditionCode,
    this.conditionId,
    this.notes = '',
    this.media = const [],
    this.isSelected = true,
  });

  final String saleLineId;
  final String? conditionCode;
  final String? conditionId;
  final String notes;
  final List<InspectionMediaItem> media;
  final bool isSelected;

  bool get hasUploadInProgress => media.any(
      (item) => item.uploadStatus == InspectionMediaUploadStatus.uploading);

  bool get hasUploadFailure => media
      .any((item) => item.uploadStatus == InspectionMediaUploadStatus.failed);

  ReturnLineInspection copyWith({
    String? conditionCode,
    String? conditionId,
    String? notes,
    List<InspectionMediaItem>? media,
    bool? isSelected,
  }) {
    return ReturnLineInspection(
      saleLineId: saleLineId,
      conditionCode: conditionCode ?? this.conditionCode,
      conditionId: conditionId ?? this.conditionId,
      notes: notes ?? this.notes,
      media: media ?? this.media,
      isSelected: isSelected ?? this.isSelected,
    );
  }
}

class InspectionPolicyMessage {
  const InspectionPolicyMessage({
    required this.severity,
    required this.title,
    required this.message,
    this.affectedSaleLineIds = const [],
    this.requiresApproval = false,
    this.refundImpact = '',
  });

  final String severity;
  final String title;
  final String message;
  final List<String> affectedSaleLineIds;
  final bool requiresApproval;
  final String refundImpact;

  factory InspectionPolicyMessage.fromJson(Map<String, dynamic> json) {
    final affected = json['affectedSaleLineIds'];
    return InspectionPolicyMessage(
      severity: _readString(json, 'severity'),
      title: _readString(json, 'title'),
      message: _readString(json, 'message'),
      affectedSaleLineIds: affected is List
          ? affected.map((value) => value.toString()).toList(growable: false)
          : const [],
      requiresApproval: json['requiresApproval'] == true,
      refundImpact: _readString(json, 'refundImpact'),
    );
  }
}

class InspectionValidationResult {
  const InspectionValidationResult({
    this.draftId,
    this.status,
    required this.canContinue,
    required this.selectedItemCount,
    required this.inspectedItemCount,
    required this.pendingItemCount,
    required this.conditionBreakdown,
    required this.policyMessages,
    required this.requiresReview,
    required this.notesMaxLength,
    required this.maxPhotosPerLine,
    required this.maxPhotoSizeBytes,
    this.version,
    this.expiresAt,
    this.requiresInspection = false,
    this.requiresManagerApproval = false,
  });

  final String? draftId;
  final String? status;
  final bool canContinue;
  final int selectedItemCount;
  final int inspectedItemCount;
  final int pendingItemCount;
  final Map<String, int> conditionBreakdown;
  final List<InspectionPolicyMessage> policyMessages;
  final bool requiresReview;
  final int notesMaxLength;
  final int maxPhotosPerLine;
  final int maxPhotoSizeBytes;
  final int? version;
  final DateTime? expiresAt;
  final bool requiresInspection;
  final bool requiresManagerApproval;

  bool get isValidated =>
      canContinue && (status == null || status == 'VALIDATED');

  factory InspectionValidationResult.fromJson(Map<String, dynamic> json) {
    final breakdownRaw = json['conditionBreakdown'];
    final breakdown = <String, int>{};
    if (breakdownRaw is Map) {
      breakdownRaw.forEach((key, value) {
        breakdown[key.toString()] =
            value is int ? value : int.tryParse(value?.toString() ?? '') ?? 0;
      });
    }

    final messagesRaw = json['policyMessages'];
    final messages = messagesRaw is List
        ? messagesRaw
            .whereType<Map>()
            .map((raw) => InspectionPolicyMessage.fromJson(
                  Map<String, dynamic>.from(raw),
                ))
            .toList(growable: false)
        : const <InspectionPolicyMessage>[];

    return InspectionValidationResult(
      draftId: _readNullableString(json, 'draftId'),
      status: _readNullableString(json, 'status'),
      canContinue: json['canContinue'] == true,
      selectedItemCount: _readInt(json, 'selectedItemCount'),
      inspectedItemCount: _readInt(json, 'inspectedItemCount'),
      pendingItemCount: _readInt(json, 'pendingItemCount'),
      conditionBreakdown: breakdown,
      policyMessages: messages,
      requiresReview: json['requiresReview'] == true,
      notesMaxLength: _readInt(json, 'notesMaxLength'),
      maxPhotosPerLine: _readInt(json, 'maxPhotosPerLine'),
      maxPhotoSizeBytes: _readInt(json, 'maxPhotoSizeBytes'),
      version: _readNullableInt(json, 'version'),
      expiresAt: _readDateTime(json, 'expiresAt'),
      requiresInspection: json['requiresInspection'] == true,
      requiresManagerApproval: json['requiresManagerApproval'] == true,
    );
  }
}

class InspectionDraft {
  const InspectionDraft({
    required this.draftId,
    required this.status,
    required this.lines,
    this.version,
    this.expiresAt,
  });

  final String? draftId;
  final String? status;
  final List<InspectionDraftLine> lines;
  final int? version;
  final DateTime? expiresAt;

  factory InspectionDraft.fromJson(Map<String, dynamic> json) {
    final rawLines = json['lines'];
    return InspectionDraft(
      draftId: _readNullableString(json, 'draftId'),
      status: _readNullableString(json, 'status'),
      version: _readNullableInt(json, 'version'),
      expiresAt: _readDateTime(json, 'expiresAt'),
      lines: rawLines is List
          ? rawLines
              .whereType<Map>()
              .map((line) => InspectionDraftLine.fromJson(
                    Map<String, dynamic>.from(line),
                  ))
              .toList(growable: false)
          : const [],
    );
  }
}

class InspectionDraftLine {
  const InspectionDraftLine({
    required this.saleLineId,
    this.conditionCode,
    this.notes = '',
    this.mediaIds = const [],
  });

  final String saleLineId;
  final String? conditionCode;
  final String notes;
  final List<String> mediaIds;

  factory InspectionDraftLine.fromJson(Map<String, dynamic> json) {
    final rawMediaIds = json['mediaIds'];
    return InspectionDraftLine(
      saleLineId: _readString(json, 'saleLineId'),
      conditionCode: _readNullableString(json, 'conditionCode'),
      notes: _readString(json, 'notes'),
      mediaIds: rawMediaIds is List
          ? rawMediaIds.map((id) => id.toString()).toList(growable: false)
          : const [],
    );
  }
}

String _readString(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value == null) {
    return '';
  }
  return value.toString();
}

String? _readNullableString(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value == null) {
    return null;
  }
  final text = value.toString().trim();
  return text.isEmpty ? null : text;
}

int _readInt(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

int? _readNullableInt(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value == null) {
    return null;
  }
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  return int.tryParse(value.toString());
}

DateTime? _readDateTime(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value == null) {
    return null;
  }
  if (value is DateTime) {
    return value;
  }
  return DateTime.tryParse(value.toString());
}
