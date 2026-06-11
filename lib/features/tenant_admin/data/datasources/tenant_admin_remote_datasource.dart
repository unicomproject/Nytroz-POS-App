import 'package:dio/dio.dart';

import '../models/tenant_admin_context_dto.dart';
import '../models/tenant_admin_menu_item_dto.dart';

class TenantAdminRemoteDatasource {
  const TenantAdminRemoteDatasource(this._dio);

  final Dio _dio;

  Future<TenantAdminContextDto> getContext() async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/tenant-admin/context',
    );

    return TenantAdminContextDto.fromJson(response.data ?? const {});
  }

  Future<List<TenantAdminMenuItemDto>> getMenu() async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/tenant-admin/menu',
    );
    final data = response.data ?? const {};
    final items = data['items'];

    if (items is! List) {
      return const [];
    }

    return items
        .whereType<Map>()
        .map((item) => TenantAdminMenuItemDto.fromJson(
              Map<String, dynamic>.from(item),
            ))
        .toList(growable: false);
  }
}
