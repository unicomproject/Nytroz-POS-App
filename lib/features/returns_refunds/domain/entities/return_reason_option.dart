/// Return reason option loaded from the tenant return-reasons catalog.
class ReturnReasonOption {
  const ReturnReasonOption({
    required this.id,
    required this.code,
    required this.displayName,
    this.description,
    required this.sortOrder,
    required this.appliesToReturn,
    required this.appliesToExchange,
    required this.requiresNotes,
    required this.requiresInspection,
    required this.requiresManagerApproval,
  });

  final String id;
  final String code;
  final String displayName;
  final String? description;
  final int sortOrder;
  final bool appliesToReturn;
  final bool appliesToExchange;
  final bool requiresNotes;
  final bool requiresInspection;
  final bool requiresManagerApproval;

  factory ReturnReasonOption.fromJson(Map<String, dynamic> json) {
    return ReturnReasonOption(
      id: _readString(json, 'id'),
      code: _readString(json, 'code'),
      displayName: _readString(json, 'displayName'),
      description: _readNullableString(json, 'description'),
      sortOrder: _readInt(json, 'sortOrder'),
      appliesToReturn: json['appliesToReturn'] == true,
      appliesToExchange: json['appliesToExchange'] == true,
      requiresNotes: json['requiresNotes'] == true,
      requiresInspection: json['requiresInspection'] == true,
      requiresManagerApproval: json['requiresManagerApproval'] == true,
    );
  }
}

class ReturnLineReasonSelection {
  const ReturnLineReasonSelection({
    required this.saleLineId,
    required this.reasonCode,
    this.reasonId,
    this.notes = '',
    this.requiresNotes = false,
    this.requiresInspection = false,
    this.requiresManagerApproval = false,
  });

  final String saleLineId;
  final String reasonCode;
  final String? reasonId;
  final String notes;
  final bool requiresNotes;
  final bool requiresInspection;
  final bool requiresManagerApproval;

  ReturnLineReasonSelection copyWith({
    String? reasonCode,
    String? reasonId,
    String? notes,
    bool? requiresNotes,
    bool? requiresInspection,
    bool? requiresManagerApproval,
  }) {
    return ReturnLineReasonSelection(
      saleLineId: saleLineId,
      reasonCode: reasonCode ?? this.reasonCode,
      reasonId: reasonId ?? this.reasonId,
      notes: notes ?? this.notes,
      requiresNotes: requiresNotes ?? this.requiresNotes,
      requiresInspection: requiresInspection ?? this.requiresInspection,
      requiresManagerApproval:
          requiresManagerApproval ?? this.requiresManagerApproval,
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
