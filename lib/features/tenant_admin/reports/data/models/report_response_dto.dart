import 'report_json.dart';

class ReportMetricDto {
  const ReportMetricDto({
    required this.key,
    required this.label,
    this.rawValue,
    this.formattedValue,
    this.currencyCode,
    this.comparisonValue,
    this.percentageChange,
    this.comparisonLabel,
    this.trendDirection,
    this.requiredPermission,
    required this.isSensitive,
  });

  factory ReportMetricDto.fromJson(Map<String, dynamic> json) {
    return ReportMetricDto(
      key: json['key']?.toString() ?? '',
      label: json['label']?.toString() ?? '',
      rawValue: json['rawValue'] is num
          ? json['rawValue'] as num
          : reportDouble(json['rawValue']),
      formattedValue: reportNullableString(json['formattedValue']),
      currencyCode: reportNullableString(json['currencyCode']),
      comparisonValue: json['comparisonValue'] is num
          ? json['comparisonValue'] as num
          : reportDouble(json['comparisonValue']),
      percentageChange: reportDouble(json['percentageChange']),
      comparisonLabel: reportNullableString(json['comparisonLabel']),
      trendDirection: reportNullableString(json['trendDirection']),
      requiredPermission: reportNullableString(json['requiredPermission']),
      isSensitive: reportBool(json['isSensitive']),
    );
  }

  final String key;
  final String label;
  final num? rawValue;
  final String? formattedValue;
  final String? currencyCode;
  final num? comparisonValue;
  final double? percentageChange;
  final String? comparisonLabel;
  final String? trendDirection;
  final String? requiredPermission;
  final bool isSensitive;

  static ReportMetricDto fromSummaryEntry(String key, Object? value) {
    return ReportMetricDto(
      key: key,
      label: _labelFromKey(key),
      rawValue: value is num ? value : reportDouble(value),
      formattedValue: value is num ? null : reportNullableString(value),
      currencyCode: null,
      comparisonValue: null,
      percentageChange: null,
      comparisonLabel: null,
      trendDirection: null,
      requiredPermission: null,
      isSensitive: _isSensitiveSummaryKey(key),
    );
  }
}

class ReportPaginationDto {
  const ReportPaginationDto({
    required this.page,
    required this.pageSize,
    required this.totalCount,
    required this.totalPages,
  });

  factory ReportPaginationDto.fromJson(Map<String, dynamic> json) {
    final page = reportInt(json['page'], fallback: 1);
    final pageSize = reportInt(json['pageSize'], fallback: 25);
    final totalCount = reportInt(json['totalCount']);
    return ReportPaginationDto(
      page: page,
      pageSize: pageSize,
      totalCount: totalCount,
      totalPages: reportInt(
        json['totalPages'],
        fallback: pageSize == 0 ? 0 : (totalCount / pageSize).ceil(),
      ),
    );
  }

  final int page;
  final int pageSize;
  final int totalCount;
  final int totalPages;
}

class ReportSectionDto {
  const ReportSectionDto({
    required this.key,
    required this.title,
    required this.records,
  });

  factory ReportSectionDto.fromJson(Map<String, dynamic> json) {
    return ReportSectionDto(
      key: json['key']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      records: reportJsonList(json['records'] ?? json['items']),
    );
  }

  final String key;
  final String title;
  final List<Map<String, dynamic>> records;

  static ReportSectionDto fromSectionEntry(String key, Object? value) {
    return ReportSectionDto(
      key: key,
      title: _labelFromKey(key),
      records: reportJsonList(value),
    );
  }
}

class ReportResultDto {
  const ReportResultDto({
    required this.section,
    required this.metrics,
    required this.sections,
    required this.records,
    required this.pagination,
    this.currencyCode,
    this.generatedAt,
  });

  factory ReportResultDto.fromJson(Map<String, dynamic> json) {
    final paginationJson = reportJsonMap(json['pagination']);
    final paginationSource = paginationJson.isEmpty ? json : paginationJson;
    final records =
        reportJsonList(json['records'] ?? json['items'] ?? json['rows']);
    final summary = reportJsonMap(json['summary']);
    final sectionsValue = json['sections'];
    return ReportResultDto(
      section: json['section']?.toString() ?? '',
      metrics: _parseMetrics(json['metrics'], summary),
      sections: _parseSections(sectionsValue),
      records: records,
      pagination: ReportPaginationDto.fromJson({
        ...paginationSource,
        if (!paginationSource.containsKey('totalCount'))
          'totalCount': records.length,
      }),
      currencyCode: reportNullableString(json['currencyCode']),
      generatedAt: reportDateTime(json['generatedAt']),
    );
  }

  final String section;
  final List<ReportMetricDto> metrics;
  final List<ReportSectionDto> sections;
  final List<Map<String, dynamic>> records;
  final ReportPaginationDto pagination;
  final String? currencyCode;
  final DateTime? generatedAt;
}

List<ReportMetricDto> _parseMetrics(
  Object? metricsValue,
  Map<String, dynamic> summary,
) {
  final metrics = reportJsonList(metricsValue).map(ReportMetricDto.fromJson);
  if (metrics.isNotEmpty) {
    return metrics.toList();
  }

  return summary.entries
      .where((entry) => entry.value is num || entry.value is String)
      .map((entry) => ReportMetricDto.fromSummaryEntry(entry.key, entry.value))
      .toList();
}

List<ReportSectionDto> _parseSections(Object? value) {
  final listSections = reportJsonList(value).map(ReportSectionDto.fromJson);
  if (listSections.isNotEmpty) {
    return listSections.toList();
  }

  final mapSections = reportJsonMap(value);
  return mapSections.entries
      .map((entry) => ReportSectionDto.fromSectionEntry(entry.key, entry.value))
      .where((section) => section.records.isNotEmpty)
      .toList();
}

String _labelFromKey(String key) {
  final words = key
      .replaceAllMapped(RegExp(r'([a-z0-9])([A-Z])'), (match) {
        return '${match.group(1)} ${match.group(2)}';
      })
      .replaceAll(RegExp(r'[_-]+'), ' ')
      .trim()
      .split(RegExp(r'\s+'));
  return words
      .where((word) => word.isNotEmpty)
      .map((word) => '${word[0].toUpperCase()}${word.substring(1)}')
      .join(' ');
}

bool _isSensitiveSummaryKey(String key) {
  final normalized = key.toLowerCase();
  return normalized.contains('cost') || normalized.contains('stockvalue');
}
