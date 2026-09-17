import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nytroz_pos/core/access/pos_access_codes.dart';

import '../helpers/online_order_test_harness.dart';

void main() {
  group('online order start fulfilment', () {
    Future<void> pumpDetail(
      WidgetTester tester, {
      required String status,
      required bool canStart,
    }) async {
      final permissions = [
        PosPermissionCodes.accessOnlineOrders,
        PosPermissionCodes.viewOnlineOrders,
        if (canStart) PosPermissionCodes.startOnlineOrderFulfillment,
      ];
      await tester.pumpWidget(
        detailHarness(
          permissions: permissions,
          status: status,
        ),
      );
      await tester.pump();
    }

    testWidgets('eligible Start is visible with the exact permission',
        (tester) async {
      await pumpDetail(tester, status: 'PENDING', canStart: true);
      expect(find.byKey(const Key('oo02-start-fulfilment')), findsOneWidget);
    });

    testWidgets('eligible Start is absent without the exact permission',
        (tester) async {
      await pumpDetail(tester, status: 'PENDING', canStart: false);
      expect(find.byKey(const Key('oo02-start-fulfilment')), findsNothing);
    });

    for (final status in [
      'PICKING',
      'PICKED',
      'PACKED',
      'READY',
      'FULFILLED',
      'CANCELLED',
    ]) {
      testWidgets('Start is absent for lifecycle $status', (tester) async {
        await pumpDetail(tester, status: status, canStart: true);
        expect(find.byKey(const Key('oo02-start-fulfilment')), findsNothing);
      });
    }
  });
}
