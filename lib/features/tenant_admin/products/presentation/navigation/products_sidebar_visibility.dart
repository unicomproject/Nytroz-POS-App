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
    this.isRouteAvailable = true,
    this.unavailableMessage = 'This screen is not available yet.',
  });

  final String key;
  final String label;
  final String route;
  final String permissionCode;
  final bool isVisible;
  final bool isRouteAvailable;
  final String unavailableMessage;
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

  /// Approved Products children order:
  /// Product List, Add Product, Categories, Brands, Inventory, Import.
  static ProductsSidebarVisibility resolve({
    required TenantAdminAccessChecker access,
  }) {
    final children = <ProductsSidebarChildVisibility>[
      ProductsSidebarChildVisibility(
        key: 'add-product',
        label: 'Add Product',
        route: ProductsSidebarRoutes.add,
        permissionCode: TenantAdminPermissionCodes.tenantProductsCreate,
        isVisible: access.canCreateProductNav(),
      ),
      ProductsSidebarChildVisibility(
        key: 'categories',
        label: 'Categories & Subcategories',
        route: ProductsSidebarRoutes.categories,
        permissionCode: TenantAdminPermissionCodes.tenantCategoriesView,
        isVisible: access.canViewCategoriesNav(),
      ),
      ProductsSidebarChildVisibility(
        key: 'brands',
        label: 'Brand',
        route: ProductsSidebarRoutes.brands,
        permissionCode: TenantAdminPermissionCodes.tenantBrandsView,
        isVisible: access.canViewBrandsNav(),
      ),
    ];

    final visibleChildren =
        children.where((child) => child.isVisible).toList(growable: false);

    return ProductsSidebarVisibility(
      showParent:
          visibleChildren.isNotEmpty || access.canAccessProductListPage(),
      children: children,
    );
  }
}
