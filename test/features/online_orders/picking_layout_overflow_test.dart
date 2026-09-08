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
import 'package:nytroz_pos/features/fulfilment_pickup/presentation/screens/pos_online_order_picking_screen.dart';
import 'package:nytroz_pos/features/fulfilment_pickup/presentation/widgets/picking/picking_header.dart';
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

  group('OO04 picking layout fit (no scroll / no overflow)', () {
    for (final size in const [
      Size(1280, 800), // screenshot-like landscape
      Size(1180, 820), // tablet landscape
      Size(1100, 700), // smaller tablet landscape (still >= 1024 after padding)
    ]) {
      testWidgets(
          '${size.width.toInt()}x${size.height.toInt()} fits without overflow',
          (tester) async {
        await _pumpFullPicking(tester, size);

        expect(overflowMessages, isEmpty, reason: overflowMessages.join(' | '));
        expect(tester.takeException(), isNull);

        // Landscape workspace must not introduce a whole-page scroll.
        expect(find.byType(SingleChildScrollView), findsNothing);

        expect(find.byType(PickingHeader), findsOneWidget);
        expect(find.byType(PickingItemCard), findsWidgets);
        expect(find.byKey(const Key('scan-item-barcode')), findsOneWidget);
        expect(find.text('Order Progress'), findsOneWidget);
        expect(find.text('Picking Tips'), findsOneWidget);
        expect(find.byKey(const Key('add-picking-note')), findsOneWidget);
        expect(find.byKey(const Key('review-pack-button')), findsOneWidget);
        expect(find.text('Pick all items to continue'), findsOneWidget);

        final review =
            tester.getRect(find.byKey(const Key('review-pack-button')));
        expect(review.bottom, lessThanOrEqualTo(size.height - 120));
        expect(review.top, greaterThan(0));
      });
    }

    testWidgets('Review & Pack stays disabled when items incomplete',
        (tester) async {
      await _pumpFullPicking(tester, const Size(1180, 820));
      final button = tester.widget<ButtonStyleButton>(
        find.descendant(
          of: find.byKey(const Key('review-pack-button')),
          matching: find.byWidgetPredicate((w) => w is ButtonStyleButton),
        ),
      );
      expect(button.onPressed, isNull);
    });

    testWidgets('phone stacked path scrolls without RenderFlex overflow',
        (tester) async {
      await _pumpWorkspaceOnly(tester, const Size(600, 900));
      expect(find.byType(SingleChildScrollView), findsOneWidget);
      expect(overflowMessages, isEmpty, reason: overflowMessages.join(' | '));
      expect(tester.takeException(), isNull);
    });
  });
}

Future<void> _pumpFullPicking(WidgetTester tester, Size size) async {
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
              permissionCodes: const [
                PosPermissionCodes.accessOnlineOrders,
                PosPermissionCodes.viewOnlineOrders,
                PosPermissionCodes.viewOnlineOrderPicking,
                PosPermissionCodes.pickOnlineOrderItem,
                PosPermissionCodes.scanOnlineOrderItem,
                PosPermissionCodes.addOnlineOrderPickingNote,
              ],
            ),
          ),
        ),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: size.width,
            height: bodyHeight,
            child: const ColoredBox(
              color: Color(0xFFF7F8FA),
              child: Padding(
                padding: EdgeInsets.fromLTRB(24, 10, 24, 10),
                child: Column(
                  children: [
                    PickingHeader(order: _order, onBack: _noop),
                    SizedBox(height: 10),
                    Expanded(
                      child: PickingWorkspace(
                        orderId: 'order-1',
                        order: _order,
                        onReviewPack: _noop,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _pumpWorkspaceOnly(WidgetTester tester, Size size) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authSessionProvider.overrideWith(
          (ref) => _PresetAuthSessionNotifier(
            AuthSession(
              accessToken: 'test-token',
              userId: 'user-1',
              userDisplayName: 'Cashier',
              permissionCodes: const [
                PosPermissionCodes.accessOnlineOrders,
                PosPermissionCodes.viewOnlineOrders,
                PosPermissionCodes.viewOnlineOrderPicking,
                PosPermissionCodes.pickOnlineOrderItem,
                PosPermissionCodes.scanOnlineOrderItem,
              ],
            ),
          ),
        ),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: size.width,
            height: size.height,
            child: const PickingWorkspace(
              orderId: 'order-1',
              order: _order,
              onReviewPack: _noop,
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void _noop() {}

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
  productName: 'Match Shorts',
  sku: 'MER-003-SKU',
  requestedQuantity: 1,
  pickedQuantity: 0,
  status: 'PICKING',
  locationCode: 'MAIN',
  locationName: 'Main Store Stock',
);

const _order = PosPickingOrder(
  orderId: 'order-1',
  orderNumber: 'ECOMM-SEED-ACCEPTED-001',
  fulfillmentOrderId: 'fulfilment-1',
  fulfillmentNumber: 'FUL-1',
  status: 'PICKING',
  assignedToName: 'Cashier',
  customerName: 'Customer 1',
  totalLines: 1,
  pickedLines: 0,
  canPack: false,
  lines: [_line],
);
