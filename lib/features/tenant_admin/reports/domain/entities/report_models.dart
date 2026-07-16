import 'report_query.dart';

class ReportFilterOption {
  const ReportFilterOption({
    required this.id,
    required this.code,
    required this.name,
    required this.status,
    this.parentId,
    this.secondaryLabel,
    required this.isActive,
  });

  final String id;
  final String code;
  final String name;
  final String status;
  final String? parentId;
  final String? secondaryLabel;
  final bool isActive;
}

class ReportFilterOptions {
  const ReportFilterOptions(this.groups);

  final Map<String, List<ReportFilterOption>> groups;

  List<ReportFilterOption> forKey(String key) => groups[key] ?? const [];
}

enum ReportTrendDirection { up, down, flat, unknown }

class ReportMetric {
  const ReportMetric({
    required this.key,
    required this.label,
    this.rawValue,
    this.formattedValue,
    this.currencyCode,
    this.comparisonValue,
    this.percentageChange,
    this.comparisonLabel,
    this.trendDirection = ReportTrendDirection.unknown,
    this.requiredPermission,
    this.isSensitive = false,
  });

  final String key;
  final String label;
  final num? rawValue;
  final String? formattedValue;
  final String? currencyCode;
  final num? comparisonValue;
  final double? percentageChange;
  final String? comparisonLabel;
  final ReportTrendDirection trendDirection;
  final String? requiredPermission;
  final bool isSensitive;
}

class ReportRecord {
  const ReportRecord(this.values);

  final Map<String, Object?> values;

  Object? operator [](String key) => values[key];
}

class ReportPagination {
  const ReportPagination({
    required this.page,
    required this.pageSize,
    required this.totalCount,
    required this.totalPages,
  });

  final int page;
  final int pageSize;
  final int totalCount;
  final int totalPages;
}

class ReportSection {
  const ReportSection({
    required this.key,
    required this.title,
    required this.records,
  });

  final String key;
  final String title;
  final List<ReportRecord> records;
}

class ReportResult {
  const ReportResult({
    required this.section,
    required this.metrics,
    required this.sections,
    required this.records,
    required this.pagination,
    this.currencyCode,
    this.generatedAt,
  });

  final String section;
  final List<ReportMetric> metrics;
  final List<ReportSection> sections;
  final List<ReportRecord> records;
  final ReportPagination pagination;
  final String? currencyCode;
  final DateTime? generatedAt;

  bool get isEmpty =>
      metrics.isEmpty &&
      records.isEmpty &&
      sections.every((section) => section.records.isEmpty);
}

class SalesTransactionDetail {
  const SalesTransactionDetail({
    required this.orderId,
    required this.orderNumber,
    required this.invoiceInformation,
    required this.financialSummary,
    required this.sections,
    this.customerEmail,
    this.customerPhone,
    this.currencyCode,
  });

  final String orderId;
  final String orderNumber;
  final Map<String, Object?> invoiceInformation;
  final Map<String, Object?> financialSummary;
  final Map<String, List<ReportRecord>> sections;
  final String? customerEmail;
  final String? customerPhone;
  final String? currencyCode;
}

class ReportExportRequest {
  const ReportExportRequest({
    required this.reportType,
    required this.section,
    required this.format,
    required this.query,
  });

  final String reportType;
  final String section;
  final String format;
  final ReportQuery query;
}

class ReportExport {
  const ReportExport({
    required this.jobId,
    required this.reportType,
    required this.format,
    required this.status,
    required this.requestedAt,
    this.completedAt,
    this.fileName,
    this.downloadUrl,
    this.expiresAt,
    this.errorMessage,
  });

  final String jobId;
  final String reportType;
  final String format;
  final String status;
  final DateTime requestedAt;
  final DateTime? completedAt;
  final String? fileName;
  final String? downloadUrl;
  final DateTime? expiresAt;
  final String? errorMessage;
}
