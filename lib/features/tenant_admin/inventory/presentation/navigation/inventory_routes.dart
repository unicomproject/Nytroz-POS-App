import 'package:go_router/go_router.dart';

import '../dashboard/pages/inventory_dashboard_page.dart';
// import '../screens/current_stock_screen.dart'; // Add later when implemented
// import '../screens/stock_in_screen.dart'; // Add later when implemented

class InventoryRoutes {
  static const stockRoot = '/tenant-admin/stock';
  static const dashboard = '/tenant-admin/stock/dashboard';
  static const currentStock = '/tenant-admin/stock/current';
  static const currentStockDetail = '/tenant-admin/stock/current/:variantId';
  static const stockIn = '/tenant-admin/stock/in';

  static List<RouteBase> getRoutes() {
    return [
      GoRoute(
        path: dashboard,
        builder: (context, state) => const InventoryDashboardPage(),
      ),
      // Add other inventory routes here later
    ];
  }
}
