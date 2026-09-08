import '../../domain/entities/tenant_user.dart';
import '../../domain/repositories/tenant_user_repository.dart';
import '../datasources/tenant_user_remote_datasource.dart';
import '../mappers/tenant_user_mapper.dart';
import '../models/user_write_request_dto.dart';
import '../../domain/entities/user_profile_image_upload.dart';

class TenantUserRepositoryImpl implements TenantUserRepository {
  const TenantUserRepositoryImpl(this._remoteDatasource);

  final TenantUserRemoteDatasource _remoteDatasource;

  @override
  Future<TenantUserListResult> getUsers({
    required TenantUserListQuery query,
  }) async {
    final dto = await _remoteDatasource.getUsers(query);
    return TenantUserMapper.toListResult(dto);
  }

  @override
  Future<TenantUserCreateOptions> getCreateOptions() async {
    final dto = await _remoteDatasource.getCreateOptions();
    return TenantUserMapper.toCreateOptions(dto);
  }

  @override
  Future<TenantUserDetail> createUser(
    UserFormData form, {
    String? idempotencyKey,
  }) async {
    final dto = await _remoteDatasource.createUser(
      _toRequestDto(form),
      idempotencyKey: idempotencyKey,
    );
    return TenantUserMapper.toDetailEntity(dto);
  }

  @override
  Future<TenantUserDetail> getUserById(String id) async {
    final dto = await _remoteDatasource.getUserById(id);
    return TenantUserMapper.toDetailEntity(dto);
  }

  @override
  Future<TenantUserDetail> updateUser(String id, UserFormData form) async {
    final dto = await _remoteDatasource.updateUser(id, _toRequestDto(form));
    return TenantUserMapper.toDetailEntity(dto);
  }

  @override
  Future<void> deleteUser(String id) {
    return _remoteDatasource.deleteUser(id);
  }

  @override
  Future<UserProfileImageUpload> uploadProfileImage(
    UserProfileImageUploadInput input, {
    void Function(int sent, int total)? onProgress,
  }) async {
    final result = await _remoteDatasource.uploadProfileImage(
      input,
      onProgress: onProgress,
    );
    return result.toEntity();
  }

  @override
  Future<void> deleteStagedProfileImage(String mediaAssetId) =>
      _remoteDatasource.deleteStagedProfileImage(mediaAssetId);

  UserWriteRequestDto _toRequestDto(UserFormData form) {
    return UserWriteRequestDto(
      fullName: form.fullName,
      email: form.email,
      phoneNumber: form.phone,
      employeeId: form.employeeId,
      roleId: form.roleId,
      outletIds: form.outletIds,
      permissionOverrideEnabled: form.permissionOverrideEnabled,
      overriddenPermissionIds: form.overriddenPermissionIds,
      sendInviteEmail: form.status == null ? form.sendInviteEmail : null,
      status: form.status,
      profileMediaAssetId: form.profileMediaAssetId,
      profileMediaAction: form.profileMediaAction,
      outletAccessScope: form.outletAccessScope,
      defaultOutletId: form.defaultOutletId,
      tillAccessScope: form.tillAccessScope,
      tillIds: form.tillIds,
      defaultTillId: form.defaultTillId,
      permissionCatalogVersion: form.permissionCatalogVersion,
      deniedPermissionIds: form.deniedPermissionIds,
      password: form.password,
      confirmPassword: form.confirmPassword,
    );
  }
}
