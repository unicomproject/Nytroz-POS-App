import 'package:dio/dio.dart';

import '../../../../core/network/media_url_resolver.dart';
import '../models/tenant_admin_context_dto.dart';

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

    final dto = TenantAdminContextDto.fromApiJson(data);
    return dto.copyWith(
      tenantLogoUrl: MediaUrlResolver.resolve(
        dto.tenantLogoUrl,
        apiBaseUrl: _dio.options.baseUrl,
        replaceLoopbackHost: true,
      ),
    );
  }
}
