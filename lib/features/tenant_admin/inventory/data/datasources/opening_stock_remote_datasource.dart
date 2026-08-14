import 'package:dio/dio.dart';
import '../models/opening_stock_dto.dart';

class OpeningStockRemoteDatasource {
  const OpeningStockRemoteDatasource(this._dio);

  final Dio _dio;

  Future<OpeningStockResponseDto> addOpeningStock(
    OpeningStockRequestDto request,
  ) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/v1/tenant-admin/inventory/opening-stock',
      data: request.toJson(),
    );

    final data = response.data ?? const {};

    if (data['success'] == false) {
      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        type: DioExceptionType.badResponse,
        message:
            data['message']?.toString() ?? 'Failed to submit opening stock.',
      );
    }

    return OpeningStockResponseDto.fromJson(data);
  }
}
