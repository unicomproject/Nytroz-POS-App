import 'package:dio/dio.dart';

import '../constants/inventory_api_paths.dart';
import '../models/inventory_dashboard_models.dart';
import '../models/current_stock_dtos.dart';

class InventoryRemoteDatasource {
  const InventoryRemoteDatasource(this._dio);

  final Dio _dio;

  Future<InventoryDashboardMetricsDto> getDashboardMetrics(
      {String? outletId}) async {
    final response = await _dio.get<dynamic>(
      InventoryApiPaths.dashboard,
      queryParameters: _queryParameters(outletId: outletId),
    );

    return InventoryDashboardMetricsDto.fromJson(
      _unwrapApiPayload(response.data, response.requestOptions),
    );
  }

  Future<InventoryDashboardAlertsResponseDto> getDashboardAlerts({
    String? outletId,
    int page = 1,
    int pageSize = 5,
  }) async {
    final response = await _dio.get<dynamic>(
      InventoryApiPaths.dashboardAlerts,
      queryParameters: _queryParameters(
        outletId: outletId,
        page: page,
        pageSize: pageSize,
      ),
    );

    return InventoryDashboardAlertsResponseDto.fromJson(
      _unwrapApiPayload(response.data, response.requestOptions),
    );
  }

  Future<InventoryDashboardActivitiesResponseDto> getDashboardActivities({
    String? outletId,
    int page = 1,
    int pageSize = 5,
  }) async {
    final response = await _dio.get<dynamic>(
      InventoryApiPaths.dashboardActivities,
      queryParameters: _queryParameters(
        outletId: outletId,
        page: page,
        pageSize: pageSize,
      ),
    );

    return InventoryDashboardActivitiesResponseDto.fromJson(
      _unwrapApiPayload(response.data, response.requestOptions),
    );
  }

  Future<CurrentStockSummaryDto> getCurrentStockSummary(
      {String? outletId}) async {
    final response = await _dio.get<dynamic>(
      InventoryApiPaths.currentStockSummary,
      queryParameters: _queryParameters(outletId: outletId),
    );

    return CurrentStockSummaryDto.fromJson(
      _unwrapApiPayload(response.data, response.requestOptions),
    );
  }

  Future<CurrentStockPageDto> getCurrentStock(
      CurrentStockQueryDto query) async {
    final response = await _dio.get<dynamic>(
      InventoryApiPaths.currentStock,
      queryParameters: query.toQueryParameters(),
    );

    return CurrentStockPageDto.fromJson(
      _unwrapApiPayload(response.data, response.requestOptions),
    );
  }

  Future<ProductStockDetailDto> getProductStockDetail(String variantId,
      {String? outletId}) async {
    final response = await _dio.get<dynamic>(
      '${InventoryApiPaths.currentStock}/$variantId/detail',
      queryParameters: _queryParameters(outletId: outletId),
    );

    return ProductStockDetailDto.fromJson(
      _unwrapApiPayload(response.data, response.requestOptions),
    );
  }

  Future<StockMovementHistoryPageDto> getStockMovementHistory(
      String variantId, StockMovementHistoryQueryDto query) async {
    final response = await _dio.get<dynamic>(
      '${InventoryApiPaths.currentStock}/$variantId/movements',
      queryParameters: query.toQueryParameters(),
    );

    return StockMovementHistoryPageDto.fromJson(
      _unwrapApiPayload(response.data, response.requestOptions),
    );
  }

  Future<void> createOpeningStock(Map<String, dynamic> data) async {
    await _dio.post<dynamic>(
      '/tenant-admin/inventory/opening-stock',
      data: data,
    );
  }

  Map<String, dynamic> _queryParameters({
    String? outletId,
    int? page,
    int? pageSize,
  }) {
    return {
      if (outletId != null && outletId.trim().isNotEmpty)
        'outletId': outletId.trim(),
      if (page != null) 'page': page,
      if (pageSize != null) 'pageSize': pageSize,
    };
  }

  Map<String, dynamic> _unwrapApiPayload(
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

    if (root['data'] is Map) {
      return Map<String, dynamic>.from(root['data'] as Map);
    }

    return root;
  }
}
