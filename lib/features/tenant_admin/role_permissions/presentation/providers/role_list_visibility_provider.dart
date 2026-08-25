import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/access/tenant_admin_access_codes.dart';
import '../../../presentation/providers/tenant_admin_access_provider.dart';

class RoleListVisibility {
  const RoleListVisibility({
    required this.showPage,
    required this.showCreateCustomRole,
    required this.showConfigureRole,
    required this.showEditRole,
    required this.showDeleteRole,
  });

  final bool showPage;
  final bool showCreateCustomRole;
  final bool showConfigureRole;
  final bool showEditRole;
  final bool showDeleteRole;
}

final roleListVisibilityProvider = Provider.autoDispose<AsyncValue<RoleListVisibility>>((ref) {
  final access = ref.watch(tenantAdminAccessCheckerProvider);

  return access.when(
    data: (checker) => AsyncValue.data(
      RoleListVisibility(
        showPage: checker.canShowActionWithAnyPermission(
          TenantAdminFeatureCodes.rolePermission,
          [
            TenantAdminPermissionCodes.rolesPermissionsView,
            TenantAdminPermissionCodes.rolesView,
            TenantAdminPermissionCodes.permissionsView,
            TenantAdminPermissionCodes.tenantRoleManage,
          ],
        ),
        showCreateCustomRole: checker.canShowActionWithAnyPermission(
          TenantAdminFeatureCodes.rolePermission,
          [
            TenantAdminPermissionCodes.tenantRolesCreate,
            TenantAdminPermissionCodes.tenantRoleManage,
          ],
        ),
        showConfigureRole: checker.canShowActionWithAnyPermission(
          TenantAdminFeatureCodes.rolePermission,
          [
            TenantAdminPermissionCodes.rolesPermissionsUpdate,
            TenantAdminPermissionCodes.tenantRoleManage,
          ],
        ),
        showEditRole: checker.canShowActionWithAnyPermission(
          TenantAdminFeatureCodes.rolePermission,
          [
            TenantAdminPermissionCodes.rolesPermissionsUpdate,
            TenantAdminPermissionCodes.tenantRoleManage,
          ],
        ),
        showDeleteRole: checker.canShowActionWithAnyPermission(
          TenantAdminFeatureCodes.rolePermission,
          [
            TenantAdminPermissionCodes.rolesPermissionsUpdate,
            TenantAdminPermissionCodes.tenantRoleManage,
          ],
        ),
      ),
    ),
    loading: () => const AsyncValue.loading(),
    error: (e, st) => AsyncValue.error(e, st),
  );
});
