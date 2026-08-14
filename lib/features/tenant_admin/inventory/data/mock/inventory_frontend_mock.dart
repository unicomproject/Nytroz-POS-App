import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/inventory_dashboard_models.dart';
import '../../domain/entities/current_stock_entities.dart';
import '../../../outlets/domain/entities/outlet.dart';
import '../../../products/domain/entities/tenant_product.dart';
import '../../domain/entities/opening_stock_param.dart';
import '../../domain/repositories/opening_stock_repository.dart';

/// Isolated frontend-only catalog for the locked 29-screen Inventory UI.
/// Replace by setting [inventoryFrontendMockEnabledProvider] to false when
/// the locked API is integrated.
final inventoryFrontendMockEnabledProvider = Provider<bool>((ref) => true);

class InventoryOpeningStockMockRepository implements OpeningStockRepository {
  const InventoryOpeningStockMockRepository();

  @override
  Future<OpeningStockResult> submitOpeningStock(OpeningStockParam param) async {
    return OpeningStockResult(
      stockMovementId: 'OS-10001',
      outletId: param.outletId,
      itemCount: param.items.length,
      createdAt: '2025-05-19T10:15:00Z',
    );
  }
}

class InventoryFrontendMock {
  const InventoryFrontendMock._();

  static const locations = <InventoryMockLocation>[
    InventoryMockLocation(id: 'loc-main', name: 'Main Outlet'),
    InventoryMockLocation(id: 'loc-wh', name: 'Warehouse'),
    InventoryMockLocation(id: 'loc-02', name: 'Outlet 02'),
    InventoryMockLocation(id: 'loc-03', name: 'Outlet 03'),
  ];

  static const channels = <InventoryMockChannel>[
    InventoryMockChannel(id: 'ch-pos', name: 'POS', subtitle: 'In-store sales'),
    InventoryMockChannel(
        id: 'ch-online', name: 'Online Store', subtitle: 'E-commerce'),
    InventoryMockChannel(
        id: 'ch-cnc', name: 'Click & Collect', subtitle: 'Pickup orders'),
    InventoryMockChannel(
        id: 'ch-delivery', name: 'Delivery', subtitle: 'Local delivery'),
  ];

  static const products = <InventoryMockProduct>[
    InventoryMockProduct(
      id: 'p-jersey',
      variantId: 'v-jersey-red-l',
      name: 'Home Jersey (Red, L)',
      sku: 'OVZ-HJ-RED-L',
      category: 'Apparel',
      onHand: 90,
      reserved: 8,
      available: 82,
      alreadyAllocated: 40,
      safetyBuffer: 5,
      serialTracked: false,
      status: 'Low Stock',
    ),
    InventoryMockProduct(
      id: 'p-bottle',
      variantId: 'v-bottle',
      name: 'OneVerz Water Bottle 750ml',
      sku: 'OVZ-WB-001',
      category: 'Accessories',
      onHand: 42,
      reserved: 2,
      available: 40,
      alreadyAllocated: 10,
      safetyBuffer: 4,
      serialTracked: false,
      status: 'In Stock',
    ),
    InventoryMockProduct(
      id: 'p-mug',
      variantId: 'v-mug',
      name: 'OneVerz Mug',
      sku: 'OVZ-MUG-001',
      category: 'Accessories',
      onHand: 0,
      reserved: 0,
      available: 0,
      alreadyAllocated: 0,
      safetyBuffer: 0,
      serialTracked: false,
      status: 'Out of Stock',
    ),
    InventoryMockProduct(
      id: 'p-tv',
      variantId: 'v-tv',
      name: 'OneVerz Display TV 55"',
      sku: 'OVZ-TV-55',
      category: 'Electronics',
      onHand: 12,
      reserved: 1,
      available: 11,
      alreadyAllocated: 3,
      safetyBuffer: 1,
      serialTracked: true,
      status: 'In Stock',
    ),
  ];

  static const adjustmentReasons = <InventoryMockReason>[
    InventoryMockReason(
        id: 'r-damaged', name: 'Damaged', direction: 'DECREASE'),
    InventoryMockReason(
        id: 'r-found', name: 'Found Stock', direction: 'INCREASE'),
    InventoryMockReason(
        id: 'r-correction', name: 'Data Correction', direction: 'INCREASE'),
    InventoryMockReason(
        id: 'r-event', name: 'Event Usage', direction: 'DECREASE'),
  ];

  static InventoryDashboardMetricsDto get metrics =>
      const InventoryDashboardMetricsDto(
        lowStockCount: 24,
        outOfStockCount: 7,
        nearExpiryCount: 18,
        activeStockCounts: 1248,
      );

