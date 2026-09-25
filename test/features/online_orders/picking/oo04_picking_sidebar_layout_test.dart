import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nytroz_pos/core/access/pos_access_codes.dart';
import 'package:nytroz_pos/features/fulfilment_pickup/presentation/widgets/picking/picking_order_sidebar.dart';

import '../helpers/online_order_test_fixtures.dart';
import '../helpers/online_order_test_harness.dart';

void main() {
  group('OO04 picking sidebar layout', () {
    testWidgets('OO04 fixed landscape keeps permission actions in-view',
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
        child: const SizedBox(
          width: 420,
          height: 430,
          child: PickingOrderSidebar(
            order: testPickingOrder,
            orderId: 'order-1',
          ),
        ),
      ));

      expect(find.byType(SingleChildScrollView), findsNothing);
      expect(find.byKey(const Key('add-picking-note')), findsOneWidget);
      expect(find.byKey(const Key('review-pack-button')), findsOneWidget);
      expect(find.text('Pick all items to continue'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
