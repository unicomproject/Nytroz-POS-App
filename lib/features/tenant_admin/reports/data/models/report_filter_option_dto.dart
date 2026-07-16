import 'report_json.dart';

class ReportFilterOptionDto {
  const ReportFilterOptionDto({
    required this.id,
    required this.code,
    required this.name,
    required this.status,
    this.parentId,
    this.secondaryLabel,
    required this.isActive,
  });

  factory ReportFilterOptionDto.fromJson(Map<String, dynamic> json) {
    final status = json['status']?.toString() ?? '';
    return ReportFilterOptionDto(
      id: json['id']?.toString() ?? '',
      code: json['code']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      status: status,
      parentId: reportNullableString(json['parentId']),
      secondaryLabel: reportNullableString(json['secondaryLabel']),
      isActive: reportBool(
        json['isActive'],
        fallback: status.toUpperCase() == 'ACTIVE',
      ),
    );
  }

  final String id;
  final String code;
  final String name;
  final String status;
  final String? parentId;
  final String? secondaryLabel;
  final bool isActive;
}

class ReportFilterOptionsDto {
  const ReportFilterOptionsDto(this.groups);

  factory ReportFilterOptionsDto.fromJson(Map<String, dynamic> json) {
    final wrappedGroups = reportJsonMap(json['groups']);
    final source = wrappedGroups.isEmpty ? json : wrappedGroups;
    final groups = <String, List<ReportFilterOptionDto>>{};
    for (final entry in source.entries) {
      if (entry.value is! List) {
        continue;
      }
      groups[entry.key] = reportJsonList(entry.value)
          .map(ReportFilterOptionDto.fromJson)
          .toList();
    }
    return ReportFilterOptionsDto(groups);
  }

  final Map<String, List<ReportFilterOptionDto>> groups;
}
