class InventoryRoutes {
  const InventoryRoutes._();

  static const currentStock = '/tenant-admin/stock/current';
  static const stockIn = '/tenant-admin/stock/in';
  static const stockRoot = '/tenant-admin/stock';

  static bool isInventoryArea(String path) {
    return path == stockRoot ||
        path == currentStock ||
        path == stockIn ||
        path.startsWith('$stockRoot/');
  }
}
