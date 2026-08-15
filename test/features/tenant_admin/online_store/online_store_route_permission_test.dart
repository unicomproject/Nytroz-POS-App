import 'package:flutter_test/flutter_test.dart';
import 'package:nytroz_pos/core/access/tenant_admin_access_codes.dart';
import 'package:nytroz_pos/core/network/api_endpoints.dart';
import 'package:nytroz_pos/features/tenant_admin/data/catalog/tenant_admin_menu_catalog.dart';
import 'package:nytroz_pos/features/tenant_admin/domain/entities/tenant_admin_context.dart';
import 'package:nytroz_pos/features/tenant_admin/domain/services/tenant_admin_access_checker.dart';
import 'package:nytroz_pos/features/tenant_admin/online_store/presentation/screens/online_store_setup_screen.dart';
import 'package:nytroz_pos/features/tenant_admin/presentation/routing/tenant_admin_route_definition.dart';

void main() {
  test('online store canonical step order and deep-link routes are registered',
      () {
    final stepLabels = OnlineStoreSetupScreen.steps
        .cast<dynamic>()
        .map((dynamic step) => step.label as String)
        .toList(growable: false);

    expect(
      stepLabels,
      [
        'Overview',
        'Activation',
        'Identity',
        'Domain',
        'Branding',
        'Support',
        'Click & Collect',
        'Products & Policies',
        'Review & Publish',
      ],
    );

    final routes = tenantAdminRouteDefinitions
        .where((definition) => definition.menuKey == 'online-store')
        .toList(growable: false);

    expect(
      routes.map((route) => route.path),
      [
        '/tenant-admin/online-store',
        '/tenant-admin/online-store/activation',
        '/tenant-admin/online-store/identity',
        '/tenant-admin/online-store/domain',
        '/tenant-admin/online-store/branding',
        '/tenant-admin/online-store/support',
        '/tenant-admin/online-store/click-collect',
        '/tenant-admin/online-store/products-policies',
        '/tenant-admin/online-store/review',
      ],
    );
    expect(
      routes.every(
        (route) =>
            route.featureCode == TenantAdminFeatureCodes.onlineStore &&
            route.permissionCode == TenantAdminPermissionCodes.onlineStoreView,
      ),
      isTrue,
    );
  });

  test('sidebar uses Online Store entitlement and view permission', () {
    final item = tenantAdminMenuCatalog.singleWhere(
      (menuItem) => menuItem.key == 'online-store',
    );

    expect(item.label, 'Online Store');
    expect(item.route, '/tenant-admin/online-store');
    expect(item.featureCode, TenantAdminFeatureCodes.onlineStore);
    expect(item.permissionCode, TenantAdminPermissionCodes.onlineStoreView);
  });

  test('endpoint constants match backend online store route family', () {
    expect(
      ApiEndpoints.tenantAdminOnlineStore,
      '/api/v1/tenant-admin/online-store',
    );
    expect(
      ApiEndpoints.tenantAdminOnlineStoreClickCollect,
      '/api/v1/tenant-admin/online-store/click-collect',
    );
    expect(
      ApiEndpoints.tenantAdminOnlineStoreCatalogProducts,
      '/api/v1/tenant-admin/online-store/catalog/products',
    );
    expect(
      ApiEndpoints.tenantAdminOnlineStorePublish,
      '/api/v1/tenant-admin/online-store/publish',
    );
  });

  test('permissions and click_collect entitlement gate are distinct', () {
    const permissionCodes = [
      TenantAdminPermissionCodes.onlineStoreView,
      TenantAdminPermissionCodes.onlineStoreManage,
      TenantAdminPermissionCodes.onlineStorePublish,
      TenantAdminPermissionCodes.onlineStoreDomainsManage,
      TenantAdminPermissionCodes.onlineStoreBrandingManage,
      TenantAdminPermissionCodes.onlineStoreSupportManage,
      TenantAdminPermissionCodes.onlineStoreFulfillmentManage,
      TenantAdminPermissionCodes.onlineStoreCatalogManage,
      TenantAdminPermissionCodes.onlineStorePoliciesManage,
    ];

    expect(permissionCodes, [
      'tenant.online_store.view',
      'tenant.online_store.manage',
      'tenant.online_store.publish',
      'tenant.online_store.domains.manage',
      'tenant.online_store.branding.manage',
      'tenant.online_store.support.manage',
      'tenant.online_store.fulfillment.manage',
      'tenant.online_store.catalog.manage',
      'tenant.online_store.policies.manage',
    ]);

    final checkerWithoutClickCollect = TenantAdminAccessChecker(
      _context(
        features: [TenantAdminFeatureCodes.onlineStore],
        permissions: [TenantAdminPermissionCodes.onlineStoreFulfillmentManage],
      ),
    );
    final checkerWithClickCollect = TenantAdminAccessChecker(
      _context(
        features: [
          TenantAdminFeatureCodes.onlineStore,
          TenantAdminFeatureCodes.clickCollect,
        ],
        permissions: [TenantAdminPermissionCodes.onlineStoreFulfillmentManage],
      ),
    );

    expect(
        checkerWithoutClickCollect.canManageOnlineStoreFulfillment(), isFalse);
    expect(checkerWithClickCollect.canManageOnlineStoreFulfillment(), isTrue);
  });
}

TenantAdminContext _context({
  required List<String> features,
  required List<String> permissions,
}) {
  return TenantAdminContext(
    tenantId: 'tenant-1',
    tenantName: 'Tenant',
    userId: 'user-1',
    userDisplayName: 'User',
    roles: const [],
    roleNames: const [],
    outletScope: const [],
    featureEntitlements: [
      for (final feature in features)
        TenantAdminFeatureEntitlement(
          featureCode: feature,
          featureName: feature,
          enabled: true,
        ),
    ],
    permissions: [
      for (final permission in permissions)
        TenantAdminPermission(
          permissionCode: permission,
          permissionName: permission,
        ),
    ],
    runtimeFlags: const [],
  );
}
