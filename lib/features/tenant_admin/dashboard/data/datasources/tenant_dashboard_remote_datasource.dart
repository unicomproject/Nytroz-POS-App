import 'package:dio/dio.dart';

import '../catalog/tenant_admin_dashboard_catalog.dart';
import '../models/tenant_dashboard_dto.dart';
import '../models/tenant_dashboard_summary_dto.dart';

class TenantDashboardRemoteDatasource {
  const TenantDashboardRemoteDatasource(this._dio);

  final Dio _dio;

  static const _summaryPaths = [
    '/api/v1/tenant-admin/dashboard/summary',
  ];

  static const _legacyDashboardPaths = [
    '/api/v1/tenant-admin/dashboard',
    '/api/tenant-admin/dashboard',
  ];

  Future<TenantDashboardDto> getDashboard() async {
    DioException? lastError;

    for (final path in _summaryPaths) {
      try {
        final response = await _dio.get<Map<String, dynamic>>(path);
        final data = response.data ?? const {};

        if (data['success'] == false) {
          throw DioException(
            requestOptions: response.requestOptions,
            response: response,
            type: DioExceptionType.badResponse,
            message: data['message']?.toString(),
          );
        }

        final summary = TenantDashboardSummaryDto.fromJson(data);
        final dashboard = summary.toDashboardDto();
        final catalog = tenantAdminDashboardCatalogFallback;

        return TenantDashboardDto(
          metrics: dashboard.metrics,
          salesThisWeek: catalog.salesThisWeek,
          needsAttention: dashboard.needsAttention.isNotEmpty
              ? dashboard.needsAttention
              : catalog.needsAttention,
          quickActions: catalog.quickActions,
          recentActivity: catalog.recentActivity,
          notificationCount: catalog.notificationCount,
        );
      } on DioException catch (error) {
        lastError = error;
        if (error.response?.statusCode == 404) {
          continue;
        }

        rethrow;
      }
    }

    for (final path in _legacyDashboardPaths) {
      try {
        final response = await _dio.get<Map<String, dynamic>>(path);
        final data = response.data ?? const {};

        if (data['success'] == false) {
          throw DioException(
            requestOptions: response.requestOptions,
            response: response,
            type: DioExceptionType.badResponse,
            message: data['message']?.toString(),
          );
        }

        final payload = data['data'] is Map<String, dynamic>
            ? Map<String, dynamic>.from(data['data'] as Map)
            : data;

        return TenantDashboardDto.fromJson(payload);
      } on DioException catch (error) {
        lastError = error;
        if (error.response?.statusCode == 404) {
          continue;
        }

        rethrow;
      }
    }

    if (lastError != null) {
      throw lastError;
    }

    return tenantAdminDashboardCatalogFallback;
  }
}
