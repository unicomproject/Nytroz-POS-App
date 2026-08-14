import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../../../core/network/api_endpoints.dart';
import '../models/pos_login_branding_dto.dart';

class PosLoginBrandingRemoteDatasource {
  const PosLoginBrandingRemoteDatasource(this._dio);
  final Dio _dio;

  Future<({PosLoginBrandingDto? dto, String? etag})> get(
    String tenantSlug, {
    String? etag,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      ApiEndpoints.publicPosLoginBranding(tenantSlug),
      options: Options(
        headers: {
          'Authorization': null,
          if (etag != null) 'If-None-Match': etag,
        },
        validateStatus: (status) => status == 200 || status == 304,
      ),
    );
    if (response.statusCode == 304) return (dto: null, etag: etag);
    return (
      dto: PosLoginBrandingDto(
        response.data ?? const {},
        apiBaseUrl: _dio.options.baseUrl,
        replaceLoopbackHost: defaultTargetPlatform == TargetPlatform.android,
      ),
      etag: response.headers.value('etag'),
    );
  }
}
