import 'package:dio/dio.dart';

import '../models/tenant_admin_context_dto.dart';
import '../models/tenant_admin_menu_item_dto.dart';

class TenantAdminRemoteDatasource {
  const TenantAdminRemoteDatasource(this._dio);

  final Dio _dio;

  Future<TenantAdminContextDto> getContext() async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/v1/tenant-admin/context',
    );
    final data = response.data ?? const {};

    if (data['success'] == false) {
      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        type: DioExceptionType.badResponse,
        message: data['message']?.toString(),
      );
    }

    return TenantAdminContextDto.fromApiJson(data);
  }

  Future<List<TenantAdminMenuItemDto>> getMenu() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/api/tenant-admin/menu',
      );
      final data = response.data ?? const {};
      final items = data['items'] ?? data;

      if (items is! List) {
        return const [];
      }

      return items
          .whereType<Map>()
          .map((item) => TenantAdminMenuItemDto.fromJson(
                Map<String, dynamic>.from(item),
              ))
          .toList(growable: false);
    } on DioException {
      return const [];
    }
  }
}
