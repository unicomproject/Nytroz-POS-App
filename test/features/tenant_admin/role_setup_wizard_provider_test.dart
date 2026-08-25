import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nytroz_pos/features/tenant_admin/role_permissions/domain/entities/permission_catalog.dart';
import 'package:nytroz_pos/features/tenant_admin/role_permissions/domain/entities/role_assignment.dart';
import 'package:nytroz_pos/features/tenant_admin/role_permissions/domain/entities/role_permissions.dart';
import 'package:nytroz_pos/features/tenant_admin/role_permissions/domain/entities/role_setup.dart';
import 'package:nytroz_pos/features/tenant_admin/role_permissions/domain/repositories/role_permission_repository.dart';
import 'package:nytroz_pos/features/tenant_admin/role_permissions/presentation/providers/role_permissions_providers.dart';
import 'package:nytroz_pos/features/tenant_admin/role_permissions/presentation/providers/role_setup_wizard_provider.dart';

void main() {
  test('keeps only canonical roles and saves each user scope atomically',
      () async {
    final repository = _FakeRolePermissionRepository();
    final container = ProviderContainer(
      overrides: [
        rolePermissionRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);

    final controller = container.read(roleSetupWizardProvider.notifier);
    await controller.load();

    expect(
      container
          .read(roleSetupWizardProvider)
          .availableRoles
          .map((role) => role.code),
      ['TENANT_ADMIN', 'CASHIER'],
    );

    final role = container
        .read(roleSetupWizardProvider)
        .availableRoles
        .firstWhere((item) => item.code == 'CASHIER');
    await controller.selectRole(role);
    controller.toggleUser(
      'user-1',
      fullName: 'Cashier One',
      email: 'cashier@example.com',
    );
    controller.setAssignmentScope(RoleAccessScopeType.selectedOutlets);
    controller.toggleAssignmentOutlet('outlet-1');

    expect(
        container.read(roleSetupWizardProvider).hasInvalidAssignment, isFalse);
    expect(await controller.saveRoleAccess(), isTrue);

    expect(repository.savedRequest?.permissionCodes, ['pos.sale.view']);
    expect(repository.savedRequest?.assignments, hasLength(1));
    expect(
      repository.savedRequest?.assignments.single.scopeType,
      RoleAccessScopeType.selectedOutlets,
    );
    expect(repository.savedRequest?.assignments.single.outletIds, ['outlet-1']);
  });
}

class _FakeRolePermissionRepository implements RolePermissionRepository {
  SaveRoleSetupRequest? savedRequest;

  @override
  Future<PermissionCatalog> getPermissionCatalog() async =>
      const PermissionCatalog(
        modules: [
          PermissionCatalogModule(
            id: 'pos',
            code: 'pos',
            name: 'Point of Sale',
            scope: 'TENANT',
            sortOrder: 1,
            isActive: true,
            features: [
              PermissionCatalogFeature(
                id: 'sales',
                code: 'sales',
                name: 'Sales',
                sortOrder: 1,
                isActive: true,
                permissions: [
                  PermissionCatalogPermission(
                    id: 'pos-sale-view',
                    code: 'pos.sale.view',
                    name: 'View sales',
                    scope: 'TENANT',
                    sortOrder: 1,
                    isActive: true,
                    source: 'tenant',
                  ),
                ],
              ),
            ],
          ),
        ],
      );

  @override
  Future<List<RoleSetupOption>> getSetupOptions() async => const [
        RoleSetupOption(
          id: 'tenant-admin',
          code: 'TENANT_ADMIN',
          name: 'Tenant Admin',
          isActive: true,
          isSystem: true,
          permissionCount: 1,
          userCount: 1,
          updatedAt: null,
        ),
        RoleSetupOption(
          id: 'cashier',
          code: 'CASHIER',
          name: 'Cashier',
          isActive: true,
          isSystem: true,
          permissionCount: 1,
          userCount: 0,
          updatedAt: null,
        ),
        RoleSetupOption(
          id: 'super-admin',
          code: 'SUPER_ADMIN',
          name: 'Super Admin',
          isActive: true,
          isSystem: true,
          permissionCount: 1,
          userCount: 0,
          updatedAt: null,
        ),
      ];

  @override
  Future<RolePermissions> getRolePermissions(String roleId) async =>
      RolePermissions(
        roleId: roleId,
        roleCode: 'CASHIER',
        roleName: 'Cashier',
        roleScope: 'TENANT',
        isSystem: true,
        assignedPermissionCodes: const ['pos.sale.view'],
        assignedPermissionIds: const ['pos-sale-view'],
        updatedAt: DateTime.utc(2026, 8, 21),
      );

  @override
  Future<List<RoleAssignment>> getRoleAssignments(String roleId) async =>
      const [];

  @override
  Future<SaveRoleSetupResult> saveRoleSetup(
    String roleId,
    SaveRoleSetupRequest request,
  ) async {
    savedRequest = request;
    return SaveRoleSetupResult(
      roleId: roleId,
      updatedAt: DateTime.utc(2026, 8, 21, 12),
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
