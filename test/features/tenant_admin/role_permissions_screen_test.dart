import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nytroz_pos/core/access/tenant_admin_access_codes.dart';
import 'package:nytroz_pos/features/tenant_admin/domain/entities/tenant_admin_context.dart';
import 'package:nytroz_pos/features/tenant_admin/domain/services/tenant_admin_access_checker.dart';
import 'package:nytroz_pos/features/tenant_admin/presentation/providers/tenant_admin_access_provider.dart';
import 'package:nytroz_pos/features/tenant_admin/presentation/providers/tenant_admin_context_provider.dart';
import 'package:nytroz_pos/features/tenant_admin/role_permissions/domain/entities/permission_catalog.dart';
import 'package:nytroz_pos/features/tenant_admin/role_permissions/domain/entities/role_permissions.dart';
import 'package:nytroz_pos/features/tenant_admin/role_permissions/presentation/providers/role_permissions_providers.dart';
import 'package:nytroz_pos/features/tenant_admin/role_permissions/presentation/screens/role_permissions_screen.dart';

void main() {
  group('RolePermissionsScreen', () {
    testWidgets('renders permission catalog and checked assigned permissions',
        (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            tenantAdminContextProvider.overrideWith(
              (ref) async => _context(),
            ),
            tenantAdminAccessCheckerProvider.overrideWith(
              (ref) async => TenantAdminAccessChecker(_context()),
            ),
            rolePermissionsCanViewProvider.overrideWith((ref) => true),
            rolePermissionsCanUpdateProvider.overrideWith((ref) => false),
            rolePermissionsAvailableRolesProvider.overrideWith(
              (ref) => const [
                TenantAdminRoleOption(id: 'role-1', name: 'Tenant Admin'),
              ],
            ),
            rolePermissionsDataProvider('role-1').overrideWith(
              (ref) async => RolePermissionsData(
                catalog: _catalog(),
                rolePermissions: _rolePermissions(),
              ),
            ),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: RolePermissionsScreen(initialRoleId: 'role-1'),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Roles & Permissions'), findsOneWidget);
      expect(find.text('roles.permissions.view'), findsOneWidget);
      expect(find.byType(CheckboxListTile), findsNWidgets(2));

      final checkbox =
          tester.widget<CheckboxListTile>(find.byType(CheckboxListTile).first);
      expect(checkbox.value, isTrue);
    });

    testWidgets('shows error state when catalog load fails', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            tenantAdminContextProvider.overrideWith(
              (ref) async => _context(),
            ),
            tenantAdminAccessCheckerProvider.overrideWith(
              (ref) async => TenantAdminAccessChecker(_context()),
            ),
            rolePermissionsCanViewProvider.overrideWith((ref) => true),
            rolePermissionsCanUpdateProvider.overrideWith((ref) => false),
            rolePermissionsAvailableRolesProvider.overrideWith(
              (ref) => const [
                TenantAdminRoleOption(id: 'role-1', name: 'Tenant Admin'),
              ],
            ),
            rolePermissionsDataProvider('role-1').overrideWith(
              (ref) async => throw Exception('Catalog failed'),
            ),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: RolePermissionsScreen(initialRoleId: 'role-1'),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Unable to load permission catalog'), findsOneWidget);
    });
  });
}

TenantAdminContext _context() {
  return TenantAdminContext(
    tenantId: 'tenant-1',
    tenantName: 'Coffee Corner Ltd',
    userId: 'user-1',
    userDisplayName: 'Tenant Admin',
    roleNames: ['Tenant Admin'],
    roles: const [
      TenantAdminRole(id: 'role-1', name: 'Tenant Admin'),
    ],
    outletScope: const [],
    featureEntitlements: const [
      TenantAdminFeatureEntitlement(
        featureCode: TenantAdminFeatureCodes.rolePermission,
        featureName: 'tenant.roles',
        enabled: true,
      ),
    ],
    permissions: const [
      TenantAdminPermission(
        permissionCode: TenantAdminPermissionCodes.rolesPermissionsView,
        permissionName: 'View Role Permissions',
      ),
      TenantAdminPermission(
        permissionCode: TenantAdminPermissionCodes.rolesPermissionsUpdate,
        permissionName: 'Update Role Permissions',
      ),
    ],
    runtimeFlags: const [
      TenantAdminRuntimeFlag(
        featureCode: TenantAdminFeatureCodes.rolePermission,
        enabled: true,
      ),
    ],
  );
}

PermissionCatalog _catalog() {
  return const PermissionCatalog(
    modules: [
      PermissionCatalogModule(
        id: 'mod-1',
        code: 'tenant_admin',
        name: 'Tenant Admin',
        scope: 'tenant',
        sortOrder: 1,
        isActive: true,
        features: [
          PermissionCatalogFeature(
            id: 'feat-1',
            code: 'roles',
            name: 'Roles',
            sortOrder: 1,
            isActive: true,
            permissions: [
              PermissionCatalogPermission(
                id: 'perm-1',
                code: 'roles.permissions.view',
                name: 'View Role Permissions',
                scope: 'tenant',
                sortOrder: 1,
                isActive: true,
                source: 'tenant',
              ),
              PermissionCatalogPermission(
                id: 'perm-2',
                code: 'outlet.view',
                name: 'View Outlets',
                scope: 'tenant',
                sortOrder: 2,
                isActive: true,
                source: 'tenant',
              ),
            ],
          ),
        ],
      ),
    ],
  );
}

RolePermissions _rolePermissions() {
  return const RolePermissions(
    roleId: 'role-1',
    roleCode: 'tenant_admin_dev',
    roleName: 'Tenant Admin',
    roleScope: 'tenant',
    isSystem: true,
    assignedPermissionCodes: ['roles.permissions.view'],
    assignedPermissionIds: ['perm-1'],
  );
}
