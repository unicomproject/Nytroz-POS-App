import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nytroz_pos/core/access/pos_access_codes.dart';
import 'package:nytroz_pos/features/fulfilment_pickup/presentation/screens/pos_online_order_picking_screen.dart';
import 'package:nytroz_pos/features/fulfilment_pickup/presentation/widgets/picking/picking_header.dart';
import 'package:nytroz_pos/features/fulfilment_pickup/presentation/widgets/picking/picking_item_card.dart';

import '../helpers/online_order_test_fixtures.dart';
import '../helpers/online_order_test_harness.dart';

void main() {
  group('OO04 picking workspace layout', () {
    testWidgets(
        'OO04 complete three-line center fits one fixed landscape viewport',
        (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(1180, 820);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(pickingHarness(
        permissions: const [
          PosPermissionCodes.pickOnlineOrderItem,
          PosPermissionCodes.scanOnlineOrderItem,
          PosPermissionCodes.addOnlineOrderPickingNote,
        ],
        child: SizedBox(
          width: 1132,
          height: 620,
          child: Column(children: const [
            PickingHeader(order: testPickingOrder, onBack: testNoop),
            SizedBox(height: 10),
            Expanded(
              child: PickingWorkspace(
                orderId: 'order-1',
                order: testPickingOrder,
                onReviewPack: testNoop,
              ),
            ),
          ]),
        ),
      ));

      expect(find.byType(SingleChildScrollView), findsNothing);
      expect(find.byType(PickingItemCard), findsNWidgets(3));
      expect(find.byKey(const Key('scan-item-barcode')), findsOneWidget);
      expect(find.byKey(const Key('add-picking-note')), findsOneWidget);
      expect(find.byKey(const Key('review-pack-button')), findsOneWidget);
      expect(find.text('Pick all items to continue'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
