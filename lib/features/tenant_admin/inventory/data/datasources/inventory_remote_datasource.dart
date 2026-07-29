import 'package:dio/dio.dart';

import '../constants/inventory_api_paths.dart';
import '../models/inventory_dto.dart';

class InventoryRemoteDatasource {
  const InventoryRemoteDatasource(this._dio);

  final Dio _dio;

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

  Future<CurrentStockSummaryDto> getCurrentStockSummary({
    String? outletId,
  }) async {
    final response = await _dio.get<dynamic>(
      InventoryApiPaths.currentStockSummary,
      queryParameters: {
        if (outletId != null && outletId.trim().isNotEmpty)
          'outletId': outletId.trim(),
      },
    );

    return CurrentStockSummaryDto.fromJson(
      _unwrapApiPayload(response.data, response.requestOptions),
    );
  }

  Future<StockInResponseDto> receiveStock(
      CreateStockInRequestDto request) async {
    final response = await _dio.post<dynamic>(
      InventoryApiPaths.stockIn,
      data: request.toJson(),
    );

    return StockInResponseDto.fromJson(
      _unwrapApiPayload(response.data, response.requestOptions),
    );
  }

  Future<VariantLookupDto> getProductVariants(String productId) async {
    final response = await _dio.get<dynamic>(
      InventoryApiPaths.productVariants(productId),
    );

    return VariantLookupDto.fromJson(
      _unwrapApiPayload(response.data, response.requestOptions),
    );
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
