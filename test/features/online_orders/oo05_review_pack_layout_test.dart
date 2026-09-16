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
import 'package:nytroz_pos/features/fulfilment_pickup/presentation/screens/review_pack_screen.dart';
import 'package:nytroz_pos/features/fulfilment_pickup/presentation/widgets/picking/picking_item_card.dart';

void main() {
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

  group('OO-05 Review & Pack layout', () {
    for (final size in const [
      Size(1280, 800),
      Size(1180, 820),
      Size(1100, 700),
    ]) {
      testWidgets(
          '${size.width.toInt()}x${size.height.toInt()} fits without overflow',
          (tester) async {
        await _pumpReview(tester, size, order: _packableOrder);

        expect(overflowMessages, isEmpty, reason: overflowMessages.join(' | '));
        expect(tester.takeException(), isNull);
        expect(find.byType(SingleChildScrollView), findsNothing);
        expect(find.text('Review & Pack'), findsOneWidget);
        expect(find.text('2 of 3'), findsOneWidget);
        expect(find.textContaining('Picked Items'), findsOneWidget);
        expect(find.text('Packing Notes'), findsOneWidget);
        expect(find.text('Order Summary'), findsOneWidget);
        expect(find.text('Order Progress'), findsOneWidget);
        expect(find.byKey(const Key('mark-ready-for-collection')), findsOneWidget);
        expect(find.byKey(const Key('back-to-pick-items')), findsOneWidget);
        expect(find.byType(PickingItemCard), findsWidgets);

        final cta = tester.getRect(
          find.byKey(const Key('mark-ready-for-collection')),
        );
        expect(cta.bottom, lessThanOrEqualTo(size.height - 100));
        expect(cta.top, greaterThan(0));
      });
    }

    testWidgets('packing note maxLength is 200', (tester) async {
      await _pumpReview(tester, const Size(1280, 800), order: _packableOrder);
      final field = tester.widget<TextField>(
        find.byKey(const Key('packing-notes-field')),
      );
      expect(field.maxLength, 200);
    });

    testWidgets('CanPack false hides primary mutation CTA', (tester) async {
      await _pumpReview(
        tester,
        const Size(1280, 800),
        order: _incompleteOrder,
      );
      expect(find.byKey(const Key('mark-ready-for-collection')), findsNothing);
      expect(find.byKey(const Key('back-to-pick-items')), findsOneWidget);
    });

    testWidgets('missing packing.pack hides primary CTA', (tester) async {
      await _pumpReview(
        tester,
        const Size(1280, 800),
        order: _packableOrder,
        permissions: const [
          PosPermissionCodes.accessOnlineOrders,
          PosPermissionCodes.viewOnlineOrders,
          PosPermissionCodes.viewOnlineOrderPicking,
          PosPermissionCodes.viewOnlineOrderPacking,
          PosPermissionCodes.markOnlineOrderReady,
        ],
      );
      expect(find.byKey(const Key('mark-ready-for-collection')), findsNothing);
    });

    testWidgets('primary CTA uses theme primary color', (tester) async {
      const primary = Color(0xFFFF6A00);
      await _pumpReview(
        tester,
        const Size(1280, 800),
        order: _packableOrder,
        primary: primary,
      );
      expect(find.byKey(const Key('mark-ready-for-collection')), findsOneWidget);
      final theme = Theme.of(
        tester.element(find.byKey(const Key('mark-ready-for-collection'))),
      );
      expect(theme.colorScheme.primary.value, primary.value);
    });

    testWidgets('Pink-like primary theme still loads Review & Pack',
        (tester) async {
      await _pumpReview(
        tester,
        const Size(1280, 800),
        order: _packableOrder,
        primary: const Color(0xFFE91E63),
      );
      expect(find.text('Review & Pack'), findsOneWidget);
      expect(find.byKey(const Key('mark-ready-for-collection')), findsOneWidget);
    });

    testWidgets('semantic success banner remains semantic green', (tester) async {
      await _pumpReview(tester, const Size(1280, 800), order: _packableOrder);
      expect(find.textContaining('Ready to pack'), findsOneWidget);
    });

    testWidgets('long product name does not overflow', (tester) async {
      await _pumpReview(
        tester,
        const Size(1280, 800),
        order: _longNameOrder,
      );
      expect(overflowMessages, isEmpty, reason: overflowMessages.join(' | '));
    });
  });
}

