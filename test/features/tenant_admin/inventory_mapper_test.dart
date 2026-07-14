import 'package:flutter_test/flutter_test.dart';
import 'package:nytroz_pos/features/tenant_admin/inventory/data/mappers/inventory_mapper.dart';
import 'package:nytroz_pos/features/tenant_admin/inventory/domain/entities/inventory_entities.dart';

void main() {
  group('InventoryMapper', () {
    test('maps stock in form with blank optional values to null', () {
      final request = InventoryMapper.toStockInRequest(
        const StockInFormInput(
          outletId: 'bbbbbbbb-0001-4000-8000-000000000001',
          referenceNumber: '   ',
          notes: '',
          items: [
            StockInLineInput(
              productVariantId: 'eeeeeeee-0001-4000-8000-000000000001',
              quantity: 2,
              batchNumber: ' ',
            ),
          ],
        ),
        idempotencyKey: 'key-1',
      );

      expect(request.referenceNumber, isNull);
      expect(request.notes, isNull);
      expect(request.items.single.batchNumber, isNull);
      expect(request.items.single.quantity, 2);
    });

    test('formats dates as yyyy-MM-dd', () {
      final request = InventoryMapper.toStockInRequest(
        StockInFormInput(
          outletId: 'bbbbbbbb-0001-4000-8000-000000000001',
          receivedAt: DateTime(2026, 7, 12, 15, 30),
          items: [
            StockInLineInput(
              productVariantId: 'eeeeeeee-0001-4000-8000-000000000001',
              quantity: 1,
              manufacturedDate: DateTime(2026, 1, 5),
              expiryDate: DateTime(2026, 12, 31),
            ),
          ],
        ),
      );

      expect(request.items.single.manufacturedDate, '2026-01-05');
      expect(request.items.single.expiryDate, '2026-12-31');
    });
  });
}
