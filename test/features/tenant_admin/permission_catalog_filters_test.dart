import 'package:flutter_test/flutter_test.dart';
import 'package:nytroz_pos/features/tenant_admin/role_permissions/domain/entities/permission_catalog.dart';
import 'package:nytroz_pos/features/tenant_admin/role_permissions/presentation/utils/permission_catalog_filters.dart';

void main() {
  const catalog = PermissionCatalog(
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
                code: 'platform.permissions.view',
                name: 'View Platform Permissions',
                scope: 'platform',
                sortOrder: 2,
                isActive: true,
                source: 'platform',
              ),
            ],
          ),
        ],
      ),
    ],
  );

  test('filters by search term', () {
    final filtered = filterPermissionCatalog(
      catalog: catalog,
      searchQuery: 'outlet.view',
      scopeFilter: '',
      moduleFilter: null,
    );

    expect(filtered, isEmpty);
  });

  test('filters by scope', () {
    final filtered = filterPermissionCatalog(
      catalog: catalog,
      searchQuery: '',
      scopeFilter: 'platform',
      moduleFilter: null,
    );

    expect(countPermissions(filtered), 1);
    expect(
      filtered.first.features.first.permissions.first.code,
      'platform.permissions.view',
    );
  });
}