Future<void> _pumpReview(
  WidgetTester tester,
  Size size, {
  required PosPickingOrder order,
  List<String>? permissions,
  Color primary = const Color(0xFFFF6A00),
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);

  const chrome = 120.0;
  final bodyHeight = size.height - chrome;

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authSessionProvider.overrideWith(
          (ref) => _PresetAuthSessionNotifier(
            AuthSession(
              accessToken: 'test-token',
              userId: 'user-1',
              userDisplayName: 'Cashier',
              permissionCodes: permissions ??
                  const [
                    PosPermissionCodes.accessOnlineOrders,
                    PosPermissionCodes.viewOnlineOrders,
                    PosPermissionCodes.viewOnlineOrderPicking,
                    PosPermissionCodes.viewOnlineOrderPacking,
                    PosPermissionCodes.packOnlineOrder,
                    PosPermissionCodes.markOnlineOrderReady,
                  ],
            ),
          ),
        ),
        posPickingOrderProvider(order.orderId).overrideWith(
          (ref) async => order,
        ),
      ],
      child: MaterialApp(
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: primary).copyWith(
            primary: primary,
          ),
          useMaterial3: true,
        ),
        home: Scaffold(
          body: SizedBox(
            width: size.width,
            height: bodyHeight,
            child: ColoredBox(
              color: const Color(0xFFF7F8FA),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 10, 24, 10),
                child: ReviewPackScreen(order: order, onBackToPickItems: () {}),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
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

const _line = PosPickingLine(
  id: 'line-1',
  lineNumber: 1,
  productName: 'Man City Home Jersey 24/25',
  variantName: 'Size: M • Player: Haaland 9',
  sku: 'MC-L2425-S',
  requestedQuantity: 1,
  pickedQuantity: 1,
  status: 'PICKED',
  locationCode: 'Aisle 12',
  locationName: 'Rack 04',
);

const _packableOrder = PosPickingOrder(
  orderId: 'order-oo05',
  orderNumber: 'EC250526-1001',
  fulfillmentOrderId: 'ful-1',
  fulfillmentNumber: 'FUL-1',
  status: 'PICKING',
  assignedToName: 'Cashier',
  customerName: 'Sarah Johnson',
  outletName: 'Etihad Stadium Store',
  totalLines: 1,
  pickedLines: 1,
  totalUnits: 1,
  pickedUnits: 1,
  remainingUnits: 0,
  canPack: true,
  fulfillmentVersion: 3,
  serverTime: null,
  collectionAt: null,
  lines: [_line],
);

const _incompleteOrder = PosPickingOrder(
  orderId: 'order-incomplete',
  orderNumber: 'EC-INCOMPLETE',
  fulfillmentOrderId: 'ful-2',
  fulfillmentNumber: 'FUL-2',
  status: 'PICKING',
  assignedToName: 'Cashier',
  customerName: 'Customer',
  totalLines: 1,
  pickedLines: 0,
  canPack: false,
  fulfillmentVersion: 2,
  lines: [
    PosPickingLine(
      id: 'line-1',
      lineNumber: 1,
      productName: 'Pending Item',
      requestedQuantity: 2,
      pickedQuantity: 0,
      status: 'PICKING',
    ),
  ],
);

const _longNameOrder = PosPickingOrder(
  orderId: 'order-long',
  orderNumber: 'EC-VERY-LONG-ORDER-NUMBER-0000000000001',
  fulfillmentOrderId: 'ful-3',
  fulfillmentNumber: 'FUL-3',
  status: 'PICKING',
  assignedToName: 'Cashier',
  customerName:
      'Customer With An Extremely Long Display Name That Must Ellipsize',
  outletName:
      'Development Outlet With An Extremely Long Name That Must Ellipsize',
  totalLines: 1,
  pickedLines: 1,
  canPack: true,
  fulfillmentVersion: 4,
  lines: [
    PosPickingLine(
      id: 'line-1',
      lineNumber: 1,
      productName:
          'Extremely Long Product Name That Should Ellipsize Without Overflowing The Review Card Layout',
      variantName: 'Extra Long Variant / Option / Bundle Description',
      sku: 'SKU-VERY-LONG-IDENTIFIER-1234567890',
      requestedQuantity: 1,
      pickedQuantity: 1,
      status: 'PICKED',
      locationName: 'Very Long Location Name That Must Ellipsize Safely',
      locationCode: 'LOC-LONG-CODE',
    ),
  ],
);
