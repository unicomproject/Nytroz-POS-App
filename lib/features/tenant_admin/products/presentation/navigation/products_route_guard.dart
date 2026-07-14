import '../../../../../core/access/tenant_admin_access_codes.dart';
import '../../../domain/services/tenant_admin_access_checker.dart';
import 'products_sidebar_routes.dart';

class ProductsRouteGuard {
  const ProductsRouteGuard._();

  static bool canAccessPath(
    TenantAdminAccessChecker access,
    String path,
  ) {
    switch (path) {
      case ProductsSidebarRoutes.dashboard:
        return access.canViewProductDashboard();
      case ProductsSidebarRoutes.list:
        return access.canViewProductListNav();
      case ProductsSidebarRoutes.add:
        return access.canCreateProductNav();
      case ProductsSidebarRoutes.categories:
        return access.canViewCategoriesNav();
      case ProductsSidebarRoutes.brands:
        return access.canViewBrandsNav();
      case ProductsSidebarRoutes.variantTemplates:
        return access.canViewVariantTemplatesNav();
      default:
        return false;
    }
  }

  static bool canAccessDefinition(
    TenantAdminAccessChecker access, {
    required String path,
    required String permissionCode,
  }) {
    if (canAccessPath(access, path)) {
      return true;
    }

    return access.can(permissionCode);
  }

  static String permissionLabel(String permissionCode) {
    switch (permissionCode) {
      case TenantAdminPermissionCodes.tenantProductsDashboardView:
        return 'tenant.products.dashboard.view';
      case TenantAdminPermissionCodes.tenantProductsView:
        return 'tenant.products.view';
      case TenantAdminPermissionCodes.tenantProductsCreate:
        return 'tenant.products.create';
      case TenantAdminPermissionCodes.tenantCategoriesView:
        return 'tenant.categories.view';
      case TenantAdminPermissionCodes.tenantBrandsView:
        return 'tenant.brands.view';
      case TenantAdminPermissionCodes.tenantVariantTemplatesView:
        return 'tenant.variant.templates.view';
      default:
        return permissionCode;
    }
  }
}
