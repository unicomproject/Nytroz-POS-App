import 'package:dio/dio.dart';

import '../models/permission_catalog_dto.dart';
import '../models/role_permissions_dto.dart';
import '../models/update_role_permissions_request_dto.dart';

class RolePermissionRemoteDatasource {
  const RolePermissionRemoteDatasource(this._dio);

  final Dio _dio;

  static const _catalogPath = '/api/v1/tenant-admin/permission-catalog';
  static const _rolesPath = '/api/v1/tenant-admin/roles';

  Future<PermissionCatalogDto> getPermissionCatalog() async {
    final response = await _dio.get<dynamic>(_catalogPath);
    final payload = _unwrapApiPayload(response.data, response.requestOptions);
    return PermissionCatalogDto.fromJson(payload);
  }

  Future<RolePermissionsDto> getRolePermissions(String roleId) async {
    final response = await _dio.get<dynamic>('$_rolesPath/$roleId/permissions');
    final payload = _unwrapApiPayload(response.data, response.requestOptions);
    return RolePermissionsDto.fromJson(payload);
  }

  Future<RolePermissionsDto> updateRolePermissions(
    String roleId,
    UpdateRolePermissionsRequestDto request,
  ) async {
    final response = await _dio.put<dynamic>(
      '$_rolesPath/$roleId/permissions',
      data: request.toJson(),
    );
    final payload = _unwrapApiPayload(response.data, response.requestOptions);
    return RolePermissionsDto.fromJson(payload);
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
