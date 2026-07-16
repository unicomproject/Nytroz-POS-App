import 'package:dio/dio.dart';

import '../../domain/entities/report_models.dart';
import '../../domain/entities/report_query.dart';
import '../constants/report_api_paths.dart';
import '../models/report_export_dto.dart';
import '../models/report_filter_option_dto.dart';
import '../models/report_response_dto.dart';
import '../models/sales_transaction_detail_dto.dart';

class ReportRemoteDatasource {
  const ReportRemoteDatasource(this._dio);

  final Dio _dio;

  Future<ReportFilterOptionsDto> getFilterOptions(ReportQuery query) async {
    final response = await _dio.get<dynamic>(
      ReportApiPaths.filterOptions,
      queryParameters: query.toQueryParameters(),
    );
    return ReportFilterOptionsDto.fromJson(
      _unwrapMap(response.data, response.requestOptions),
    );
  }

  Future<ReportResultDto> getDashboard(ReportQuery query) =>
      _getResult(ReportApiPaths.dashboard, query);

  Future<ReportResultDto> getSales(ReportQuery query) =>
      _getResult(ReportApiPaths.sales, query);

  Future<ReportResultDto> getStock(ReportQuery query) =>
      _getResult(ReportApiPaths.stock, query);

  Future<ReportResultDto> getOutlets(ReportQuery query) =>
      _getResult(ReportApiPaths.outlets, query);

  Future<SalesTransactionDetailDto> getSalesDetail(String orderId) async {
    final response = await _dio.get<dynamic>(
      ReportApiPaths.salesDetail(orderId),
    );
    return SalesTransactionDetailDto.fromJson(
      _unwrapMap(response.data, response.requestOptions),
    );
  }

  Future<ReportExportDto> requestExport(ReportExportRequest request) async {
    final response = await _dio.post<dynamic>(
      ReportApiPaths.exports,
      data: {
        'reportType': request.reportType,
        'section': request.section,
        'format': request.format,
        ...request.query.toQueryParameters()
          ..remove('section')
          ..remove('page')
          ..remove('pageSize'),
      },
    );
    return ReportExportDto.fromJson(
      _unwrapMap(response.data, response.requestOptions),
    );
  }

  Future<ReportExportDto> getExportStatus(String jobId) async {
    final response = await _dio.get<dynamic>(
      ReportApiPaths.exportStatus(jobId),
    );
    return ReportExportDto.fromJson(
      _unwrapMap(response.data, response.requestOptions),
    );
  }

  Future<ReportResultDto> _getResult(String path, ReportQuery query) async {
    final response = await _dio.get<dynamic>(
      path,
      queryParameters: query.toQueryParameters(),
    );
    return ReportResultDto.fromJson(
      _unwrapMap(response.data, response.requestOptions),
    );
  }

  Map<String, dynamic> _unwrapMap(
    dynamic data,
    RequestOptions requestOptions,
  ) {
    if (data is! Map) {
      return const {};
    }

    final root = Map<String, dynamic>.from(data);
    if (root['success'] == false) {
      throw DioException(
        requestOptions: requestOptions,
        response: Response(
          requestOptions: requestOptions,
          data: root,
          statusCode: 400,
        ),
        type: DioExceptionType.badResponse,
        message: root['message']?.toString(),
      );
    }

    final payload = root['data'];
    if (payload is Map) {
      final mapped = Map<String, dynamic>.from(payload);
      for (final key in const [
        'page',
        'pageSize',
        'totalCount',
        'totalPages'
      ]) {
        if (!mapped.containsKey(key) && root.containsKey(key)) {
          mapped[key] = root[key];
        }
      }
      return mapped;
    }

    return root;
  }
}
