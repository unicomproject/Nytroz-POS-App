import '../../../../../core/access/tenant_admin_access_codes.dart';
import '../../../domain/services/tenant_admin_access_checker.dart';
import 'products_sidebar_routes.dart';

class ProductsSidebarChildVisibility {
  const ProductsSidebarChildVisibility({
    required this.key,
    required this.label,
    required this.route,
    required this.permissionCode,
    required this.isVisible,
  });

  final String key;
  final String label;
  final String route;
  final String permissionCode;
  final bool isVisible;
}

class ProductsSidebarVisibility {
  const ProductsSidebarVisibility({
    required this.showParent,
    required this.children,
  });

  final bool showParent;
  final List<ProductsSidebarChildVisibility> children;

  List<ProductsSidebarChildVisibility> get visibleChildren =>
      children.where((child) => child.isVisible).toList(growable: false);

  bool get hasVisibleChildren => visibleChildren.isNotEmpty;

  static ProductsSidebarVisibility resolve({
    required TenantAdminAccessChecker access,
  }) {
    final children = <ProductsSidebarChildVisibility>[
      ProductsSidebarChildVisibility(
        key: 'product-dashboard',
        label: 'Product Dashboard',
        route: ProductsSidebarRoutes.dashboard,
        permissionCode: TenantAdminPermissionCodes.tenantProductsDashboardView,
        isVisible: access.canViewProductDashboard(),
      ),
      ProductsSidebarChildVisibility(
        key: 'product-list',
        label: 'Product List',
        route: ProductsSidebarRoutes.list,
        permissionCode: TenantAdminPermissionCodes.tenantProductsView,
        isVisible: access.canViewProductListNav(),
      ),
      ProductsSidebarChildVisibility(
        key: 'add-product',
        label: 'Add Product',
        route: ProductsSidebarRoutes.add,
        permissionCode: TenantAdminPermissionCodes.tenantProductsCreate,
        isVisible: access.canCreateProductNav(),
      ),
      ProductsSidebarChildVisibility(
        key: 'categories',
        label: 'Categories',
        route: ProductsSidebarRoutes.categories,
        permissionCode: TenantAdminPermissionCodes.tenantCategoriesView,
        isVisible: access.canViewCategoriesNav(),
      ),
      ProductsSidebarChildVisibility(
        key: 'brands',
        label: 'Brands',
        route: ProductsSidebarRoutes.brands,
        permissionCode: TenantAdminPermissionCodes.tenantBrandsView,
        isVisible: access.canViewBrandsNav(),
      ),
      ProductsSidebarChildVisibility(
        key: 'variant-templates',
        label: 'Variant Templates',
        route: ProductsSidebarRoutes.variantTemplates,
        permissionCode: TenantAdminPermissionCodes.tenantVariantTemplatesView,
        isVisible: access.canViewVariantTemplatesNav(),
      ),
    ];

    final visibleChildren =
        children.where((child) => child.isVisible).toList(growable: false);

    return ProductsSidebarVisibility(
      showParent: visibleChildren.isNotEmpty,
      children: children,
    );
  }
}
