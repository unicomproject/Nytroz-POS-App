import '../../domain/entities/report_models.dart';
import '../models/report_export_dto.dart';
import '../models/report_filter_option_dto.dart';
import '../models/report_response_dto.dart';
import '../models/sales_transaction_detail_dto.dart';

abstract final class ReportMapper {
  static ReportFilterOptions toFilterOptions(ReportFilterOptionsDto dto) {
    return ReportFilterOptions(
      dto.groups.map(
        (key, options) => MapEntry(
          key,
          options
              .map(
                (option) => ReportFilterOption(
                  id: option.id,
                  code: option.code,
                  name: option.name,
                  status: option.status,
                  parentId: option.parentId,
                  secondaryLabel: option.secondaryLabel,
                  isActive: option.isActive,
                ),
              )
              .toList(),
        ),
      ),
    );
  }

  static ReportResult toResult(ReportResultDto dto) {
    return ReportResult(
      section: dto.section,
      metrics: dto.metrics.map(_toMetric).toList(),
      sections: dto.sections
          .map(
            (section) => ReportSection(
              key: section.key,
              title: section.title,
              records: section.records.map(ReportRecord.new).toList(),
            ),
          )
          .toList(),
      records: dto.records.map(ReportRecord.new).toList(),
      pagination: ReportPagination(
        page: dto.pagination.page,
        pageSize: dto.pagination.pageSize,
        totalCount: dto.pagination.totalCount,
        totalPages: dto.pagination.totalPages,
      ),
      currencyCode: dto.currencyCode,
      generatedAt: dto.generatedAt,
    );
  }

  static SalesTransactionDetail toTransactionDetail(
    SalesTransactionDetailDto dto,
  ) {
    return SalesTransactionDetail(
      orderId: dto.orderId,
      orderNumber: dto.orderNumber,
      invoiceInformation: dto.invoiceInformation,
      financialSummary: dto.financialSummary,
      sections: dto.sections.map(
        (key, records) => MapEntry(
          key,
          records.map(ReportRecord.new).toList(),
        ),
      ),
      customerEmail: dto.customerEmail,
      customerPhone: dto.customerPhone,
      currencyCode: dto.currencyCode,
    );
  }

  static ReportExport toExport(ReportExportDto dto) {
    return ReportExport(
      jobId: dto.jobId,
      reportType: dto.reportType,
      format: dto.format,
      status: dto.status,
      requestedAt: dto.requestedAt,
      completedAt: dto.completedAt,
      fileName: dto.fileName,
      downloadUrl: dto.downloadUrl,
      expiresAt: dto.expiresAt,
      errorMessage: dto.errorMessage,
    );
  }

  static ReportMetric _toMetric(ReportMetricDto dto) {
    return ReportMetric(
      key: dto.key,
      label: dto.label,
      rawValue: dto.rawValue,
      formattedValue: dto.formattedValue,
      currencyCode: dto.currencyCode,
      comparisonValue: dto.comparisonValue,
      percentageChange: dto.percentageChange,
      comparisonLabel: dto.comparisonLabel,
      trendDirection: switch (dto.trendDirection?.toLowerCase()) {
        'up' => ReportTrendDirection.up,
        'down' => ReportTrendDirection.down,
        'flat' => ReportTrendDirection.flat,
        _ => ReportTrendDirection.unknown,
      },
      requiredPermission: dto.requiredPermission,
      isSensitive: dto.isSensitive,
    );
  }
}
