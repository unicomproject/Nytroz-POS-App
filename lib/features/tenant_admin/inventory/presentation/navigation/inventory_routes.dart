import 'package:go_router/go_router.dart';

import '../dashboard/pages/inventory_dashboard_page.dart';
import '../opening_stock/screens/opening_stock_wizard_screen.dart';

class InventoryRoutes {
  static const stockRoot = '/tenant-admin/stock';
  static const dashboard = '/tenant-admin/stock/dashboard';
  static const currentStock = '/tenant-admin/stock/current';
  static const currentStockDetail = '/tenant-admin/stock/current/:variantId';
  static const stockIn = '/tenant-admin/stock/in';

  static const openingStock = '/tenant-admin/stock/opening';

  static List<RouteBase> getRoutes() {
    return [
      GoRoute(
        path: dashboard,
        builder: (context, state) => const InventoryDashboardPage(),
      ),
      GoRoute(
        path: openingStock,
        builder: (context, state) => const OpeningStockWizardScreen(),
      ),
    ];
  }
}
