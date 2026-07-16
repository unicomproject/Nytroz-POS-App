import '../../domain/entities/report_models.dart';
import '../../domain/entities/report_query.dart';
import '../../domain/repositories/report_repository.dart';
import '../datasources/report_remote_datasource.dart';
import '../mappers/report_mapper.dart';

class ReportRepositoryImpl implements ReportRepository {
  const ReportRepositoryImpl(this._remoteDatasource);

  final ReportRemoteDatasource _remoteDatasource;

  @override
  Future<ReportFilterOptions> getFilterOptions(ReportQuery query) async =>
      ReportMapper.toFilterOptions(
        await _remoteDatasource.getFilterOptions(query),
      );

  @override
  Future<ReportResult> getDashboard(ReportQuery query) async =>
      ReportMapper.toResult(await _remoteDatasource.getDashboard(query));

  @override
  Future<ReportResult> getSales(ReportQuery query) async =>
      ReportMapper.toResult(await _remoteDatasource.getSales(query));

  @override
  Future<SalesTransactionDetail> getSalesDetail(String orderId) async =>
      ReportMapper.toTransactionDetail(
        await _remoteDatasource.getSalesDetail(orderId),
      );

  @override
  Future<ReportResult> getStock(ReportQuery query) async =>
      ReportMapper.toResult(await _remoteDatasource.getStock(query));

  @override
  Future<ReportResult> getOutlets(ReportQuery query) async =>
      ReportMapper.toResult(await _remoteDatasource.getOutlets(query));

  @override
  Future<ReportExport> requestExport(ReportExportRequest request) async =>
      ReportMapper.toExport(await _remoteDatasource.requestExport(request));

  @override
  Future<ReportExport> getExportStatus(String jobId) async =>
      ReportMapper.toExport(await _remoteDatasource.getExportStatus(jobId));
}
