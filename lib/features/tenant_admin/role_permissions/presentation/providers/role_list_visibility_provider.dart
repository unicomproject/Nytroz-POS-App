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
    required this.showUpdateStatus,
  });

  final bool showPage;
  final bool showCreateCustomRole;
  final bool showConfigureRole;
  final bool showEditRole;
  final bool showDeleteRole;
  final bool showUpdateStatus;
}

final roleListVisibilityProvider =
    Provider.autoDispose<AsyncValue<RoleListVisibility>>((ref) {
  final access = ref.watch(tenantAdminAccessCheckerProvider);

  return access.when(
    data: (checker) => AsyncValue.data(
      RoleListVisibility(
        showPage: checker.canShowActionWithAnyPermission(
          TenantAdminFeatureCodes.rolePermission,
          [
            TenantAdminPermissionCodes.tenantRolesPermissionsView,
            TenantAdminPermissionCodes.tenantRolesAssignmentsView,
            TenantAdminPermissionCodes.tenantRolesView,
            TenantAdminPermissionCodes.tenantPermissionsView,
            TenantAdminPermissionCodes.tenantRolesManage,
          ],
        ),
        showCreateCustomRole: checker.canShowActionWithAnyPermission(
          TenantAdminFeatureCodes.rolePermission,
          [
            TenantAdminPermissionCodes.tenantRolesCreate,
            TenantAdminPermissionCodes.tenantRolesManage,
          ],
        ),
        showConfigureRole: checker.canShowAction(
              TenantAdminFeatureCodes.rolePermission,
              TenantAdminPermissionCodes.tenantRolesManage,
            ) ||
            (checker.canShowAction(
                  TenantAdminFeatureCodes.rolePermission,
                  TenantAdminPermissionCodes.tenantRolesUpdate,
                ) &&
                checker.can(
                  TenantAdminPermissionCodes.tenantRolesPermissionsUpdate,
                ) &&
                checker.can(
                  TenantAdminPermissionCodes.tenantRolesUsersAssign,
                ) &&
                checker.can(
                  TenantAdminPermissionCodes.tenantRolesOutletsAssign,
                )),
        showEditRole: checker.canShowActionWithAnyPermission(
          TenantAdminFeatureCodes.rolePermission,
          [
            TenantAdminPermissionCodes.tenantRolesUpdate,
            TenantAdminPermissionCodes.tenantRolesPermissionsUpdate,
            TenantAdminPermissionCodes.tenantRolesUsersAssign,
            TenantAdminPermissionCodes.tenantRolesOutletsAssign,
            TenantAdminPermissionCodes.tenantRolesManage,
          ],
        ),
        showDeleteRole: checker.canShowActionWithAnyPermission(
          TenantAdminFeatureCodes.rolePermission,
          [
            TenantAdminPermissionCodes.tenantRolesDelete,
            TenantAdminPermissionCodes.tenantRolesManage,
          ],
        ),
        showUpdateStatus: checker.canShowActionWithAnyPermission(
          TenantAdminFeatureCodes.rolePermission,
          [
            TenantAdminPermissionCodes.tenantRolesStatusUpdate,
            TenantAdminPermissionCodes.tenantRolesManage,
          ],
        ),
      ),
    ),
    loading: () => const AsyncValue.loading(),
    error: (e, st) => AsyncValue.error(e, st),
  );
});
