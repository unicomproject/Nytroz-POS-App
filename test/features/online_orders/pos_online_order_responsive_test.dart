import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nytroz_pos/features/fulfilment_pickup/domain/entities/pos_online_order.dart';
import 'package:nytroz_pos/features/fulfilment_pickup/presentation/providers/pos_online_orders_provider.dart';
import 'package:nytroz_pos/features/fulfilment_pickup/presentation/screens/online_order_detail_screen.dart';
import 'package:nytroz_pos/features/fulfilment_pickup/presentation/screens/ready_for_collection_screen.dart';
import 'package:nytroz_pos/features/fulfilment_pickup/presentation/screens/review_pack_screen.dart';
import 'package:nytroz_pos/features/fulfilment_pickup/presentation/widgets/oo01_online_orders_widgets.dart';
import 'package:nytroz_pos/features/fulfilment_pickup/presentation/widgets/online_order_ui.dart';
import 'package:nytroz_pos/features/fulfilment_pickup/presentation/widgets/picking_widgets.dart';
import 'package:nytroz_pos/features/fulfilment_pickup/presentation/widgets/start_fulfilment_dialog.dart';

void main() {
  const viewportCases = <String, Size>{
    'desktop': Size(1440, 900),
    'tablet landscape': Size(1180, 820),
    'tablet portrait': Size(800, 1100),
    'phone': Size(600, 900),
    'small phone': Size(390, 844),
  };

  group('OO01 queue responsive contract', () {
    for (final entry in viewportCases.entries) {
      testWidgets('${entry.key} renders without overflow', (tester) async {
        await _pumpAt(
          tester,
          entry.value,
          Oo01OrderResults(
            state: _queueState,
            onOpen: (_) {},
            onRetry: () {},
          ),
        );

        expect(tester.takeException(), isNull);
        expect(find.byType(Oo01OrderCard), findsOneWidget);
      });
    }
  });

  group('OO02 detail responsive contract', () {
    testWidgets('target landscape uses a fixed non-scrollable body',
        (tester) async {
      await _pumpAt(
        tester,
        const Size(1280, 800),
        const OnlineOrderDetailScreen(
          state: PosOnlineOrdersState(selected: _detail),
          showBackButton: true,
        ),
      );

      expect(
          find.byKey(const Key('oo02-fixed-landscape-body')), findsOneWidget);
      expect(find.byType(SingleChildScrollView), findsNothing);
      expect(find.textContaining(_longProduct), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    for (final entry in viewportCases.entries) {
      testWidgets('${entry.key} keeps long authoritative content reachable',
          (tester) async {
        await _pumpAt(
          tester,
          entry.value,
          const OnlineOrderDetailScreen(
            state: PosOnlineOrdersState(selected: _detail),
            showBackButton: true,
          ),
        );

        expect(tester.takeException(), isNull);
        expect(find.textContaining(_longCustomer), findsOneWidget);
        // The default test session has no start permission. The action must be
        // completely absent so the header naturally reflows.
        expect(find.byKey(const Key('oo02-start-fulfilment')), findsNothing);
        expect(find.byKey(const Key('oo02-order-icon')), findsOneWidget);
      });
    }
  });

  group('OO03 start fulfilment confirmation', () {
    for (final entry in viewportCases.entries) {
      testWidgets('${entry.key} keeps summary and actions reachable',
          (tester) async {
        await _pumpDialogLauncher(tester, entry.value);
        if (entry.value.width < OnlineOrderUi.phoneBreakpoint) {
          expect(find.byType(BottomSheet), findsOneWidget);
        } else {
          expect(find.byType(Dialog), findsOneWidget);
        }
        expect(find.byType(SingleChildScrollView), findsNothing);
        expect(find.byKey(const Key('oo03-dialog-icon')), findsOneWidget);
        expect(find.byKey(const Key('oo03-summary-card')), findsOneWidget);
        expect(
          find.text('You are about to start picking this order.\n'
              'This order will be assigned to you.'),
          findsOneWidget,
        );
        expect(find.text('Yes, Start Fulfilment'), findsOneWidget);
        expect(find.text('Cancel'), findsOneWidget);
        expect(find.textContaining(_longCustomer), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  });

  group('OO04 picking responsive contract', () {
    for (final entry in viewportCases.entries) {
      testWidgets('${entry.key} keeps picking controls overflow-free',
          (tester) async {
        await _pumpAt(
          tester,
          entry.value,
          ListView(
            padding: const EdgeInsets.all(8),
            children: const [
              PickingHeader(order: _picking, onBack: _noop),
              FulfilmentStepper(status: 'PICKING'),
              PickingItemCard(line: _pickingLine),
              PickingOrderSidebar(order: _picking),
              PickQuantityPanel(requested: 123456, picked: 123455),
            ],
          ),
        );

        expect(tester.takeException(), isNull);
        expect(find.textContaining(_longProduct), findsWidgets);
      });
    }
  });

  group('OO05 review and pack responsive contract', () {
    for (final entry in viewportCases.entries) {
      testWidgets('${entry.key} renders the review workspace without overflow',
          (tester) async {
        await _pumpAt(
          tester,
          entry.value,
          const ReviewPackScreen(order: _pickedOrder),
        );

        expect(tester.takeException(), isNull);
        expect(find.byType(PickedItemsReviewList), findsOneWidget);
        expect(find.byType(PackingReadinessSummary), findsOneWidget);
      });
    }
  });

  group('OO06 ready for collection responsive contract', () {
    for (final entry in viewportCases.entries) {
      testWidgets('${entry.key} renders ready state without overflow',
          (tester) async {
        await _pumpAt(
          tester,
          entry.value,
          const ReadyForCollectionScreen(order: _readyOrder, onBack: _noop),
        );

        expect(tester.takeException(), isNull);
        expect(find.byType(ReadyForCollectionHero), findsOneWidget);
        expect(find.byType(ReadyOrderSummary), findsOneWidget);
      });
    }
  });
}

Future<void> _pumpAt(WidgetTester tester, Size size, Widget child) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);
  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(home: Scaffold(body: child)),
    ),
  );
  await tester.pump();
}

Future<void> _pumpDialogLauncher(WidgetTester tester, Size size) async {
  await _pumpAt(
    tester,
    size,
    Builder(
      builder: (context) => TextButton(
        onPressed: () => StartFulfilmentDialog.show(
          context,
          _detail,
          onConfirm: () async => true,
        ),
        child: const Text('Open'),
      ),
    ),
  );
  await tester.tap(find.text('Open'));
  await tester.pumpAndSettle();
}

void _noop() {}

const _longCustomer =
    'A customer with an exceptionally long production display name for layout verification';
const _longProduct =
    'Extra long product title with multiple descriptive words and production metadata';

const _order = PosOnlineOrder(
  id: 'order-1',
  orderNumber: 'CLICK-COLLECT-ORDER-2026-000000000001',
  customerName: _longCustomer,
  customerPhone: '+9477000000000000000000',
  status: 'ACCEPTED',
  statusLabel: 'Accepted and awaiting fulfilment',
  paymentStatus: 'PAID_ONLINE',
  currencyCode: 'LKR',
  totalAmount: 123456789.99,
  lineCount: 1,
);

const _detailLine = PosOnlineOrderLine(
  id: 'line-1',
  lineNumber: 1,
  productName: _longProduct,
  variantName: 'Extra Small / Limited Edition / Ocean Blue',
  sku: 'SKU-WITH-A-VERY-LONG-PRODUCTION-IDENTIFIER-001',
  quantity: 1,
  unitPrice: 123456789.99,
  lineTotal: 123456789.99,
  pickedQuantity: 0,
  packedQuantity: 0,
);

const _detail = PosOnlineOrderDetail(
  order: _order,
  outletName: 'Development Main Store With A Very Long Outlet Display Name',
  paymentStatus: 'PAID_ONLINE',
  subtotal: 123456789.99,
  discount: 0,
  tax: 0,
  charges: 0,
  paid: 123456789.99,
  balanceDue: 0,
  customerPhone: '+9477000000000000000000',
  lines: [_detailLine],
);

const _queueState = PosOnlineOrdersState(
  items: [_order],
  totalCount: 999999,
  totalPages: 99999,
  page: 99998,
);

const _pickingLine = PosPickingLine(
  id: 'picking-line-1',
  lineNumber: 999,
  productName: _longProduct,
  variantName: 'Extra Small / Limited Edition / Ocean Blue',
  sku: 'SKU-WITH-A-VERY-LONG-PRODUCTION-IDENTIFIER-001',
  barcode: '999999999999999999999999999999',
  requestedQuantity: 123456,
  pickedQuantity: 123455,
  status: 'PICKING',
  locationCode: 'A-VERY-LONG-LOCATION-CODE',
  locationName: 'A very long warehouse location display name',
);

const _picking = PosPickingOrder(
  orderId: 'order-1',
  orderNumber: 'CLICK-COLLECT-ORDER-2026-000000000001',
  fulfillmentOrderId: 'fulfilment-1',
  fulfillmentNumber: 'FULFILMENT-2026-000000000001',
  status: 'PICKING',
  assignedToName: 'A cashier with a long display name',
  customerName: _longCustomer,
  totalLines: 1,
  pickedLines: 0,
  lines: [_pickingLine],
);

const _pickedOrder = PosPickingOrder(
  orderId: 'order-1',
  orderNumber: 'CLICK-COLLECT-ORDER-2026-000000000001',
  fulfillmentOrderId: 'fulfilment-1',
  fulfillmentNumber: 'FULFILMENT-2026-000000000001',
  status: 'PICKED',
  assignedToName: 'A cashier with a long display name',
  customerName: _longCustomer,
  totalLines: 1,
  pickedLines: 1,
  lines: [_pickingLine],
);

const _readyOrder = PosPickingOrder(
  orderId: 'order-1',
  orderNumber: 'CLICK-COLLECT-ORDER-2026-000000000001',
  fulfillmentOrderId: 'fulfilment-1',
  fulfillmentNumber: 'FULFILMENT-2026-000000000001',
  status: 'READY_FOR_COLLECTION',
  assignedToName: 'A cashier with a long display name',
  customerName: _longCustomer,
  totalLines: 1,
  pickedLines: 1,
  lines: [_pickingLine],
);