  static InventoryDashboardAlertsResponseDto get alerts {
    final now = DateTime(2025, 5, 19, 10, 15);
    return InventoryDashboardAlertsResponseDto(
      items: [
        InventoryDashboardAlertItemDto(
          productId: 'p-jersey',
          variantId: 'v-jersey-red-l',
          productName: 'Home Jersey (Red, L)',
          sku: 'OVZ-HJ-RED-L',
          outletId: 'loc-main',
          outletName: 'Main Outlet',
          alertType: 'LOW_STOCK',
          severity: 'HIGH',
          detectedOn: now,
        ),
        InventoryDashboardAlertItemDto(
          productId: 'p-bottle',
          productName: 'OneVerz Water Bottle 750ml',
          sku: 'OVZ-WB-001',
          outletId: 'loc-wh',
          outletName: 'Warehouse',
          alertType: 'NEAR_EXPIRY',
          severity: 'MEDIUM',
          detectedOn: now,
        ),
        InventoryDashboardAlertItemDto(
          productId: 'p-mug',
          productName: 'OneVerz Mug',
          sku: 'OVZ-MUG-001',
          outletId: 'loc-03',
          outletName: 'Outlet 03',
          alertType: 'OUT_OF_STOCK',
          severity: 'HIGH',
          detectedOn: now,
        ),
      ],
    );
  }

  static InventoryDashboardActivitiesResponseDto get activities {
    final ts = DateTime(2025, 5, 19, 10, 15);
    return InventoryDashboardActivitiesResponseDto(
      items: [
        InventoryDashboardActivityItemDto(
          stockMovementId: 'm-1',
          activityType: 'Opening stock added',
          outletId: 'loc-main',
          outletName: 'Main Outlet',
          timestamp: ts,
          changeQuantity: 24,
        ),
        InventoryDashboardActivityItemDto(
          stockMovementId: 'm-2',
          activityType: 'Stock adjusted',
          outletId: 'loc-02',
          outletName: 'Outlet 02',
          timestamp: ts.subtract(const Duration(minutes: 35)),
          changeQuantity: -3,
        ),
        InventoryDashboardActivityItemDto(
          stockMovementId: 'm-3',
          activityType: 'Stock received',
          outletId: 'loc-wh',
          outletName: 'Warehouse',
          timestamp: ts.subtract(const Duration(hours: 18)),
          changeQuantity: 40,
        ),
      ],
    );
  }

  static List<CurrentStockItem> get stockItems => products
      .map(
        (p) => CurrentStockItem(
          inventoryBalanceId: 'bal-${p.id}',
          inventoryLocationId: 'loc-main',
          outletId: 'loc-main',
          outletName: 'Main Outlet',
          productId: p.id,
          productName: p.name,
          variantId: p.variantId,
          sku: p.sku,
          onHandQuantity: p.onHand,
          reservedQuantity: p.reserved,
          availableQuantity: p.available,
          stockStatus: p.status == 'Out of Stock'
              ? 'OutOfStock'
              : p.status == 'Low Stock'
                  ? 'LowStock'
                  : 'InStock',
          reorderLevel: 10,
        ),
      )
      .toList();

  static CurrentStockSummary get stockSummary => const CurrentStockSummary(
        totalItemsInStock: 3,
        totalItemsLowStock: 1,
        totalItemsOutOfStock: 1,
        totalInventoryValue: 18420,
        totalProducts: 4,
        lowStockCount: 1,
        outOfStockCount: 1,
      );

  static CurrentStockPage stockPage({
    required String search,
    required int page,
    required int pageSize,
  }) {
    final q = search.trim().toLowerCase();
    var items = stockItems;
    if (q.isNotEmpty) {
      items = items
          .where((e) =>
              (e.productName ?? '').toLowerCase().contains(q) ||
              (e.sku ?? '').toLowerCase().contains(q))
          .toList();
    }
    final start = ((page - 1) * pageSize).clamp(0, items.length);
    final end = (start + pageSize).clamp(0, items.length);
    return CurrentStockPage(
      items: items.sublist(start, end),
      page: page,
      pageSize: pageSize,
      totalCount: items.length,
    );
  }

  static ProductStockDetail productDetail(String id) {
    final product = products.firstWhere(
      (p) => p.id == id || p.variantId == id,
      orElse: () => products.first,
    );
    return ProductStockDetail(
      productId: product.id,
      productName: product.name,
      productVariantId: product.variantId,
      sku: product.sku,
      categoryName: product.category,
      productStatus: 'ACTIVE',
      stockStatus: product.status,
      totalOnHand: product.onHand,
      totalReserved: product.reserved,
      totalAvailable: product.available,
      totalReorderLevel: 10,
      locationBalances: [
        LocationBalance(
          locationId: 'loc-main',
          locationName: 'Main Outlet',
          onHand: product.onHand,
          reserved: product.reserved,
          available: product.available,
          reorderLevel: 10,
        ),
      ],
    );
  }

