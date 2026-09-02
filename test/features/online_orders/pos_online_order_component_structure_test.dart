import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nytroz_pos/features/fulfilment_pickup/domain/entities/pos_online_order.dart';
import 'package:nytroz_pos/features/fulfilment_pickup/presentation/providers/pos_online_orders_provider.dart';
import 'package:nytroz_pos/features/fulfilment_pickup/presentation/screens/ready_for_collection_screen.dart';
import 'package:nytroz_pos/features/fulfilment_pickup/presentation/widgets/oo01_online_orders_widgets.dart';

void main() {
  const order = PosOnlineOrder(
    id: 'order-1',
    orderNumber: 'CC-0001',
    customerName: 'Nimal',
    status: 'PREPARING',
    statusLabel: 'Preparing',
    paymentStatus: 'PAID',
    currencyCode: 'LKR',
    totalAmount: 2800,
    lineCount: 1,
  );

  testWidgets('OO01 uses the canonical order-card result owner',
      (tester) async {
    const state = PosOnlineOrdersState(
      items: [order],
      totalCount: 1,
      totalPages: 1,
    );

    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1280, 600);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Oo01OrderResults(
            state: state,
            onOpen: (_) {},
            onRetry: () {},
          ),
        ),
      ),
    );

    expect(find.byType(Oo01OrderCard), findsOneWidget);
    expect(find.text('CC-0001'), findsOneWidget);
  });

  testWidgets('OO06 composes ready hero and authoritative summary',
      (tester) async {
    const picking = PosPickingOrder(
      orderId: 'order-1',
      orderNumber: 'CC-0001',
      fulfillmentOrderId: 'fulfilment-1',
      fulfillmentNumber: 'FUL-0001',
      status: 'READY',
      assignedToName: 'Kavin',
      customerName: 'Nimal',
      totalLines: 1,
      pickedLines: 1,
      lines: [],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 1000,
            height: 600,
            child: ReadyForCollectionScreen(
              order: picking,
              onBack: () {},
            ),
          ),
        ),
      ),
    );

    expect(find.byType(ReadyForCollectionHero), findsOneWidget);
    expect(find.byType(ReadyOrderSummary), findsOneWidget);
    expect(find.text('CC-0001'), findsOneWidget);
    expect(find.text('Nimal'), findsOneWidget);
    expect(find.textContaining('ready for Nimal'), findsOneWidget);
  });
}
