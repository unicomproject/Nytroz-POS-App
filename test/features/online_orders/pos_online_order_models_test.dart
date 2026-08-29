import 'package:flutter_test/flutter_test.dart';
import 'package:nytroz_pos/features/fulfilment_pickup/domain/entities/pos_online_order.dart';

void main() {
  test('parses the canonical online-order list payload', () {
    final page = PosOnlineOrderPage.fromJson({
      'items': [
        {
          'id': 'order-1',
          'orderNumber': 'CC-0001',
          'customerName': 'Nimal',
          'externalReference': 'PICK-1',
          'collectionStart': '2026-08-24T10:30:00Z',
          'collectionEnd': '2026-08-24T11:00:00Z',
          'status': 'PREPARING',
          'statusLabel': 'Preparing',
          'paymentStatus': 'PAID',
          'currencyCode': 'LKR',
          'totalAmount': 2800,
          'itemCount': 1,
          'unitCount': 2,
          'productPreviews': [
            {
              'productId': 'product-1',
              'productVariantId': 'variant-1',
              'productName': 'Match Shorts',
              'imageUrl': 'https://example.test/product.png',
              'altText': 'Match Shorts Small',
            }
          ],
          'remainingPreviewCount': 3,
          'collectionTimezone': 'Asia/Colombo',
          'placedAt': '2026-08-24T08:00:00Z',
          'updatedAt': '2026-08-24T08:15:00Z',
        },
      ],
      'summary': {
        'newCount': 1,
        'preparingCount': 1,
        'readyCount': 2,
        'delayedCount': 0,
        'collectedCount': 3,
        'cancelledCount': 1,
      },
      'page': 1,
      'pageSize': 20,
      'totalCount': 4,
      'totalPages': 1,
      'serverTime': '2026-08-24T09:00:00Z',
    });

    expect(page.items.single.orderNumber, 'CC-0001');
    expect(page.items.single.totalAmount, 2800);
    expect(page.items.single.collectionAt, isNotNull);
    expect(page.items.single.collectionTimezone, 'Asia/Colombo');
    expect(page.items.single.placedAt, isNotNull);
    expect(page.summary.ready, 2);
    expect(page.summary.total, 8);
    expect(
        page.items.single.productPreviews.single.productName, 'Match Shorts');
    expect(page.items.single.remainingPreviewCount, 3);
    expect(page.items.single.unitCount, 2);
    expect(page.serverTime, isNotNull);
    expect(page.totalCount, 4);
  });

  test('maps only backend-supported queue query parameters', () {
    const query = PosOnlineOrdersQuery(
      outletId: 'outlet-1',
      search: '  CC-0001  ',
      status: 'PREPARING',
      sort: PosOnlineOrderSort.newest,
      page: 2,
      pageSize: 20,
    );

    expect(query.toQueryParameters(), {
      'outletId': 'outlet-1',
      'page': 2,
      'pageSize': 20,
      'search': 'CC-0001',
      'status': 'PREPARING',
      'sortBy': 'placedAt',
      'sortDirection': 'desc',
    });
    expect(
      const PosOnlineOrdersQuery(outletId: 'outlet-1')
          .toQueryParameters()['sortBy'],
      'collectionTime',
    );
  });

  test('parses real order-line fulfilment progress', () {
    final detail = PosOnlineOrderDetail.fromJson({
      'id': 'order-1',
      'orderNumber': 'CC-0001',
      'outletName': 'Main Outlet',
      'customerName': 'Nimal',
      'status': 'PREPARING',
      'statusLabel': 'Preparing',
      'paymentStatus': 'PAID',
      'currencyCode': 'LKR',
      'subtotal': 3000,
      'discount': 200,
      'tax': 0,
      'charges': 0,
      'totalAmount': 2800,
      'paid': 2800,
      'balanceDue': 0,
      'outletId': 'outlet-1',
      'customerId': 'customer-1',
      'fulfillmentOrderId': 'fulfilment-1',
      'assignedToTenantUserId': 'user-1',
      'lines': [
        {
          'id': 'line-1',
          'lineNumber': 1,
          'productName': 'Match Shorts',
          'variantName': 'Small',
          'sku': 'MER-003-S',
          'quantity': 1,
          'unitPrice': 2800,
          'lineTotal': 2800,
          'pickedQuantity': 1,
          'packedQuantity': 0,
          'lineStatus': 'OPEN',
        },
      ],
    });

    expect(detail.lines.single.productName, 'Match Shorts');
    expect(detail.lines.single.pickedQuantity, 1);
    expect(detail.lines.single.packedQuantity, 0);
    expect(detail.discount, 200);
    expect(detail.outletId, 'outlet-1');
    expect(detail.unitCount, 1);
    expect(detail.lines.single.remainingQuantity, 0);
  });

  test('parses the canonical read-only picking payload', () {
    final picking = PosPickingOrder.fromJson({
      'orderId': 'order-1',
      'orderNumber': 'CC-0001',
      'fulfillmentOrderId': 'fulfilment-1',
      'fulfillmentNumber': 'FUL-CC-0001',
      'status': 'PICKING',
      'assignedToName': 'Kavin',
      'assignedToTenantUserId': 'user-1',
      'customerName': 'Nimal',
      'collectionAt': '2026-08-25T10:30:00Z',
      'totalLines': 1,
      'pickedLines': 0,
      'lines': [
        {
          'id': 'fulfilment-line-1',
          'lineNumber': 1,
          'productName': 'Match Shorts',
          'variantName': 'Small',
          'sku': 'MER-003-S',
          'requestedQuantity': 1,
          'pickedQuantity': 0,
          'status': 'PICKING',
          'locationCode': 'FRONT',
          'locationName': 'Front Store',
        },
      ],
    });

    expect(picking.status, 'PICKING');
    expect(picking.assignedToName, 'Kavin');
    expect(picking.lines.single.locationCode, 'FRONT');
    expect(picking.lines.single.requestedQuantity, 1);
    expect(picking.remainingUnits, 1);
    expect(picking.allPicked, isFalse);
  });

  test('parses an authoritative fulfilment command response', () {
    final result = PosFulfillmentCommandResult.fromJson({
      'orderId': 'order-1',
      'status': 'PACKED',
      'totalLines': 2,
      'completedLines': 2,
      'packageNumber': 'PKG-CC-0001-01',
      'fulfillmentOrderId': 'fulfilment-1',
      'updatedAt': '2026-08-25T10:30:00Z',
    });

    expect(result.orderId, 'order-1');
    expect(result.status, 'PACKED');
    expect(result.completedLines, 2);
    expect(result.packageNumber, 'PKG-CC-0001-01');
    expect(result.fulfillmentOrderId, 'fulfilment-1');
    expect(result.updatedAt, isNotNull);
  });
}
