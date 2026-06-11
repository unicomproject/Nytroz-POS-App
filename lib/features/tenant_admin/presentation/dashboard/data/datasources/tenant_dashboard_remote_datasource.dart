import 'package:dio/dio.dart';

import '../models/tenant_dashboard_dto.dart';

class TenantDashboardRemoteDatasource {
  const TenantDashboardRemoteDatasource(this._dio);

  final Dio _dio;

  Future<TenantDashboardDto> getDashboard() async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/tenant-admin/dashboard',
    );

    return TenantDashboardDto.fromJson(response.data ?? const {});
  }
}
