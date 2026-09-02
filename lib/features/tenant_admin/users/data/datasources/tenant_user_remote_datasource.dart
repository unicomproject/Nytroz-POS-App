import 'package:dio/dio.dart';

import '../../domain/entities/tenant_user.dart';
import '../models/tenant_user_dto.dart';
import '../models/user_write_request_dto.dart';
import '../models/user_profile_image_upload_dto.dart';
import '../../domain/entities/user_profile_image_upload.dart';

class TenantUserRemoteDatasource {
  const TenantUserRemoteDatasource(this._dio);

  final Dio _dio;

  static const _usersPath = '/api/v1/tenant-admin/users';
  static const _createOptionsPath = '/api/v1/tenant-admin/users/create-options';

  Future<TenantUserListResultDto> getUsers(TenantUserListQuery query) async {
    final response = await _dio.get<dynamic>(
      _usersPath,
      queryParameters: _listQueryParameters(query),
    );

    return TenantUserListResultDto.fromJson(
      _unwrapApiPayload(response.data, response.requestOptions),
    );
  }

  Future<TenantUserCreateOptionsDto> getCreateOptions() async {
    final response = await _dio.get<dynamic>(_createOptionsPath);
    return TenantUserCreateOptionsDto.fromJson(
      _unwrapApiPayload(response.data, response.requestOptions),
    );
  }

  Future<TenantUserDetailDto> createUser(
    UserWriteRequestDto request, {
    String? idempotencyKey,
  }) async {
    final response = await _dio.post<dynamic>(
      _usersPath,
      data: request.toJson(),
      options: idempotencyKey == null || idempotencyKey.trim().isEmpty
          ? null
          : Options(headers: {'Idempotency-Key': idempotencyKey.trim()}),
    );

    return TenantUserDetailDto.fromJson(
      _unwrapApiPayload(response.data, response.requestOptions),
    );
  }

  Future<TenantUserDetailDto> getUserById(String id) async {
    final response = await _dio.get<dynamic>('$_usersPath/$id');
    return TenantUserDetailDto.fromJson(
      _unwrapApiPayload(response.data, response.requestOptions),
    );
  }

  Future<TenantUserDetailDto> updateUser(
    String id,
    UserWriteRequestDto request,
  ) async {
    final response = await _dio.put<dynamic>(
      '$_usersPath/$id',
      data: request.toJson(),
    );

    return TenantUserDetailDto.fromJson(
      _unwrapApiPayload(response.data, response.requestOptions),
    );
  }

  Future<void> deleteUser(String id) async {
    await _dio.delete<dynamic>('$_usersPath/$id');
  }

  Future<UserProfileImageUploadDto> uploadProfileImage(
    UserProfileImageUploadInput input, {
    void Function(int sent, int total)? onProgress,
  }) async {
    final response = await _dio.post<dynamic>(
      '$_usersPath/profile-image-uploads',
      data: FormData.fromMap({
        'file': MultipartFile.fromBytes(
          input.bytes,
          filename: input.fileName,
          contentType: DioMediaType.parse(input.mimeType),
        ),
      }),
      onSendProgress: onProgress,
    );
    return UserProfileImageUploadDto.fromJson(
      _unwrapApiPayload(response.data, response.requestOptions),
    );
  }

  Future<void> deleteStagedProfileImage(String mediaAssetId) =>
      _dio.delete<void>('$_usersPath/profile-image-uploads/$mediaAssetId');

  Map<String, dynamic> _listQueryParameters(TenantUserListQuery query) {
    return {
      'page': query.page,
      'pageSize': query.pageSize,
      'sortBy': query.sortBy,
      'sortDirection': query.sortDirection,
      if (query.search != null && query.search!.trim().isNotEmpty)
        'search': query.search!.trim(),
      if (query.status != null && query.status!.trim().isNotEmpty)
        'status': query.status!.trim(),
      if (query.roleId != null && query.roleId!.trim().isNotEmpty)
        'roleId': query.roleId!.trim(),
      if (query.outletId != null && query.outletId!.trim().isNotEmpty)
        'outletId': query.outletId!.trim(),
    };
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
