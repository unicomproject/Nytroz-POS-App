import 'package:dio/dio.dart';

import '../../domain/entities/product_dashboard.dart';
import '../models/product_dashboard_dto.dart';

class ProductDashboardRemoteDatasource {
  const ProductDashboardRemoteDatasource(this._dio);

  final Dio _dio;

  static const _dashboardPath = '/api/v1/tenant-admin/products/dashboard';

  Future<ProductDashboardDto> getDashboard(ProductDashboardQuery query) async {
    final response = await _dio.get<dynamic>(
      _dashboardPath,
      queryParameters: _queryParameters(query),
    );

    return ProductDashboardDto.fromJson(
      _unwrapApiPayload(response.data, response.requestOptions),
    );
  }

  Map<String, dynamic> _queryParameters(ProductDashboardQuery query) {
    return {
      if (query.outletId != null && query.outletId!.trim().isNotEmpty)
        'outletId': query.outletId!.trim(),
      'dateFrom': _formatDateOnly(query.dateFrom),
      'dateTo': _formatDateOnly(query.dateTo),
    };
  }

  String _formatDateOnly(DateTime value) {
    final year = value.year.toString().padLeft(4, '0');
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
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
