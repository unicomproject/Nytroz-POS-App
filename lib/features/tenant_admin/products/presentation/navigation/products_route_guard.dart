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
      case ProductsSidebarRoutes.categoriesAdd:
        return access.canCreateCategory();
      case ProductsSidebarRoutes.brands:
        return access.canViewBrandsNav();
      case ProductsSidebarRoutes.tax:
        return access.canAccessProductListPage();
      case ProductsSidebarRoutes.variantTemplates:
        return access.canViewVariantTemplatesNav();
      case ProductsSidebarRoutes.popular:
        return access.canViewPopularProductsNav();
      case ProductsSidebarRoutes.import:
        return access.canImportProductsNav();
      default:
        if (path.startsWith('${ProductsSidebarRoutes.categories}/') &&
            path.endsWith('/edit')) {
          return access.canUpdateCategory();
        }
        if (path.startsWith('${ProductsSidebarRoutes.categories}/')) {
          return access.canFetchCategoryList();
        }
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
      case 'catalog.collections.view':
        return 'catalog.collections.view';
      default:
        return permissionCode;
    }
  }
}
