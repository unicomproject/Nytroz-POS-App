import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nytroz_pos/core/access/pos_access_codes.dart';
import 'package:nytroz_pos/features/cart/data/models/pos_parked_sale_dtos.dart';
import 'package:nytroz_pos/features/cart/domain/repositories/pos_parked_sale_repository.dart';
import 'package:nytroz_pos/features/cart/presentation/providers/pos_new_sale_cart_provider.dart';
import 'package:nytroz_pos/features/cart/presentation/providers/pos_parked_sale_provider.dart';
import 'package:nytroz_pos/features/sale/domain/entities/pos_checkout_summary.dart';
import 'package:nytroz_pos/features/sale/presentation/widgets/new_sale/pos_parked_sale_dialog.dart';
import 'package:nytroz_pos/features/tenant_admin/presentation/theme/tenant_admin_theme.dart';

void main() {
  testWidgets('shows backend list, count, exact reference and summary',
      (tester) async {
    final h = await _pump(tester);
    addTearDown(h.dispose);
    await _open(tester);
    expect(find.text('Parked Sales'), findsOneWidget);
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
      'confirmed recall uses provider response and restores backend cart',
      (tester) async {
    final h = await _pump(tester);
    addTearDown(h.dispose);
    await _open(tester);
    await tester.tap(find.byKey(const ValueKey('recall-hold-1')));
    await tester.pumpAndSettle();
    expect(find.text('Recall Sale'), findsNWidgets(3));
    expect(find.text('PS-2026-00021'), findsWidgets);
    final recallDialog = tester.widget<AlertDialog>(
      find.byKey(const ValueKey('recall-sale-dialog')),
    );
    expect(recallDialog.backgroundColor, TenantAdminColors.surface);
    expect(recallDialog.surfaceTintColor, TenantAdminColors.surface);
    final summary = tester.widget<Container>(
      find.byKey(const ValueKey('recall-sale-summary')),
    );
    final summaryDecoration = summary.decoration! as BoxDecoration;
    expect(summaryDecoration.color, TenantAdminColors.posHomeReturnsCard);
    expect(
      (summaryDecoration.border! as Border).top.color,
      TenantAdminColors.posNewSaleAccent,
    );
    final recallConfirm = tester.widget<FilledButton>(
      find.byKey(const ValueKey('recall-sale-confirm')),
    );
    expect(
      recallConfirm.style?.backgroundColor?.resolve(<WidgetState>{}),
      TenantAdminColors.posNewSaleAccent,
    );
    final recallCancel = tester.widget<OutlinedButton>(
      find.byKey(const ValueKey('recall-sale-cancel')),
    );
    expect(
      recallCancel.style?.foregroundColor?.resolve(<WidgetState>{}),
      TenantAdminColors.bodyText,
    );
    await tester.tap(find.byKey(const ValueKey('recall-sale-confirm')));
    await tester.pumpAndSettle();
    expect(h.repository.recalled, ['hold-1']);
    final cart = h.container.read(posNewSaleCartProvider);
    expect(cart.itemList.single.quantity, 2);
    expect(cart.selectedCustomer?.customerId, 'customer-1');
    expect(h.container.read(posParkedSaleProvider).valueOrNull, isEmpty);
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
      expect(find.widgetWithText(FilledButton, 'Recall Sale'), findsOneWidget);
      expect(find.widgetWithText(OutlinedButton, 'Cancel Parked Sale'),
          findsOneWidget);
    });
  }
}

Future<_Harness> _pump(WidgetTester tester,
    {List<PosHoldDto>? holds,
    bool activeCart = false,
    int failCancels = 0}) async {
  final repo = _Repo(holds ?? [_hold], failCancels: failCancels);
  final container = ProviderContainer(overrides: [
    posParkedSaleRepositoryProvider.overrideWithValue(repo),
    posParkedSaleAccessContextProvider.overrideWithValue(
        const PosParkedSaleAccessContext(
            authenticated: true,
            trustedDevice: true,
            deviceId: 'device-1',
            permissions: {
          PosPermissionCodes.viewBackendParkedSales,
          PosPermissionCodes.recallBackendParkedSale,
          PosPermissionCodes.createParkedSale
        })),
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
  _Repo(this.holds, {this.failCancels = 0});
  final List<PosHoldDto> holds;
  int failCancels;
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