  static StockMovementHistoryPage movements(String id) {
    return StockMovementHistoryPage(
      items: [
        StockMovementHistory(
          movementId: 'mv-1',
          movementType: 'RECEIPT',
          reference: 'RCV-10021',
          locationName: 'Main Outlet',
          date: DateTime(2025, 5, 18, 16, 25),
          change: 20,
        ),
        StockMovementHistory(
          movementId: 'mv-2',
          movementType: 'ADJUSTMENT_OUT',
          reference: 'ADJ-10008',
          locationName: 'Main Outlet',
          date: DateTime(2025, 5, 17, 11, 10),
          change: -2,
        ),
      ],
      totalCount: 2,
      page: 1,
      pageSize: 5,
    );
  }

  static List<TenantProduct> get tenantProducts => products
      .map(
        (p) => TenantProduct(
          id: p.id,
          productCode: p.sku,
          name: p.name,
          sku: p.sku,
          status: 'ACTIVE',
          categoryName: p.category,
        ),
      )
      .toList();

  static List<Outlet> get tenantOutlets => locations
      .map(
        (l) => Outlet(
          id: l.id,
          name: l.name,
          code: l.id.toUpperCase(),
          status: 'ACTIVE',
          outletType: l.id == 'loc-wh' ? 'WAREHOUSE' : 'STORE',
        ),
      )
      .toList();

  static const serials = <InventoryMockSerial>[
    InventoryMockSerial(
      serial: 'TV-55-10021',
      productName: 'OneVerz Display TV 55"',
      sku: 'OVZ-TV-55',
      locationName: 'Warehouse',
      status: 'IN_STOCK',
    ),
    InventoryMockSerial(
      serial: 'TV-55-10022',
      productName: 'OneVerz Display TV 55"',
      sku: 'OVZ-TV-55',
      locationName: 'Warehouse',
      status: 'IN_STOCK',
    ),
    InventoryMockSerial(
      serial: 'TV-55-09910',
      productName: 'OneVerz Display TV 55"',
      sku: 'OVZ-TV-55',
      locationName: 'Main Outlet',
      status: 'RESERVED',
    ),
    InventoryMockSerial(
      serial: 'TV-55-09911',
      productName: 'OneVerz Display TV 55"',
      sku: 'OVZ-TV-55',
      locationName: 'Main Outlet',
      status: 'IN_STOCK',
    ),
    InventoryMockSerial(
      serial: 'TV-55-09912',
      productName: 'OneVerz Display TV 55"',
      sku: 'OVZ-TV-55',
      locationName: 'Warehouse',
      status: 'IN_STOCK',
    ),
    InventoryMockSerial(
      serial: 'TV-55-09913',
      productName: 'OneVerz Display TV 55"',
      sku: 'OVZ-TV-55',
      locationName: 'Outlet 02',
      status: 'IN_STOCK',
    ),
  ];
}

class InventoryMockLocation {
  const InventoryMockLocation({required this.id, required this.name});
  final String id;
  final String name;
}

class InventoryMockChannel {
  const InventoryMockChannel({
    required this.id,
    required this.name,
    required this.subtitle,
  });
  final String id;
  final String name;
  final String subtitle;
}

class InventoryMockProduct {
  const InventoryMockProduct({
    required this.id,
    required this.variantId,
    required this.name,
    required this.sku,
    required this.category,
    required this.onHand,
    required this.reserved,
    required this.available,
    required this.alreadyAllocated,
    required this.safetyBuffer,
    required this.serialTracked,
    required this.status,
  });

  final String id;
  final String variantId;
  final String name;
  final String sku;
  final String category;
  final double onHand;
  final double reserved;
  final double available;
  final double alreadyAllocated;
  final double safetyBuffer;
  final bool serialTracked;
  final String status;

  double get allocatable =>
      (available - safetyBuffer - alreadyAllocated).clamp(0, available);
}

class InventoryMockReason {
  const InventoryMockReason({
    required this.id,
    required this.name,
    required this.direction,
  });
  final String id;
  final String name;
  final String direction;
}

class InventoryMockSerial {
  const InventoryMockSerial({
    required this.serial,
    required this.productName,
    required this.sku,
    required this.locationName,
    required this.status,
  });
  final String serial;
  final String productName;
  final String sku;
  final String locationName;
  final String status;
}
