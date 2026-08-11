import 'package:dio/dio.dart';

import '../../../../../core/network/api_endpoints.dart';
import '../../domain/entities/tenant_login_branding_settings.dart';
import '../models/tenant_login_branding_settings_dto.dart';

class TenantLoginBrandingRemoteDatasource {
  const TenantLoginBrandingRemoteDatasource(this._dio);

  final Dio _dio;

  Future<TenantLoginBrandingSettings> get() async {
    final response = await _dio.get<dynamic>(
      ApiEndpoints.tenantAdminPosLoginBranding,
    );
    return TenantLoginBrandingSettingsDto(_payload(response)).toDomain();
  }

  Future<TenantLoginBrandingSettings> update(
    UpdateTenantLoginBrandingSettings request,
  ) async {
    final response = await _dio.put<dynamic>(
      ApiEndpoints.tenantAdminPosLoginBranding,
      data: request.toJson(),
    );
    return TenantLoginBrandingSettingsDto(_payload(response)).toDomain();
  }

  Future<TenantLoginBrandingMediaUpload> uploadMedia(
    String purpose,
    TenantLoginBrandingMediaInput input,
  ) async {
    final response = await _dio.post<dynamic>(
      ApiEndpoints.tenantAdminPosLoginBrandingMedia(purpose),
      data: FormData.fromMap({
        'file': MultipartFile.fromBytes(
          input.bytes,
          filename: input.fileName,
          contentType: DioMediaType.parse(input.mimeType),
        ),
      }),
    );
    final json = _payload(response);
    return TenantLoginBrandingMediaUpload(
      mediaAssetId: json['mediaAssetId']?.toString() ?? '',
      purpose: json['purpose']?.toString() ?? purpose,
      publicUrl: json['publicUrl']?.toString(),
    );
  }

  Map<String, dynamic> _payload(Response<dynamic> response) {
    if (response.data is! Map) {
      throw const FormatException('Invalid POS login branding response.');
    }
    final root = Map<String, dynamic>.from(response.data as Map);
    if (root['success'] == false) {
      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        type: DioExceptionType.badResponse,
        message: root['message']?.toString(),
      );
    }
    return root['data'] is Map
        ? Map<String, dynamic>.from(root['data'] as Map)
        : root;
  }
}
