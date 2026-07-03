import 'package:flutter_test/flutter_test.dart';
import 'package:nytroz_pos/features/tenant_admin/inventory/data/mappers/inventory_mapper.dart';
import 'package:nytroz_pos/features/tenant_admin/inventory/data/models/inventory_dto.dart';

void main() {
  group('InventoryMapper', () {
    test('maps balance list result from dto', () {
      const dto = InventoryBalanceListResultDto(
        summary: InventoryBalanceSummaryDto(
          onHand: 100,
          reserved: 20,
          available: 80,
          lowStockItems: 3,
        ),
        items: [
          InventoryBalanceRowDto(
            productId: 'p1',
            productName: 'Cappuccino',
            variantId: 'v1',
            variantLabel: 'Regular',
            onHand: 24,
            reserved: 2,
            available: 22,
            lowStockThreshold: 10,
          ),
        ],
        page: 1,
        pageSize: 10,
        totalCount: 1,
      );

      final result = InventoryMapper.toBalanceListResult(dto);

      expect(result.summary.onHand, 100);
      expect(result.summary.lowStockItems, 3);
      expect(result.items, hasLength(1));
      expect(result.items.first.productName, 'Cappuccino');
      expect(result.items.first.displayAvailable, 22);
      expect(result.totalCount, 1);
    });

    test('maps location dto to entity', () {
      const dto = InventoryLocationDto(
        id: 'loc-1',
        name: 'Head Office Outlet',
        code: 'HO',
      );

      final entity = InventoryMapper.toLocationEntity(dto);

      expect(entity.id, 'loc-1');
      expect(entity.name, 'Head Office Outlet');
      expect(entity.code, 'HO');
    });
  });
}
