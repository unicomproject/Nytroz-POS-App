class ProductsSidebarRoutes {
  const ProductsSidebarRoutes._();

  static const dashboard = '/tenant-admin/products/dashboard';
  static const list = '/tenant-admin/products';
  static const add = '/tenant-admin/products/add';
  static const categories = '/tenant-admin/categories';
  static const brands = '/tenant-admin/brands';
  static const variantTemplates = '/tenant-admin/variant-templates';

  static bool isProductsArea(String path) {
    if (path == categories || path == brands || path == variantTemplates) {
      return true;
    }

    return path == list ||
        path == add ||
        path == dashboard ||
        path.startsWith('$list/');
  }

  static bool isParentActive(String path) => isProductsArea(path);

  static bool isChildActive({
    required String currentPath,
    required String route,
  }) {
    if (route == list) {
      return currentPath == list ||
          (currentPath.startsWith('$list/') &&
              currentPath != add &&
              currentPath != dashboard &&
              !currentPath.endsWith('/edit'));
    }

    return currentPath == route;
  }
}
