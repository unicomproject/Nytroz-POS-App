import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nytroz_pos/core/access/pos_access_codes.dart';
import 'package:nytroz_pos/features/fulfilment_pickup/presentation/widgets/picking/picking_item_card.dart';
import 'package:nytroz_pos/features/fulfilment_pickup/presentation/widgets/picking/picking_items_list.dart';

import '../helpers/online_order_test_fixtures.dart';
import '../helpers/online_order_test_harness.dart';

void main() {
  group('OO04 picking items layout', () {
    testWidgets(
        'OO04 target three lines and scanner fit without list scrolling',
        (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(1180, 820);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(pickingHarness(
        permissions: const [
          PosPermissionCodes.pickOnlineOrderItem,
          PosPermissionCodes.scanOnlineOrderItem,
        ],
        child: const SizedBox(
          width: 740,
          height: 470,
          child: PickingItemsList(
            orderId: 'order-1',
            order: testPickingOrder,
          ),
        ),
      ));

      expect(find.byType(ListView), findsNothing);
      expect(find.byType(PickingItemCard), findsNWidgets(3));
      expect(find.byKey(const Key('scan-item-barcode')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
