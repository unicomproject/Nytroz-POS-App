import 'package:dio/dio.dart';

import '../models/inventory_dto.dart';

class InventoryRemoteDatasource {
  const InventoryRemoteDatasource(this._dio);

  final Dio _dio;

  static const _locationsPath = '/api/v1/inventory/locations';
  static const _balancesPath = '/api/v1/inventory/balances';
  static const _stockMovementsPath = '/api/v1/inventory/stock-movements';

  Future<List<InventoryLocationDto>> getLocations() async {
    final response = await _dio.get<dynamic>(_locationsPath);
    return _parseLocationList(response.data, response.requestOptions);
  }

  Future<InventoryBalanceListResultDto> getBalances({
    String? locationId,
    String? search,
    int page = 1,
    int pageSize = 10,
    bool lowStockOnly = false,
  }) async {
    final response = await _dio.get<dynamic>(
      _balancesPath,
      queryParameters: {
        'page': page,
        'pageSize': pageSize,
        if (locationId != null && locationId.isNotEmpty)
          'locationId': locationId,
        if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
        if (lowStockOnly) 'lowStockOnly': true,
      },
    );

    return _parseBalanceList(response.data, response.requestOptions);
  }

  Future<void> submitStockIn(StockInRequestDto request) async {
    final response = await _dio.post<dynamic>(
      _stockMovementsPath,
      data: request.toJson(),
    );

    if (response.data is Map && (response.data as Map)['success'] == false) {
      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        type: DioExceptionType.badResponse,
        message: (response.data as Map)['message']?.toString(),
      );
    }
  }

  List<InventoryLocationDto> _parseLocationList(
    dynamic data,
    RequestOptions requestOptions,
  ) {
    _ensureSuccess(data, requestOptions);

    if (data is Map) {
      final payload = data['data'] ?? data['items'] ?? data;
      if (payload is List) {
        return payload
            .whereType<Map>()
            .map(
              (item) => InventoryLocationDto.fromJson(
                Map<String, dynamic>.from(item),
              ),
            )
            .toList(growable: false);
      }
    }

    if (data is List) {
      return data
          .whereType<Map>()
          .map(
            (item) => InventoryLocationDto.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .toList(growable: false);
    }

    return const [];
  }

  InventoryBalanceListResultDto _parseBalanceList(
    dynamic data,
    RequestOptions requestOptions,
  ) {
    _ensureSuccess(data, requestOptions);

    if (data is Map) {
      final payload = data['data'] is Map
          ? Map<String, dynamic>.from(data['data'] as Map)
          : Map<String, dynamic>.from(data);

      return InventoryBalanceListResultDto.fromJson(payload);
    }

    return const InventoryBalanceListResultDto(
      summary: InventoryBalanceSummaryDto(),
      items: [],
    );
  }

  void _ensureSuccess(dynamic data, RequestOptions requestOptions) {
    if (data is Map && data['success'] == false) {
      throw DioException(
        requestOptions: requestOptions,
        type: DioExceptionType.badResponse,
        message: data['message']?.toString(),
      );
    }
  }
}
