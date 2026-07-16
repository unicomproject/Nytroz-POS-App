import 'report_json.dart';

class ReportExportDto {
  const ReportExportDto({
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

  factory ReportExportDto.fromJson(Map<String, dynamic> json) {
    return ReportExportDto(
      jobId: json['jobId']?.toString() ?? '',
      reportType: json['reportType']?.toString() ?? '',
      format: json['format']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      requestedAt: reportDateTime(json['requestedAt']) ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      completedAt: reportDateTime(json['completedAt']),
      fileName: reportNullableString(json['fileName']),
      downloadUrl: reportNullableString(json['downloadUrl']),
      expiresAt: reportDateTime(json['expiresAt']),
      errorMessage: reportNullableString(json['errorMessage']),
    );
  }

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
