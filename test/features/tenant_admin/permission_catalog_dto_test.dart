import 'package:flutter_test/flutter_test.dart';
import 'package:nytroz_pos/features/tenant_admin/data/models/tenant_admin_context_dto.dart';
import 'package:nytroz_pos/features/tenant_admin/role_permissions/data/models/permission_catalog_dto.dart';
import 'package:nytroz_pos/features/tenant_admin/role_permissions/data/models/role_permissions_dto.dart';

void main() {
  group('PermissionCatalogDto', () {
    test('parses nested module-feature-permission tree', () {
      final dto = PermissionCatalogDto.fromJson({
        'modules': [
          {
            'id': 'mod-1',
            'code': 'tenant_admin',
            'name': 'Tenant Admin',
            'scope': 'tenant',
            'sortOrder': 1,
            'isActive': true,
            'features': [
              {
                'id': 'feat-1',
                'code': 'roles',
                'name': 'Roles',
                'sortOrder': 1,
                'isActive': true,
                'permissions': [
                  {
                    'id': 'perm-1',
                    'code': 'roles.permissions.view',
                    'name': 'View Role Permissions',
                    'scope': 'tenant',
                    'sortOrder': 1,
                    'isActive': true,
                    'source': 'tenant',
                  },
                ],
              },
            ],
          },
        ],
      });

      expect(dto.modules, hasLength(1));
      expect(dto.modules.first.code, 'tenant_admin');
      expect(dto.modules.first.features.first.permissions.first.code,
          'roles.permissions.view');
    });
  });

  group('RolePermissionsDto', () {
    test('parses assigned permission codes', () {
      final dto = RolePermissionsDto.fromJson({
        'roleId': '44000000-0000-0000-0000-000000000010',
        'roleCode': 'tenant_admin_dev',
        'roleName': 'Tenant Admin',
        'roleScope': 'tenant',
        'isSystem': true,
        'assignedPermissionCodes': [
          'roles.permissions.view',
          'outlet.view',
        ],
        'assignedPermissionIds': [
          '45000000-0000-0000-0000-000000000001',
        ],
      });

      expect(dto.roleCode, 'tenant_admin_dev');
      expect(dto.assignedPermissionCodes, contains('outlet.view'));
    });
  });

  group('TenantAdminContextDto', () {
    test('prefers effectivePermissions and enabledFeatures when present', () {
      final dto = TenantAdminContextDto.fromBackendJson({
        'tenant': {'id': 'tenant-1', 'name': 'Coffee Corner Ltd'},
        'user': {'id': 'user-1', 'fullName': 'Tenant Admin'},
        'roles': [
          {'id': 'role-1', 'name': 'Tenant Admin'},
        ],
        'features': ['legacy.feature'],
        'enabledFeatures': ['tenant.roles'],
        'permissions': ['legacy.permission'],
        'effectivePermissions': ['roles.permissions.view'],
        'runtimeFlags': [],
        'outlets': [],
      });

      expect(dto.permissions.first.permissionCode, 'roles.permissions.view');
      expect(dto.featureEntitlements.first.featureName, 'tenant.roles');
      expect(dto.roles.first.id, 'role-1');
    });
  });
}
