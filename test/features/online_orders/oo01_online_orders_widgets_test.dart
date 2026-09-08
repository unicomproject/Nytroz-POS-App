import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nytroz_pos/features/fulfilment_pickup/domain/entities/pos_online_order.dart';
import 'package:nytroz_pos/features/fulfilment_pickup/presentation/providers/pos_online_orders_provider.dart';
import 'package:nytroz_pos/features/fulfilment_pickup/presentation/widgets/oo01_online_orders_widgets.dart';

void main() {
  testWidgets('OO01 header and exactly six summary labels are visible',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 1200,
            child: Column(
              children: [
                Oo01Header(
                  searchController: TextEditingController(),
                  onSearch: (_) {},
                ),
                const Oo01SummaryRow(
                  summary: PosOnlineOrderSummary(
                    total: 0,
                    pending: 1,
                    preparing: 2,
                    ready: 3,
                    overdue: 4,
                    newOrders: 1,
                    collected: 5,
                    cancelled: 6,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    expect(find.text('Online Orders'), findsOneWidget);
    expect(find.text('Click & Collect orders from your online store'),
        findsOneWidget);
    for (final label in [
      'New',
      'Preparing',
      'Ready',
      'Delayed',
      'Collected',
      'Cancelled'
    ]) {
      expect(find.text(label), findsOneWidget);
    }
    expect(find.text('Filters'), findsNothing);
    expect(find.text('Orders queue'), findsNothing);
    expect(find.text('Sort by'), findsNothing);
  });

  testWidgets('empty search state is specific and has no pagination',
      (tester) async {
    const state = PosOnlineOrdersState(query: 'missing');
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
    expect(find.text('No orders match your search.'), findsOneWidget);
    expect(find.textContaining('Showing'), findsNothing);
    expect(find.textContaining('Page '), findsNothing);
  });
}
