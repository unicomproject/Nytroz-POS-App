import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:nytroz_pos/core/access/effective_permission_set.dart';
import 'package:nytroz_pos/core/access/permission_access_providers.dart';
import 'package:nytroz_pos/core/access/pos_access_codes.dart';
import 'package:nytroz_pos/features/cart/data/models/pos_parked_sale_dtos.dart';
import 'package:nytroz_pos/features/cart/domain/repositories/pos_parked_sale_repository.dart';
import 'package:nytroz_pos/features/cart/presentation/providers/pos_new_sale_cart_provider.dart';
import 'package:nytroz_pos/features/cart/presentation/providers/pos_parked_sale_provider.dart';
import 'package:nytroz_pos/features/sale/domain/entities/pos_checkout_summary.dart';
import 'package:nytroz_pos/features/sale/presentation/screens/pos_parked_sales_screen.dart';

/// Held-sales view/recall/cancel + list/summary children (Chunk 14).
const _heldSalesFixturePermissions = {
  PosPermissionCodes.heldSalesView,
  PosPermissionCodes.viewBackendParkedSales,
  PosPermissionCodes.heldSalesRecall,
  PosPermissionCodes.recallBackendParkedSale,
  PosPermissionCodes.heldSalesCancel,
  PosPermissionCodes.heldSalesCreate,
  PosPermissionCodes.createParkedSale,
  PosPermissionCodes.heldSalesListActiveCount,
  PosPermissionCodes.heldSalesListCustomer,
  PosPermissionCodes.heldSalesListValue,
  PosPermissionCodes.heldSalesListItemCount,
  PosPermissionCodes.heldSalesListParkedTime,
  PosPermissionCodes.heldSalesListExpiryTime,
  PosPermissionCodes.heldSalesListItems,
  PosPermissionCodes.heldSalesListSummary,
  PosPermissionCodes.heldSalesListFilters,
  PosPermissionCodes.heldSalesListPagination,
  // Summary panel "Start New Sale" uses canAccessNewSale (exact create).
  PosPermissionCodes.createSale,
};

void main() {
  testWidgets('loading state shows a progress indicator', (tester) async {
    final harness = await _pump(tester, repo: _Repo(holds: [_hold]));
    addTearDown(harness.dispose);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('empty list shows the empty state message', (tester) async {
    final harness = await _pump(tester, repo: _Repo(holds: const []));
    addTearDown(harness.dispose);
    await tester.pumpAndSettle();
    expect(find.text('No parked sales available'), findsOneWidget);
  });

  testWidgets('error state shows retry and retry reloads successfully',
      (tester) async {
    final repo = _Repo(holds: [_hold], failFirstList: true);
    final harness = await _pump(tester, repo: repo);
    addTearDown(harness.dispose);
    await tester.pumpAndSettle();
    expect(find.text('Try Again'), findsOneWidget);
    expect(find.text('PS-2026-00099'), findsNothing);

    await tester.tap(find.text('Try Again'));
    await tester.pumpAndSettle();

    expect(find.text('Try Again'), findsNothing);
    expect(find.text('PS-2026-00099'), findsOneWidget);
  });

  testWidgets(
      'this route is not the generic placeholder screen and shows parked sales content',
      (tester) async {
    final harness = await _pump(tester, repo: _Repo(holds: [_hold]));
    addTearDown(harness.dispose);
    await tester.pumpAndSettle();
    expect(
        find.byKey(const ValueKey('pos-parked-sales-screen')), findsOneWidget);
    expect(find.text('Coming soon'), findsNothing);
    expect(find.text('PS-2026-00099'), findsOneWidget);
  });

  testWidgets('dashboard route shows the parked sales side summary',
      (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final harness = await _pump(tester, repo: _Repo(holds: [_hold]));
    addTearDown(harness.dispose);
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('dashboard-parked-sales-summary')),
        findsOneWidget);
    expect(find.text('Parked Sales Summary'), findsOneWidget);
    expect(find.text('Total Parked Sales'), findsOneWidget);
    expect(find.text('Total Parked Value'), findsOneWidget);
    expect(find.text('Start New Sale'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('closing View keeps the Parked Sales route mounted',
      (tester) async {
    final harness = await _pump(tester, repo: _Repo(holds: [_hold]));
    addTearDown(harness.dispose);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('view-hold-1')));
    await tester.pumpAndSettle();
    expect(
        find.byKey(const ValueKey('parked-sale-view-dialog')), findsOneWidget);

    await tester.tap(find.widgetWithText(TextButton, 'Close'));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('parked-sale-view-dialog')), findsNothing);
    expect(find.byType(PosParkedSalesScreen), findsOneWidget);
    expect(find.text('PS-2026-00099'), findsOneWidget);
  });

  testWidgets('successful recall restores cart and navigates to New Sale',
      (tester) async {
    final repo = _Repo(holds: [_hold]);
    final harness = await _pump(tester, repo: repo);
    addTearDown(harness.dispose);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('recall-hold-1')));
    await tester.pumpAndSettle();

    expect(repo.recalled, ['hold-1']);
    expect(find.text('New Sale Stub'), findsOneWidget);
    expect(find.byType(PosParkedSalesScreen), findsNothing);
    expect(find.text('Parked Sales'), findsNothing);
    expect(
      harness.container.read(posNewSaleCartProvider).itemList.single.quantity,
      2,
    );
    expect(harness.router.routerDelegate.currentConfiguration.uri.toString(),
        '/pos/new-sale');
  });

  testWidgets('failed recall stays on Parked Sales without changing cart',
      (tester) async {
    final repo = _Repo(holds: [_hold], failRecalls: 1);
    final harness = await _pump(tester, repo: repo);
    addTearDown(harness.dispose);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('recall-hold-1')));
    await tester.pumpAndSettle();

    expect(find.byType(PosParkedSalesScreen), findsOneWidget);
    expect(find.text('New Sale Stub'), findsNothing);
    expect(harness.container.read(posNewSaleCartProvider).hasItems, isFalse);
    expect(repo.recalled, isEmpty);
    expect(harness.router.routerDelegate.currentConfiguration.uri.toString(),
        '/pos/parked-sales');
  });

  testWidgets('rapid double Recall tap issues one recall and one New Sale go',
      (tester) async {
    final repo = _Repo(
      holds: [_hold],
      recallDelay: const Duration(milliseconds: 80),
    );
    final harness = await _pump(tester, repo: repo);
    addTearDown(harness.dispose);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('recall-hold-1')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('recall-hold-1')));
    await tester.pumpAndSettle();

    expect(repo.recalled, ['hold-1']);
    expect(find.text('New Sale Stub'), findsOneWidget);
    expect(find.byType(PosParkedSalesScreen), findsNothing);
    expect(harness.router.routerDelegate.currentConfiguration.uri.toString(),
        '/pos/new-sale');
  });
}

