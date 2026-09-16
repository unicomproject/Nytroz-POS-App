import 'package:go_router/go_router.dart';

import '../dashboard/pages/inventory_dashboard_page.dart';
import '../opening_stock/screens/opening_stock_wizard_screen.dart';

class InventoryRoutes {
  static const stockRoot = '/tenant-admin/stock';
  static const inventoryRoot = '/tenant-admin/inventory';

  static const dashboard = '$stockRoot/dashboard';
  static const currentStock = '$stockRoot/current';
  static const currentStockDetail = '$stockRoot/current/:variantId';
  static const stockIn = '$stockRoot/in';
  static const openingStock = '$stockRoot/opening';
  static const receiving = '$stockRoot/receiving';
  static const receivingNew = '$stockRoot/receiving/new';
  static const serials = '$stockRoot/serials';
  static const adjustment = '$stockRoot/adjust';
  static const adjustmentNew = '$stockRoot/adjust/new';
  static const channel = '$stockRoot/channel-allocations';
  static const channelNew = '$stockRoot/channel-allocations/new';
  static const channelDetail = '$stockRoot/channel-allocations/:id';

  static const inventoryDashboard = '$inventoryRoot/dashboard';
  static const inventoryCurrentStock = '$inventoryRoot/current';
  static const inventoryCurrentStockDetail =
      '$inventoryRoot/current/:variantId';
  static const inventoryOpeningStock = '$inventoryRoot/opening';
  static const inventoryReceiving = '$inventoryRoot/receiving';
  static const inventoryReceivingNew = '$inventoryRoot/receiving/new';
  static const inventorySerials = '$inventoryRoot/serials';
  static const inventoryAdjustment = '$inventoryRoot/adjust';
  static const inventoryAdjustmentNew = '$inventoryRoot/adjust/new';
  static const inventoryChannel = '$inventoryRoot/channel-allocations';
  static const inventoryChannelNew = '$inventoryRoot/channel-allocations/new';
  static const inventoryChannelDetail =
      '$inventoryRoot/channel-allocations/:id';

  static String channelDetailPath(String id) =>
      '$stockRoot/channel-allocations/$id';

  static bool matches(String path, String stockPath) {
    return path == stockPath || path == toInventory(stockPath);
  }

  static String toInventory(String stockPath) =>
      stockPath.replaceFirst(stockRoot, inventoryRoot);

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
