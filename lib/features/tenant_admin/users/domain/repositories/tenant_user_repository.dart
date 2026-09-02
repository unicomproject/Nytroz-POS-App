import '../entities/tenant_user.dart';
import '../entities/user_profile_image_upload.dart';

abstract class TenantUserRepository {
  Future<TenantUserListResult> getUsers({required TenantUserListQuery query});

  Future<TenantUserCreateOptions> getCreateOptions();

  Future<TenantUserDetail> createUser(
    UserFormData form, {
    String? idempotencyKey,
  });

  Future<TenantUserDetail> getUserById(String id);

  Future<TenantUserDetail> updateUser(String id, UserFormData form);

  Future<void> deleteUser(String id);

  Future<UserProfileImageUpload> uploadProfileImage(
    UserProfileImageUploadInput input, {
    void Function(int sent, int total)? onProgress,
  });

  Future<void> deleteStagedProfileImage(String mediaAssetId);
}
