import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nytroz_pos/core/access/pos_access_codes.dart';
import 'package:nytroz_pos/core/storage/app_secure_storage.dart';
import 'package:nytroz_pos/features/auth/data/datasources/auth_session_storage.dart';
import 'package:nytroz_pos/features/auth/domain/entities/auth_session.dart';
import 'package:nytroz_pos/features/auth/presentation/providers/session_provider.dart';
import 'package:nytroz_pos/features/fulfilment_pickup/domain/entities/pos_online_order.dart';
import 'package:nytroz_pos/features/fulfilment_pickup/presentation/providers/pos_online_orders_provider.dart';
import 'package:nytroz_pos/features/fulfilment_pickup/presentation/screens/pos_pick_item_screen.dart';
import 'package:nytroz_pos/features/fulfilment_pickup/presentation/widgets/picking/pick_item_barcode_entry_dialog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PickItemBarcodeEntryDialog lifecycle', () {
    testWidgets('TEST 01 open manual barcode UI without exception',
        (tester) async {
      await _pumpDialogHost(tester);
      await tester.tap(find.text('Open Manual'));
      await tester.pumpAndSettle();
      expect(find.text('Enter Barcode Manually'), findsOneWidget);
      expect(find.byKey(const Key('manual-barcode-input')), findsOneWidget);
      _expectNoDependentsAssertion(tester);
    });

    testWidgets('TEST 02-03 type numeric digits without framework assertion',
        (tester) async {
      await _pumpDialogHost(tester);
      await tester.tap(find.text('Open Manual'));
      await tester.pumpAndSettle();
      await tester.enterText(
          find.byKey(const Key('manual-barcode-input')), '1');
      await tester.pump();
      await tester.enterText(
          find.byKey(const Key('manual-barcode-input')), '1234567890');
      await tester.pump();
      _expectNoDependentsAssertion(tester);
    });

    testWidgets('TEST 04 cancel closes cleanly', (tester) async {
      await _pumpDialogHost(tester);
      await tester.tap(find.text('Open Manual'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(find.text('Enter Barcode Manually'), findsNothing);
      _expectNoDependentsAssertion(tester);
    });

    testWidgets('TEST 05 submit empty returns empty string to caller',
        (tester) async {
      String? result = 'unset';
      await _pumpDialogHost(tester, onResult: (value) => result = value);
      await tester.tap(find.text('Open Manual'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Verify'));
      await tester.pumpAndSettle();
      expect(result, '');
      _expectNoDependentsAssertion(tester);
    });

    testWidgets('TEST 08 open close reopen works repeatedly', (tester) async {
      await _pumpDialogHost(tester);
      for (var i = 0; i < 3; i++) {
        await tester.tap(find.text('Open Manual'));
        await tester.pumpAndSettle();
        await tester.enterText(
            find.byKey(const Key('manual-barcode-input')), 'ABC-$i');
        await tester.tap(find.text('Verify'));
        await tester.pumpAndSettle();
      }
      expect(find.text('Enter Barcode Manually'), findsNothing);
      _expectNoDependentsAssertion(tester);
    });

    testWidgets('TEST 09 open then rapidly cancel', (tester) async {
      await _pumpDialogHost(tester);
      await tester.tap(find.text('Open Manual'));
      await tester.pump();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      _expectNoDependentsAssertion(tester);
    });
  });

  group('PosPickItemScreen manual barcode', () {
    testWidgets('TEST 06 invalid barcode shows mismatch without crash',
        (tester) async {
      await _pumpScreen(tester);
      await tester.tap(find.byKey(const Key('enter-barcode-manually')));
      await tester.pumpAndSettle();
      await tester.enterText(
          find.byKey(const Key('manual-barcode-input')), 'WRONG-BARCODE');
      await tester.tap(find.text('Verify'));
      await tester.pumpAndSettle();
      expect(find.text('Barcode does not match the selected item.'),
          findsOneWidget);
      expect(find.byKey(const Key('manual-barcode-input')), findsNothing);
      _expectNoDependentsAssertion(tester);
    });

    testWidgets(
        'TEST 07+25 valid barcode verifies; wrong selected-item rejected',
        (tester) async {
      await _pumpScreen(tester);
      await tester.tap(find.byKey(const Key('enter-barcode-manually')));
      await tester.pumpAndSettle();
      await tester.enterText(
          find.byKey(const Key('manual-barcode-input')), 'OTHER-LINE-002');
      await tester.tap(find.text('Verify'));
      await tester.pumpAndSettle();
      expect(find.text('Barcode does not match the selected item.'),
          findsOneWidget);

      await tester.tap(find.byKey(const Key('enter-barcode-manually')));
      await tester.pumpAndSettle();
      await tester.enterText(
          find.byKey(const Key('manual-barcode-input')), 'CURRENT-001');
      await tester.tap(find.text('Verify'));
      await tester.pumpAndSettle();
      expect(
        find.text('Barcode verified. Confirm the quantity to continue.'),
        findsOneWidget,
      );
      expect(find.byKey(const Key('manual-barcode-input')), findsNothing);
      _expectNoDependentsAssertion(tester);
    });

    testWidgets('TEST 15 manual entry absent without permission',
        (tester) async {
      await _pumpScreen(tester, includeManual: false, includeScan: false);
      expect(find.byKey(const Key('enter-barcode-manually')), findsNothing);
      expect(find.text('Barcode verification permission is required.'),
          findsOneWidget);
      _expectNoDependentsAssertion(tester);
    });

    testWidgets('TEST 11 API failure after Mark as Picked keeps screen stable',
        (tester) async {
      await _pumpScreen(tester, pickFailsWith: 500);
      await tester.tap(find.byKey(const Key('enter-barcode-manually')));
      await tester.pumpAndSettle();
      await tester.enterText(
          find.byKey(const Key('manual-barcode-input')), 'CURRENT-001');
      await tester.tap(find.text('Verify'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('mark-as-picked')));
      await tester.pumpAndSettle();
      expect(find.byType(PosPickItemScreen), findsOneWidget);
      _expectNoDependentsAssertion(tester);
    });

    testWidgets('TEST 12 HTTP 409 after Mark as Picked keeps screen stable',
        (tester) async {
      await _pumpScreen(tester, pickFailsWith: 409);
      await tester.tap(find.byKey(const Key('enter-barcode-manually')));
      await tester.pumpAndSettle();
      await tester.enterText(
          find.byKey(const Key('manual-barcode-input')), 'CURRENT-001');
      await tester.tap(find.text('Verify'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('mark-as-picked')));
      await tester.pumpAndSettle();
      expect(find.byType(PosPickItemScreen), findsOneWidget);
      _expectNoDependentsAssertion(tester);
    });
  });
}

void _expectNoDependentsAssertion(WidgetTester tester) {
  final pending = tester.takeException();
  if (pending != null) {
    fail('Unexpected Flutter exception: $pending');
  }
}

Future<void> _pumpDialogHost(
  WidgetTester tester, {
  void Function(String? value)? onResult,
}) async {
  final errors = <Object>[];
  final previous = FlutterError.onError;
  FlutterError.onError = (details) {
    errors.add(details.exception);
    previous?.call(details);
  };
  addTearDown(() {
    FlutterError.onError = previous;
    for (final error in errors) {
      expect(
        error.toString().contains('_dependents.isEmpty'),
        isFalse,
        reason: 'FlutterError.onError captured: $error',
      );
    }
  });

  await tester.pumpWidget(MaterialApp(
    home: Builder(
      builder: (context) => Scaffold(
        body: FilledButton(
          onPressed: () async {
            final value = await PickItemBarcodeEntryDialog.show(
              context,
              scanned: false,
            );
            onResult?.call(value);
          },
          child: const Text('Open Manual'),
        ),
      ),
    ),
  ));
}

Future<void> _pumpScreen(
  WidgetTester tester, {
  bool includeManual = true,
  bool includeScan = true,
  int? pickFailsWith,
}) async {
  final errors = <Object>[];
  final previous = FlutterError.onError;
  FlutterError.onError = (details) {
    errors.add(details.exception);
    previous?.call(details);
  };
  addTearDown(() {
    FlutterError.onError = previous;
    for (final error in errors) {
      expect(
        error.toString().contains('_dependents.isEmpty'),
        isFalse,
        reason: 'FlutterError.onError captured: $error',
      );
    }
  });

  tester.view.physicalSize = const Size(1280, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final permissions = <String>[
    PosPermissionCodes.accessOnlineOrders,
    PosPermissionCodes.viewOnlineOrders,
    PosPermissionCodes.viewOnlineOrderPicking,
    PosPermissionCodes.pickOnlineOrderItem,
    PosPermissionCodes.reportOnlineOrderPickingIssue,
    if (includeScan) PosPermissionCodes.scanOnlineOrderItem,
    if (includeManual) PosPermissionCodes.manuallyEnterOnlineOrderItem,
  ];

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authSessionProvider.overrideWith(
          (ref) => _PresetAuthSessionNotifier(
            AuthSession(
              accessToken: 'test-token',
              userId: 'user-1',
              userDisplayName: 'Cashier',
              permissionCodes: permissions,
            ),
          ),
        ),
        posPickingOrderProvider.overrideWith((ref, orderId) async => _order),
        if (pickFailsWith != null)
          posPickingActionsProvider.overrideWith(
            (ref, orderId) => _FailingPickActions(ref, orderId, pickFailsWith),
          ),
      ],
      child: const MaterialApp(
        home: Scaffold(
          body: PosPickItemScreen(orderId: 'order-1', lineId: 'line-a'),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

class _FailingPickActions extends PosPickingActions {
  _FailingPickActions(super.ref, super.orderId, this.statusCode);
  final int statusCode;

  @override
  Future<PosFulfillmentCommandResult> pick(
    PosPickingOrder order,
    PosPickingLine line, {
    required bool scanned,
    required String barcode,
    double? quantity,
  }) async {
    throw DioException(
      requestOptions: RequestOptions(path: '/pick'),
      response: Response(
        requestOptions: RequestOptions(path: '/pick'),
        statusCode: statusCode,
      ),
      type: DioExceptionType.badResponse,
    );
  }
}

class _PresetAuthSessionNotifier extends AuthSessionNotifier {
  _PresetAuthSessionNotifier(AuthSession session) : super(_TestStorage()) {
    state = session;
  }
}

class _TestStorage extends AuthSessionStorage {
  _TestStorage() : super(const AppSecureStorage(FlutterSecureStorage()));

  @override
  Future<AuthSession?> read() async => null;

  @override
  Future<void> save(AuthSession session) async {}

  @override
  Future<void> clear() async {}
}

final _order = PosPickingOrder(
  orderId: 'order-1',
  orderNumber: 'ORDER-001',
  fulfillmentOrderId: 'fulfilment-1',
  fulfillmentNumber: 'FUL-001',
  status: 'PICKING',
  assignedToName: 'Picker',
  customerName: 'Customer',
  totalLines: 2,
  pickedLines: 0,
  totalUnits: 3,
  pickedUnits: 0,
  remainingUnits: 3,
  fulfillmentVersion: 7,
  lines: const [
    PosPickingLine(
      id: 'line-a',
      lineNumber: 1,
      productName: 'Long Sleeve Product',
      requestedQuantity: 2,
      pickedQuantity: 0,
      status: 'PICKING',
      barcode: 'CURRENT-001',
      sku: 'SKU-001',
      variantName: 'Large / Blue',
      locationCode: 'MAIN-01',
      locationName: 'Main Inventory',
    ),
    PosPickingLine(
      id: 'line-b',
      lineNumber: 2,
      productName: 'Next Product',
      requestedQuantity: 1,
      pickedQuantity: 0,
      status: 'PENDING',
      barcode: 'OTHER-LINE-002',
      locationName: 'Stock Room',
    ),
  ],
);
