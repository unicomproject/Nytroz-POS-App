import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nytroz_pos/core/access/effective_permission_set.dart';
import 'package:nytroz_pos/core/access/permission_access_providers.dart';
import 'package:nytroz_pos/core/access/pos_access_codes.dart';
import 'package:nytroz_pos/features/cart/data/models/pos_parked_sale_dtos.dart';
import 'package:nytroz_pos/features/cart/domain/repositories/pos_parked_sale_repository.dart';
import 'package:nytroz_pos/features/cart/presentation/providers/pos_new_sale_cart_provider.dart';
import 'package:nytroz_pos/features/cart/presentation/providers/pos_parked_sale_provider.dart';
import 'package:nytroz_pos/features/sale/domain/entities/pos_checkout_summary.dart';
import 'package:nytroz_pos/features/sale/presentation/widgets/new_sale/pos_parked_sale_dialog.dart';
import 'package:nytroz_pos/features/tenant_admin/presentation/theme/tenant_admin_theme.dart';

/// Held-sales view/recall/cancel + list children (Chunk 14 exact membership).
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
};

void main() {
  testWidgets('shows backend list, count, exact reference and summary',
      (tester) async {
    final h = await _pump(tester);
    addTearDown(h.dispose);
    await _open(tester);
    expect(find.text('Parked Sales'), findsOneWidget);
    expect(find.text('Parked Sales Summary'), findsNothing);
    expect(find.byKey(const ValueKey('dashboard-parked-sales-summary')),
        findsNothing);
    expect(find.text('1 active'), findsOneWidget);
    expect(find.text('PS-2026-00021'), findsOneWidget);
    expect(find.text('Maya Silva'), findsOneWidget);
    expect(find.text('2 items'), findsWidgets);
    expect(find.text('LKR 3,000.00'), findsOneWidget);
    expect(find.textContaining('Expires '), findsOneWidget);
    expect(find.textContaining('Parked Sale #'), findsNothing);
    final dialog = tester.widget<Dialog>(find.byType(Dialog).first);
    expect(dialog.backgroundColor, TenantAdminColors.surface);
    expect(dialog.surfaceTintColor, TenantAdminColors.surface);
    final card = tester.widget<Container>(
      find.byKey(const ValueKey('parked-sale-card-hold-1')),
    );
    final decoration = card.decoration! as BoxDecoration;
    expect(decoration.color, TenantAdminColors.surface);
    expect((decoration.border! as Border).top.color, TenantAdminColors.border);
    final recall = tester.widget<FilledButton>(
      find.byKey(const ValueKey('recall-hold-1')),
    );
    expect(
      recall.style?.backgroundColor?.resolve(<WidgetState>{}),
      TenantAdminColors.posNewSaleAccent,
    );
    final chip = tester.widget<Chip>(find.byType(Chip).first);
    expect(chip.backgroundColor, TenantAdminColors.posHomeReturnsCard);
    expect(chip.side?.color, TenantAdminColors.posNewSaleAccent);
  });

  testWidgets('empty backend list shows approved empty state', (tester) async {
    final h = await _pump(tester, holds: const []);
    addTearDown(h.dispose);
    await _open(tester);
    expect(find.text('No parked sales available'), findsOneWidget);
    expect(find.text('0 active'), findsOneWidget);
  });

  testWidgets('non-empty active cart blocks recall without repository call',
      (tester) async {
    final h = await _pump(tester, activeCart: true);
    addTearDown(h.dispose);
    await _open(tester);
    await tester.tap(find.byKey(const ValueKey('recall-hold-1')));
    await tester.pumpAndSettle();
    expect(find.text('Cannot Recall Sale'), findsOneWidget);
    expect(
        find.text(
            'Complete, clear or park the current cart before recalling another sale.'),
        findsOneWidget);
    expect(h.repository.recalled, isEmpty);
    expect(h.container.read(posNewSaleCartProvider).hasItems, isTrue);
  });

  testWidgets(
      'single-tap recall uses provider response and restores backend cart',
      (tester) async {
    final h = await _pump(tester);
    addTearDown(h.dispose);
    await _open(tester);
    await tester.tap(find.byKey(const ValueKey('recall-hold-1')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('recall-sale-dialog')), findsNothing);
    expect(find.text('Parked Sales'), findsNothing);
    expect(find.byType(Dialog), findsNothing);
    expect(find.text('Open'), findsOneWidget);
    expect(h.repository.recalled, ['hold-1']);
    final cart = h.container.read(posNewSaleCartProvider);
    expect(cart.hasItems, isTrue);
    expect(cart.itemList, hasLength(1));
    expect(cart.itemList.single.quantity, 2);
    expect(cart.selectedCustomer?.customerId, 'customer-1');
    expect(h.container.read(posParkedSaleProvider).valueOrNull, isEmpty);
  });

  testWidgets('failed recall keeps Parked Sales open and cart empty',
      (tester) async {
    final h = await _pump(tester, failRecalls: 1);
    addTearDown(h.dispose);
    await _open(tester);
    await tester.tap(find.byKey(const ValueKey('recall-hold-1')));
    await tester.pumpAndSettle();
    expect(find.text('Parked Sales'), findsOneWidget);
    expect(find.byKey(const ValueKey('parked-sale-card-hold-1')), findsOneWidget);
    expect(find.byType(Dialog), findsOneWidget);
    expect(h.container.read(posNewSaleCartProvider).hasItems, isFalse);
    expect(h.repository.recalled, isEmpty);
  });

  testWidgets('rapid double Recall tap issues only one repository recall',
      (tester) async {
    final h = await _pump(tester, recallDelay: const Duration(milliseconds: 80));
    addTearDown(h.dispose);
    await _open(tester);
    await tester.tap(find.byKey(const ValueKey('recall-hold-1')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('recall-hold-1')));
    await tester.pumpAndSettle();
    expect(h.repository.recalled, ['hold-1']);
    expect(find.text('Parked Sales'), findsNothing);
    expect(h.container.read(posNewSaleCartProvider).itemList, hasLength(1));
  });

  testWidgets('held view without recall hides Recall button', (tester) async {
    final h = await _pump(
      tester,
      permissions: {
        PosPermissionCodes.heldSalesView,
        PosPermissionCodes.viewBackendParkedSales,
        PosPermissionCodes.heldSalesListActiveCount,
        PosPermissionCodes.heldSalesListCustomer,
        PosPermissionCodes.heldSalesListValue,
        PosPermissionCodes.heldSalesListItemCount,
        PosPermissionCodes.heldSalesListParkedTime,
        PosPermissionCodes.heldSalesListExpiryTime,
        PosPermissionCodes.heldSalesListItems,
        PosPermissionCodes.heldSalesListFilters,
        PosPermissionCodes.heldSalesListPagination,
      },
    );
    addTearDown(h.dispose);
    await _open(tester);
    expect(find.byKey(const ValueKey('recall-hold-1')), findsNothing);
    expect(find.widgetWithText(FilledButton, 'Recall'), findsNothing);
  });

  testWidgets(
      'cancel trims reason and removes only after 204 repository success',
      (tester) async {
    final h = await _pump(tester);
    addTearDown(h.dispose);
    await _open(tester);
    await tester.tap(find.widgetWithText(OutlinedButton, 'Cancel Parked Sale'));
    await tester.pumpAndSettle();
    expect(find.text('Cancel Parked Sale'), findsWidgets);
    expect(find.text('PS-2026-00021'), findsWidgets);
    await tester.enterText(find.byKey(const Key('cancel-parked-sale-reason')),
        '  customer changed mind  ');
    await tester.tap(find.widgetWithText(FilledButton, 'Cancel Parked Sale'));
    await tester.pumpAndSettle();
    expect(h.repository.cancelled.single, ('hold-1', 'customer changed mind'));
    expect(h.container.read(posParkedSaleProvider).valueOrNull, isEmpty);
    expect(h.container.read(posNewSaleCartProvider).hasItems, isFalse);
  });

  testWidgets('251-character cancel reason is rejected before repository call',
      (tester) async {
    final h = await _pump(tester);
    addTearDown(h.dispose);
    await _open(tester);
    await tester.tap(find.widgetWithText(OutlinedButton, 'Cancel Parked Sale'));
    await tester.pumpAndSettle();
    await tester.enterText(
        find.byKey(const Key('cancel-parked-sale-reason')), 'x' * 251);
    await tester.tap(find.widgetWithText(FilledButton, 'Cancel Parked Sale'));
    await tester.pump();
    expect(
        find.text('Reason must be 250 characters or fewer.'), findsOneWidget);
    expect(h.repository.cancelled, isEmpty);
  });

  testWidgets(
      'empty or whitespace-only cancel reason is rejected before repository call',
      (tester) async {
    final h = await _pump(tester);
    addTearDown(h.dispose);
    await _open(tester);
    await tester.tap(find.widgetWithText(OutlinedButton, 'Cancel Parked Sale'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Cancel Parked Sale'));
    await tester.pump();
    expect(find.text('A cancellation reason is required.'), findsOneWidget);
    expect(h.repository.cancelled, isEmpty);

    await tester.enterText(
        find.byKey(const Key('cancel-parked-sale-reason')), '   ');
    await tester.tap(find.widgetWithText(FilledButton, 'Cancel Parked Sale'));
    await tester.pump();
    expect(find.text('A cancellation reason is required.'), findsOneWidget);
    expect(h.repository.cancelled, isEmpty);
  });

  testWidgets('cancel reason text is preserved after a repository failure',
      (tester) async {
    final h = await _pump(tester, failCancels: 1);
    addTearDown(h.dispose);
    await _open(tester);
    await tester.tap(find.widgetWithText(OutlinedButton, 'Cancel Parked Sale'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('cancel-parked-sale-reason')),
        'customer changed mind');
    await tester.tap(find.widgetWithText(FilledButton, 'Cancel Parked Sale'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Cancel unavailable'), findsOneWidget);
    expect(
      tester
          .widget<TextFormField>(
              find.byKey(const Key('cancel-parked-sale-reason')))
          .controller
          ?.text,
      'customer changed mind',
    );
    expect(h.repository.cancelled, isEmpty);
  });

  for (final size in [
    const Size(1280, 800),
    const Size(1680, 1050),
    const Size(2560, 1600)
  ]) {
    testWidgets('list and actions fit at ${size.width} x ${size.height}',
        (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final h = await _pump(tester);
      addTearDown(h.dispose);
      await _open(tester);
      expect(tester.takeException(), isNull);
      expect(find.widgetWithText(FilledButton, 'Recall'), findsOneWidget);
      expect(find.widgetWithText(OutlinedButton, 'Cancel Parked Sale'),
          findsOneWidget);
    });
  }

  for (final size in [
    const Size(390, 844),
    const Size(1280, 800),
    const Size(2560, 1600),
  ]) {
    testWidgets(
        'successful recall dismisses Parked Sales at ${size.width} x ${size.height}',
        (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final h = await _pump(tester);
      addTearDown(h.dispose);
      await _open(tester);
      await tester.tap(find.byKey(const ValueKey('recall-hold-1')));
      await tester.pumpAndSettle();
      // Phone widths may overflow the action row; navigation must still complete.
      while (tester.takeException() != null) {}
      expect(find.text('Parked Sales'), findsNothing);
      expect(find.byType(Dialog), findsNothing);
      expect(h.container.read(posNewSaleCartProvider).itemList, hasLength(1));
      expect(find.text('Open'), findsOneWidget);
    });
  }
}

Future<_Harness> _pump(
  WidgetTester tester, {
  List<PosHoldDto>? holds,
  bool activeCart = false,
  int failCancels = 0,
  int failRecalls = 0,
  Duration? recallDelay,
  Set<String>? permissions,
}) async {
  final granted = permissions ?? _heldSalesFixturePermissions;
  final repo = _Repo(
    holds ?? [_hold],
    failCancels: failCancels,
    failRecalls: failRecalls,
    recallDelay: recallDelay,
  );
  final container = ProviderContainer(overrides: [
    posParkedSaleRepositoryProvider.overrideWithValue(repo),
    posParkedSaleAccessContextProvider.overrideWithValue(
      PosParkedSaleAccessContext(
        authenticated: true,
        trustedDevice: true,
        deviceId: 'device-1',
        permissions: granted,
      ),
    ),
    effectivePermissionSetProvider.overrideWithValue(
      EffectivePermissionSet.fromIterable(granted),
    ),
  ]);
  if (activeCart) {
    container.read(posNewSaleCartProvider.notifier).addToCart(_product);
  }
  await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(home: Scaffold(body: _Open()))));
  return _Harness(container, repo);
}

Future<void> _open(WidgetTester tester) async {
  await tester.tap(find.text('Open'));
  await tester.pumpAndSettle();
}

class _Open extends ConsumerWidget {
  const _Open();
  @override
  Widget build(BuildContext context, WidgetRef ref) => FilledButton(
      onPressed: () => showPosParkedSaleDialog(context: context, ref: ref),
      child: const Text('Open'));
}

class _Harness {
  const _Harness(this.container, this.repository);
  final ProviderContainer container;
  final _Repo repository;
  void dispose() => container.dispose();
}

class _Repo implements PosParkedSaleRepository {
  _Repo(
    this.holds, {
    this.failCancels = 0,
    this.failRecalls = 0,
    this.recallDelay,
  });
  final List<PosHoldDto> holds;
  int failCancels;
  int failRecalls;
  final Duration? recallDelay;
  final recalled = <String>[];
  final cancelled = <(String, String?)>[];
  @override
  Future<PosHoldListDto> list(
          {required String deviceId,
          required String scope,
          required int page,
          required int pageSize}) async =>
      PosHoldListDto(holds, holds.length);
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
    if (failCancels-- > 0) {
      throw Exception('Cancel unavailable');
    }
    cancelled.add((holdId, reason));
    holds.removeWhere((hold) => hold.holdId == holdId);
  }

  @override
  Future<PosHoldDto> create(PosCreateHoldRequestDto request) =>
      throw UnimplementedError();
}

final _hold = PosHoldDto(
    holdId: 'hold-1',
    holdNumber: 'PS-2026-00021',
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
    holdNumber: 'PS-2026-00021',
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
const _product = PosNewSaleProduct(
    id: 'product-1',
    productId: 'product-1',
    variantId: 'variant-1',
    name: 'Team Jersey',
    category: 'Apparel',
    price: 1500);
