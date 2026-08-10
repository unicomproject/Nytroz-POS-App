// ignore_for_file: prefer_const_constructors
import 'package:flutter_test/flutter_test.dart';
import 'package:nytroz_pos/features/tenant_admin/inventory/data/models/current_stock_dtos.dart';
import 'package:nytroz_pos/features/tenant_admin/inventory/data/models/stock_in_dtos.dart';

void main() {
  group('CurrentStockPageDto', () {
    test('parses backend current stock list response', () {
      final dto = CurrentStockPageDto.fromJson({
        'items': [
          {
            'inventoryBalanceId': 'aaaaaaaa-0001-4000-8000-000000000001',
            'inventoryLocationId': 'dddddddd-0001-4000-8000-000000000001',
            'outletId': 'bbbbbbbb-0001-4000-8000-000000000001',
            'outletName': 'Dev Outlet',
            'productId': 'cccccccc-0001-4000-8000-000000000001',
            'productName': 'Espresso Beans',
            'productVariantId': 'eeeeeeee-0001-4000-8000-000000000001',
            'variantName': '250g',
            'variantOptions': [
              {'name': 'Size', 'value': '250g'},
            ],
            'sku': 'ESP-250',
            'barcode': '1234567890',
            'productBatchId': 'ffffffff-0001-4000-8000-000000000001',
            'batchNumber': 'BATCH-001',
            'expiryDate': '2026-12-31',
            'onHandQuantity': 10,
            'reservedQuantity': 1,
            'damagedQuantity': 0,
            'quarantineQuantity': 0,
            'availableQuantity': 9,
            'stockStatus': 'IN_STOCK',
            'expiryStatus': 'VALID',
            'lastMovementAt': '2026-07-12T10:00:00Z',
            'rowVersion': 1,
          },
        ],
        'page': 1,
        'pageSize': 50,
        'totalCount': 1,
      });

      expect(dto.items, hasLength(1));
      expect(dto.items.first.productName, 'Espresso Beans');
      expect(dto.items.first.availableQuantity, 9);
      expect(dto.items.first.stockStatus, 'IN_STOCK');
      expect(dto.totalCount, 1);
    });

    test('unknown enum values do not crash parsing', () {
      final dto = CurrentStockItemDto.fromJson({
        'inventoryBalanceId': 'id',
        'inventoryLocationId': 'loc',
        'outletId': 'outlet',
        'outletName': 'Outlet',
        'productId': 'product',
        'productName': 'Product',
        'variantOptions': [],
        'onHandQuantity': 0,
        'reservedQuantity': 0,
        'damagedQuantity': 0,
        'quarantineQuantity': 0,
        'availableQuantity': 0,
        'stockStatus': 'FUTURE_STATUS',
        'expiryStatus': 'FUTURE_EXPIRY',
        'rowVersion': 0,
      });

      expect(dto.stockStatus, 'FUTURE_STATUS');
      expect(dto.expiryStatus, 'FUTURE_EXPIRY');
    });
  });

  group('CurrentStockQueryDto', () {
    test('maps supported query parameters only', () {
      final params = const CurrentStockQueryDto(
        outletId: 'bbbbbbbb-0001-4000-8000-000000000001',
        search: 'espresso',
        stockStatus: 'LOW_STOCK',
        expiryStatus: 'EXPIRING',
        batchNumber: 'BATCH-001',
        page: 2,
        pageSize: 25,
        sortBy: 'productName',
        sortDirection: 'asc',
      ).toQueryParameters();

      expect(params['outletId'], 'bbbbbbbb-0001-4000-8000-000000000001');
      expect(params['search'], 'espresso');
      expect(params['stockStatus'], 'LOW_STOCK');
      expect(params['expiryStatus'], 'EXPIRING');
      expect(params['batchNumber'], 'BATCH-001');
      expect(params['page'], 2);
      expect(params['pageSize'], 25);
      expect(params['sortBy'], 'productName');
      expect(params['sortDirection'], 'asc');
    });
  });

  group('CreateStockInRequestDto', () {
    test('serializes stock in request fields', () {
      final json = const CreateStockInRequestDto(
        outletId: 'bbbbbbbb-0001-4000-8000-000000000001',
        referenceNumber: 'GRN-001',
        receivedAt: '2026-07-12T10:00:00Z',
        notes: 'Morning delivery',
        idempotencyKey: 'key-1',
        items: [
          StockInLineRequestDto(
            productVariantId: 'eeeeeeee-0001-4000-8000-000000000001',
            batchNumber: 'BATCH-001',
            manufacturedDate: '2026-01-01',
            expiryDate: '2026-12-31',
            quantity: 5,
            unitCost: 100,
            barcode: '1234567890',
          ),
        ],
      ).toJson();

      expect(json['outletId'], 'bbbbbbbb-0001-4000-8000-000000000001');
      expect(json['referenceNumber'], 'GRN-001');
      expect(json['items'], hasLength(1));
      expect(json['items'][0]['productVariantId'],
          'eeeeeeee-0001-4000-8000-000000000001');
      expect(json['items'][0]['quantity'], 5);
    });
  });
}

