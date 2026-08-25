import 'package:dio/dio.dart';

import '../models/create_role_request_dto.dart';
import '../models/permission_catalog_dto.dart';
import '../models/role_assignments_dto.dart';
import '../models/role_list_dto.dart';
import '../models/role_permissions_dto.dart';
import '../models/role_setup_dto.dart';
import '../models/update_role_assignments_request_dto.dart';
import '../models/update_role_permissions_request_dto.dart';
import '../models/update_role_request_dto.dart';
import '../models/update_role_status_request_dto.dart';

class RolePermissionRemoteDatasource {
  const RolePermissionRemoteDatasource(this._dio);

  final Dio _dio;

  static const _catalogPath = '/api/v1/tenant-admin/permission-catalog';
  static const _rolesPath = '/api/v1/tenant-admin/roles';

  Future<RoleSetupOptionsDto> getSetupOptions() async {
    final response = await _dio.get<dynamic>('$_rolesPath/setup-options');
    final payload = _unwrapApiPayload(response.data, response.requestOptions);
    return RoleSetupOptionsDto.fromJson(payload);
  }

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

  Future<Map<String, dynamic>> createRole(CreateRoleRequestDto request) async {
    final idempotencyKey =
        '${DateTime.now().millisecondsSinceEpoch}-${request.hashCode}';
    final response = await _dio.post<dynamic>(
      _rolesPath,
      data: request.toJson(),
      options: Options(headers: {'Idempotency-Key': idempotencyKey}),
    );
    return _unwrapApiPayload(response.data, response.requestOptions);
  }

  Future<RoleListResponseDto> getRoles(
      int page, int pageSize, String? search, String? status) async {
    final response = await _dio.get<dynamic>(
      _rolesPath,
      queryParameters: {
        'page': page,
        'pageSize': pageSize,
        if (search != null && search.isNotEmpty) 'search': search,
        if (status != null && status.isNotEmpty) 'status': status,
      },
    );
    return RoleListResponseDto.fromJson(
        _unwrapApiPayload(response.data, response.requestOptions));
  }

  Future<Map<String, dynamic>> getRoleById(String roleId) async {
    final response = await _dio.get<dynamic>('$_rolesPath/$roleId');
    return _unwrapApiPayload(response.data, response.requestOptions);
  }

  Future<Map<String, dynamic>> updateRole(
      String roleId, UpdateRoleRequestDto request) async {
    final response = await _dio.put<dynamic>(
      '$_rolesPath/$roleId',
      data: request.toJson(),
    );
    return _unwrapApiPayload(response.data, response.requestOptions);
  }

  Future<Map<String, dynamic>> updateRoleStatus(
      String roleId, UpdateRoleStatusRequestDto request) async {
    final response = await _dio.patch<dynamic>(
      '$_rolesPath/$roleId/status',
      data: request.toJson(),
    );
    return _unwrapApiPayload(response.data, response.requestOptions);
  }

  Future<void> deleteRole(String roleId, DateTime? expectedUpdatedAt) async {
    await _dio.delete<dynamic>(
      '$_rolesPath/$roleId',
      queryParameters: {
        if (expectedUpdatedAt != null)
          'expectedUpdatedAt': expectedUpdatedAt.toIso8601String(),
      },
    );
  }

  Future<RoleAssignmentsDto> getRoleAssignments(String roleId) async {
    final response = await _dio.get<dynamic>('$_rolesPath/$roleId/assignments');
    final payload = _unwrapApiPayload(response.data, response.requestOptions);
    return RoleAssignmentsDto.fromJson(payload);
  }

  Future<RoleAssignmentsDto> updateRoleAssignments(
    String roleId,
    UpdateRoleAssignmentsRequestDto request,
  ) async {
    final response = await _dio.put<dynamic>(
      '$_rolesPath/$roleId/assignments',
      data: request.toJson(),
    );
    final payload = _unwrapApiPayload(response.data, response.requestOptions);
    return RoleAssignmentsDto.fromJson(payload);
  }

  Future<Map<String, dynamic>> saveRoleSetup(
    String roleId,
    SaveRoleSetupRequestDto request,
  ) async {
    final response = await _dio.put<dynamic>(
      '$_rolesPath/$roleId/setup',
      data: request.toJson(),
    );
    return _unwrapApiPayload(response.data, response.requestOptions);
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
