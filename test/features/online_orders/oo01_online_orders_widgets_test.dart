import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nytroz_pos/features/fulfilment_pickup/domain/entities/pos_online_order.dart';
import 'package:nytroz_pos/features/fulfilment_pickup/presentation/providers/pos_online_orders_provider.dart';
import 'package:nytroz_pos/features/fulfilment_pickup/presentation/widgets/oo01_online_orders_widgets.dart';

void main() {
  testWidgets('refresh preserves list position and scroll offset', (tester) async {
    final items = List.generate(20, (index) => PosOnlineOrder.fromJson({
      'id': 'order-$index',
      'orderNumber': 'ORDER-$index',
    }));
    Future<void> render(bool loading) => tester.pumpWidget(MaterialApp(
      home: Scaffold(body: Oo01OrderResults(
        state: PosOnlineOrdersState(items: items, isLoading: loading),
        onOpen: (_) {},
        onRetry: () {},
      )),
    ));
    await render(false);
    await tester.drag(find.byType(ListView), const Offset(0, -200));
    await tester.pumpAndSettle();
    final origin = tester.getTopLeft(find.byType(ListView));
    final scroll = tester.state<ScrollableState>(find.byType(Scrollable));
    final offset = scroll.position.pixels;
    await render(true);
    expect(tester.getTopLeft(find.byType(ListView)), origin);
    expect(scroll.position.pixels, offset);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    await render(false);
    expect(tester.getTopLeft(find.byType(ListView)), origin);
    expect(scroll.position.pixels, offset);
    expect(tester.takeException(), isNull);
  });

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

  testWidgets('summary card tap selects and toggles status filter',
      (tester) async {
    String? selected;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              return SizedBox(
                width: 1200,
                child: Oo01SummaryRow(
                  summary: const PosOnlineOrderSummary(
                    total: 0,
                    pending: 0,
                    preparing: 0,
                    ready: 6,
                    overdue: 7,
                    newOrders: 0,
                    collected: 2,
                    cancelled: 0,
                  ),
                  selectedStatus: selected,
                  onStatusSelected: (value) {
                    setState(() => selected = value);
                  },
                ),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('Ready'));
    await tester.pump();
    expect(selected, Oo01SummaryRow.statusReady);

    await tester.tap(find.text('Delayed'));
    await tester.pump();
    expect(selected, Oo01SummaryRow.statusDelayed);

    await tester.tap(find.text('Delayed'));
    await tester.pump();
    expect(selected, isNull);
  });

  testWidgets('empty status filter state names the selected bucket',
      (tester) async {
    const state = PosOnlineOrdersState(status: 'READY');
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
    expect(find.text('No Ready orders right now.'), findsOneWidget);
  });
}
