import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nytroz_pos/features/fulfilment_pickup/domain/entities/pos_online_order.dart';
import 'package:nytroz_pos/features/fulfilment_pickup/presentation/widgets/picking/pick_item_workspace.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('tablet landscape renders selected line and target actions',
      (tester) async {
    await _pump(tester, size: const Size(1280, 720));

    expect(find.text('Pick: Long Sleeve Product'), findsOneWidget);
    expect(find.text('1 of 3'), findsOneWidget);
    expect(find.byKey(const Key('scanner-ready-card')), findsOneWidget);
    expect(find.byKey(const Key('enter-barcode-manually')), findsOneWidget);
    expect(find.byKey(const Key('mark-as-picked')), findsOneWidget);
    expect(find.text('Next Product'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'quantity controls enforce callbacks and selected line is excluded',
      (tester) async {
    var decreased = 0;
    var increased = 0;
    await _pump(
      tester,
      onDecrease: () => decreased++,
      onIncrease: () => increased++,
    );

    await tester.tap(find.byKey(const Key('decrease-pick-quantity')));
    await tester.tap(find.byKey(const Key('increase-pick-quantity')));
    expect(decreased, 1);
    expect(increased, 1);
    expect(find.textContaining('Long Sleeve Product'), findsWidgets);
    expect(find.text('2 pending'), findsOneWidget);
  });

  testWidgets('permission reflow removes scan manual and report actions',
      (tester) async {
    await _pump(tester, canScan: false, canManual: false, canReport: false);

    expect(find.byKey(const Key('enter-barcode-manually')), findsNothing);
    expect(find.byKey(const Key('cant-find-item')), findsNothing);
    expect(find.text('Barcode verification permission is required.'),
        findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('brand primary adapts to a pink-like tenant theme',
      (tester) async {
    const pink = Color(0xffd81b60);
    await _pump(tester, primary: pink);

    final indicator = tester.widget<CircularProgressIndicator>(
        find.byType(CircularProgressIndicator).last);
    expect(indicator.color, pink);
  });

  testWidgets('missing optional image and location render safely',
      (tester) async {
    await _pump(tester, missingOptionalData: true);
    expect(find.text('Location unavailable'), findsOneWidget);
    expect(find.byIcon(Icons.inventory_2_outlined), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  group('OO-04B tablet landscape layout fit (no scroll / no overflow)', () {
    final overflowMessages = <String>[];

    setUp(() {
      overflowMessages.clear();
      final previous = FlutterError.onError;
      FlutterError.onError = (details) {
        final text = details.toString();
        if (text.contains('overflowed') || text.contains('OVERFLOWED')) {
          overflowMessages.add(text.split('\n').first);
        }
        previous?.call(details);
      };
      addTearDown(() => FlutterError.onError = previous);
    });

    for (final size in const [
      Size(1280, 800), // Pixel Tablet landscape
      Size(1180, 820), // Tablet landscape
      Size(1100, 700), // Compact tablet landscape
    ]) {
      testWidgets(
          '${size.width.toInt()}x${size.height.toInt()} fits with no overflow and all critical controls visible',
          (tester) async {
        await _pump(tester, size: size);

        expect(overflowMessages, isEmpty, reason: overflowMessages.join(' | '));
        expect(tester.takeException(), isNull);

        // Whole-page and internal card scrolling must be NONE
        expect(find.byType(SingleChildScrollView), findsNothing);
        expect(find.byType(ListView), findsNothing);

        // Critical controls visible:
        expect(find.byKey(const Key('back-to-pick-items')), findsOneWidget);
        expect(find.text('Pick: Long Sleeve Product'), findsOneWidget);
        expect(find.byKey(const Key('scanner-ready-card')), findsOneWidget);
        expect(find.byKey(const Key('decrease-pick-quantity')), findsOneWidget);
        expect(find.byKey(const Key('increase-pick-quantity')), findsOneWidget);
        expect(find.text('Picked'), findsWidgets);
        expect(find.text('Remaining'), findsWidgets);
        expect(find.byKey(const Key('mark-as-picked')), findsOneWidget);
        expect(find.text('Order Progress'), findsOneWidget);
        expect(find.byKey(const Key('cant-find-item')), findsOneWidget);
        expect(find.byKey(const Key('pick-next-item')), findsOneWidget);
      });
    }

    testWidgets('empty pending items collapse naturally without overflow',
        (tester) async {
      await _pump(
        tester,
        size: const Size(1100, 700),
        singleItemOnly: true,
      );

      expect(overflowMessages, isEmpty, reason: overflowMessages.join(' | '));
      expect(tester.takeException(), isNull);
      expect(find.byType(SingleChildScrollView), findsNothing);
      expect(find.text('0 pending'), findsOneWidget);
      expect(find.text('No other pending items'), findsOneWidget);
      expect(find.byKey(const Key('mark-as-picked')), findsOneWidget);
    });

    testWidgets('extreme long strings render without overflow or clipping',
        (tester) async {
      await _pump(
        tester,
        size: const Size(1100, 700),
        longStrings: true,
      );

      expect(overflowMessages, isEmpty, reason: overflowMessages.join(' | '));
      expect(tester.takeException(), isNull);
    });
  });
}

Future<void> _pump(
  WidgetTester tester, {
  Size size = const Size(1280, 720),
  Color primary = const Color(0xffff6a00),
  bool canScan = true,
  bool canManual = true,
  bool canReport = true,
  bool missingOptionalData = false,
  bool singleItemOnly = false,
  bool longStrings = false,
  VoidCallback? onDecrease,
  VoidCallback? onIncrease,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final order = _order(
    missingOptionalData: missingOptionalData,
    singleItemOnly: singleItemOnly,
    longStrings: longStrings,
  );
  await tester.pumpWidget(MaterialApp(
    theme: ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: primary).copyWith(
        primary: primary,
      ),
      useMaterial3: true,
    ),
    home: Scaffold(
      body: PickItemWorkspace(
        order: order,
        line: order.lines.first,
        quantity: 1,
        verifiedBarcode: 'CURRENT-001',
        verificationMessage:
            'Barcode verified. Confirm the quantity to continue.',
        isSubmitting: false,
        canScan: canScan,
        canManual: canManual,
        canPick: true,
        canReport: canReport,
        onBack: () {},
        onDecrease: onDecrease,
        onIncrease: onIncrease,
        onPick: () {},
        onScan: () {},
        onManual: () {},
        onIssue: () {},
        onSelectLine: (_) {},
        onReviewPack: null,
      ),
    ),
  ));
  await tester.pump();
}

PosPickingOrder _order({
  required bool missingOptionalData,
  bool singleItemOnly = false,
  bool longStrings = false,
}) =>
    PosPickingOrder(
      orderId: 'order-1',
      orderNumber: longStrings
          ? 'ORDER-EXTRAORDINARILY-LONG-IDENTIFIER-999999999'
          : 'ORDER-001',
      fulfillmentOrderId: 'fulfilment-1',
      fulfillmentNumber: 'FUL-001',
      status: 'PICKING',
      assignedToName: longStrings
          ? 'Picker With An Exceptionally Lengthy Full Legal Name'
          : 'Authenticated Picker',
      customerName: longStrings
          ? 'Customer With A Super Incredibly Long Enterprise Business Entity Name'
          : 'Customer With A Long Display Name',
      totalLines: singleItemOnly ? 1 : 3,
      pickedLines: 0,
      totalUnits: singleItemOnly ? 2 : 4,
      pickedUnits: 0,
      remainingUnits: singleItemOnly ? 2 : 4,
      fulfillmentVersion: 7,
      lines: [
        PosPickingLine(
          id: 'line-a',
          lineNumber: 1,
          productName: longStrings
              ? 'Ultra High Performance Organic Cotton Heavyweight Long Sleeve Workwear Jacket With Thermal Insulation'
              : 'Long Sleeve Product',
          requestedQuantity: 2,
          pickedQuantity: 0,
          status: 'PICKING',
          barcode: 'CURRENT-001',
          sku: 'SKU-001',
          variantName: longStrings
              ? 'Extra Extra Large / Navy Blue Heather Diamond Weave'
              : 'Large / Blue',
          locationCode: missingOptionalData
              ? null
              : (longStrings ? 'WAREHOUSE-B-BAY-12-SHELF-4-BIN-9' : 'MAIN-01'),
          locationName: missingOptionalData
              ? null
              : (longStrings
                  ? 'Central Distribution Facility Main Storage Warehouse North Wing'
                  : 'Main Inventory'),
        ),
        if (!singleItemOnly) ...[
          const PosPickingLine(
            id: 'line-b',
            lineNumber: 2,
            productName: 'Next Product',
            requestedQuantity: 1,
            pickedQuantity: 0,
            status: 'PENDING',
            barcode: 'NEXT-002',
            locationName: 'Stock Room',
          ),
          const PosPickingLine(
            id: 'line-c',
            lineNumber: 3,
            productName: 'Final Product',
            requestedQuantity: 1,
            pickedQuantity: 0,
            status: 'PENDING',
            barcode: 'FINAL-003',
          ),
        ],
      ],
    );
