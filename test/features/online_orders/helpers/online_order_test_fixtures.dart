import 'package:nytroz_pos/features/fulfilment_pickup/domain/entities/pos_online_order.dart';

const testPickingLine = PosPickingLine(
  id: 'line-1',
  lineNumber: 1,
  productName: 'Match Shorts',
  sku: 'MER-003-SKU',
  requestedQuantity: 1,
  pickedQuantity: 0,
  status: 'PENDING',
  locationCode: 'MAIN',
  locationName: 'Main Store Stock',
);

const testPickingOrder = PosPickingOrder(
  orderId: 'order-1',
  orderNumber: 'ECOMM-SEED-ACCEPTED-001',
  fulfillmentOrderId: 'fulfilment-1',
  fulfillmentNumber: 'FUL-1',
  status: 'PICKING',
  assignedToName: 'Cashier',
  customerName: 'Customer 1',
  totalLines: 3,
  pickedLines: 0,
  canPack: false,
  lines: [testPickingLine, testPickingLine, testPickingLine],
);

PosOnlineOrderDetail testOnlineOrderDetail(String status) =>
    PosOnlineOrderDetail(
      order: const PosOnlineOrder(
        id: 'order-1',
        orderNumber: 'ORDER-1',
        customerName: 'Customer',
        status: 'ACCEPTED',
        statusLabel: 'Accepted',
        paymentStatus: 'PAID',
        currencyCode: 'LKR',
        totalAmount: 100,
        lineCount: 1,
        unitCount: 1,
      ),
      outletName: 'Outlet A',
      paymentStatus: 'PAID',
      subtotal: 100,
      discount: 0,
      tax: 0,
      charges: 0,
      paid: 100,
      balanceDue: 0,
      fulfillmentStatus: status,
      fulfillmentVersion: 5,
      fulfillmentOrderId: 'fulfilment-1',
      pickupStatus: 'PENDING',
      lines: const [
        PosOnlineOrderLine(
            id: 'line-1',
            lineNumber: 1,
            productName: 'Match Shorts',
            quantity: 1,
            unitPrice: 100,
            lineTotal: 100,
            pickedQuantity: 0,
            packedQuantity: 0,
            fulfillmentOrderLineId: 'fl-1',
            authoritativeRemainingQuantity: 1)
      ],
    );
