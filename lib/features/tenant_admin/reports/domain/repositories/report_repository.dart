import '../entities/report_models.dart';
import '../entities/report_query.dart';

abstract class ReportRepository {
  Future<ReportFilterOptions> getFilterOptions(ReportQuery query);

  Future<ReportResult> getDashboard(ReportQuery query);

  Future<ReportResult> getSales(ReportQuery query);

  Future<SalesTransactionDetail> getSalesDetail(String orderId);

  Future<ReportResult> getStock(ReportQuery query);

  Future<ReportResult> getOutlets(ReportQuery query);

  Future<ReportExport> requestExport(ReportExportRequest request);

  Future<ReportExport> getExportStatus(String jobId);
}
