import '../entities/tenant_user.dart';

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
}