Future<_Harness> _pump(WidgetTester tester, {required _Repo repo}) async {
  final container = ProviderContainer(overrides: [
    posParkedSaleRepositoryProvider.overrideWithValue(repo),
    posParkedSaleAccessContextProvider.overrideWithValue(
      const PosParkedSaleAccessContext(
        authenticated: true,
        trustedDevice: true,
        deviceId: 'device-1',
        permissions: _heldSalesFixturePermissions,
      ),
    ),
    effectivePermissionSetProvider.overrideWithValue(
      EffectivePermissionSet.fromIterable(_heldSalesFixturePermissions),
    ),
  ]);
  final router = GoRouter(
    initialLocation: '/pos/parked-sales',
    routes: [
      GoRoute(
        path: '/pos/parked-sales',
        builder: (context, state) => const Scaffold(
          body: PosParkedSalesScreen(),
        ),
      ),
      GoRoute(
        path: '/pos/new-sale',
        builder: (context, state) => const Scaffold(
          body: Center(child: Text('New Sale Stub')),
        ),
      ),
    ],
  );
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  return _Harness(container, repo, router);
}

class _Harness {
  const _Harness(this.container, this.repo, this.router);
  final ProviderContainer container;
  final _Repo repo;
  final GoRouter router;
  void dispose() => container.dispose();
}

class _Repo implements PosParkedSaleRepository {
  _Repo({
    required this.holds,
    this.failFirstList = false,
    this.failRecalls = 0,
    this.recallDelay,
  });
  final List<PosHoldDto> holds;
  bool failFirstList;
  int failRecalls;
  final Duration? recallDelay;
  final recalled = <String>[];

  @override
  Future<PosHoldListDto> list(
      {required String deviceId,
      required String scope,
      required int page,
      required int pageSize}) async {
    if (failFirstList) {
      failFirstList = false;
      throw Exception('Parked sales are unavailable.');
    }
    return PosHoldListDto(
      holds,
      holds.length,
      totalValue: holds.fold(0, (sum, hold) => sum + hold.total),
      currency: 'LKR',
    );
  }

  @override
  Future<PosRecallHoldDto> recall(String holdId, String deviceId) async {
    if (recallDelay != null) {
      await Future<void>.delayed(recallDelay!);
    }
    if (failRecalls-- > 0) {
      throw Exception('Recall unavailable');
    }
    recalled.add(holdId);
    holds.removeWhere((hold) => hold.holdId == holdId);
    return _recall;
  }

  @override
  Future<void> cancel(String holdId, {String? reason}) async {
    holds.removeWhere((hold) => hold.holdId == holdId);
  }

  @override
  Future<PosHoldDto> create(PosCreateHoldRequestDto request) =>
      throw UnimplementedError();
}

final _hold = PosHoldDto(
    holdId: 'hold-1',
    holdNumber: 'PS-2026-00099',
    saleId: 'sale-1',
    saleNumber: 'SALE-1',
    customerId: 'customer-1',
    customerName: 'Maya Silva',
    reason: 'Returns after lunch',
    status: 'Held',
    itemCount: 2,
    subtotal: 3000,
    discount: 0,
    tax: 0,
    total: 3000,
    currency: 'LKR',
    heldAt: DateTime.utc(2026, 8, 6, 8),
    expiresAt: DateTime.utc(2026, 8, 7, 8),
    lines: const [
      PosHoldLineDto(
          lineId: 'line-1',
          variantId: 'variant-1',
          name: 'Team Jersey',
          qty: 2,
          unitPrice: 1500,
          lineTotal: 3000)
    ]);
final _recall = PosRecallHoldDto(
    holdId: 'hold-1',
    saleId: 'sale-1',
    holdNumber: 'PS-2026-00099',
    deviceId: 'device-1',
    customerId: 'customer-1',
    customerName: 'Maya Silva',
    saleType: 'NewSale',
    recalledAt: DateTime.utc(2026, 8, 6, 9),
    lines: const [PosCheckoutLineRequest(variantId: 'variant-1', quantity: 2)],
    checkoutSummary: PosCheckoutSummaryPayload(
        billingSummary: const PosCheckoutBillingSummaryPayload(
            itemCount: 2,
            subtotal: 3000,
            discount: 0,
            tax: 0,
            totalPayable: 3000,
            currency: 'LKR'),
        saleDetails: PosCheckoutSaleDetailsPayload(
            saleType: 'NewSale',
            itemsInCart: 2,
            saleDate: DateTime.utc(2026, 8, 6, 9),
            cashierName: 'Cashier'),
        paymentMethods: const ['cash'],
        validationMessages: const []));
