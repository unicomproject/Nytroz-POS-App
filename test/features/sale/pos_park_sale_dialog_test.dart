import 'dart:async';

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
import 'package:nytroz_pos/features/sale/presentation/widgets/new_sale/pos_park_sale_dialog.dart';
import 'package:nytroz_pos/features/tenant_admin/presentation/theme/tenant_admin_theme.dart';

void main() {
  testWidgets('shows the approved compact pre-submit content only',
      (tester) async {
    final harness = await _pumpHarness(tester);
    addTearDown(harness.dispose);
    await _open(tester);
    expect(find.text('Park Sale'), findsNWidgets(2));
    expect(find.text('Save this sale and continue it later.'), findsOneWidget);
    expect(find.text('Park Reference'), findsOneWidget);
    expect(find.text('Generated automatically after parking'), findsOneWidget);
    expect(find.text('Short Note (Optional)'), findsOneWidget);
    expect(find.text('Customer will return shortly'), findsOneWidget);
    expect(find.text('This parked sale will be available for 24 hours.'),
        findsOneWidget);
    for (final forbidden in [
      'Hold Reference Name',
      'Customer Name',
      'Assigned Cashier',
      'Confirm Hold Sale',
      'Expiry'
    ]) {
      expect(find.text(forbidden), findsNothing);
    }
    expect(find.textContaining('PS-'), findsNothing);
    expect(find.text('0/250'), findsNothing);

    final dialog = tester.widget<Dialog>(find.byType(Dialog));
    expect(dialog.backgroundColor, TenantAdminColors.surface);
    expect(dialog.surfaceTintColor, TenantAdminColors.surface);

    final headerIcon = tester.widget<Container>(
      find.byKey(const Key('park-sale-header-icon')),
    );
    final headerDecoration = headerIcon.decoration! as BoxDecoration;
    expect(headerDecoration.color, TenantAdminColors.surface);
    expect(
      (headerDecoration.border! as Border).top.color,
      TenantAdminColors.posNewSaleAccent,
    );

    final referenceField = tester.widget<Container>(
      find.byKey(const Key('park-sale-reference-field')),
    );
    final referenceDecoration = referenceField.decoration! as BoxDecoration;
    expect(referenceDecoration.color, TenantAdminColors.surface);
    expect(referenceDecoration.border, isA<Border>());

    final note = tester.widget<InputDecorator>(
      find.descendant(
        of: find.byKey(const Key('park-sale-note')),
        matching: find.byType(InputDecorator),
      ),
    );
    expect(note.decoration.border, isA<OutlineInputBorder>());
    expect(note.decoration.counterText, isEmpty);

    final expiry = tester.widget<Container>(
      find.byKey(const Key('park-sale-expiry-banner')),
    );
    final expiryDecoration = expiry.decoration! as BoxDecoration;
    expect(expiryDecoration.color, TenantAdminColors.posHomeReturnsCard);
    expect(
      (expiryDecoration.border! as Border).top.color,
      TenantAdminColors.posNewSaleAccent,
    );

    final cancel = tester.widget<OutlinedButton>(
      find.byKey(const Key('park-sale-cancel')),
    );
    expect(
      cancel.style?.foregroundColor?.resolve(<WidgetState>{}),
      TenantAdminColors.bodyText,
    );
    final submit = tester.widget<FilledButton>(
      find.byKey(const Key('park-sale-submit')),
    );
    expect(
      submit.style?.backgroundColor?.resolve(<WidgetState>{}),
      TenantAdminColors.posNewSaleAccent,
    );
  });

  testWidgets('251-character note is rejected before repository call',
      (tester) async {
    final harness = await _pumpHarness(tester);
    addTearDown(harness.dispose);
    await _open(tester);
    await tester.enterText(find.byKey(const Key('park-sale-note')), 'x' * 251);
    await tester.tap(find.widgetWithText(FilledButton, 'Park Sale'));
    await tester.pump();
    expect(find.text('Short note must be 250 characters or fewer.'),
        findsOneWidget);
    expect(harness.repository.created, isEmpty);
    expect(harness.container.read(posNewSaleCartProvider).hasItems, isTrue);
  });

  testWidgets('success closes dialog and leaves provider-cleared cart',
      (tester) async {
    final harness = await _pumpHarness(tester);
    addTearDown(harness.dispose);
    await _open(tester);
    await tester.enterText(
        find.byKey(const Key('park-sale-note')), '  returns soon  ');
    await tester.tap(find.widgetWithText(FilledButton, 'Park Sale'));
    await tester.pumpAndSettle();
    expect(harness.repository.created, hasLength(1));
    expect(harness.repository.created.single.reason, 'returns soon');
    expect(harness.repository.created.single.toJson(),
        isNot(contains('expiresAt')));
    expect(find.text('Sale parked successfully'), findsNothing);
    expect(find.byKey(const Key('park-sale-success-icon')), findsNothing);
    expect(find.byKey(const Key('park-sale-success-done')), findsNothing);
    expect(find.byType(Dialog), findsNothing);
    expect(harness.container.read(posNewSaleCartProvider).hasItems, isFalse);
  });

  testWidgets('cancel preserves the active cart and makes no request',
      (tester) async {
    final harness = await _pumpHarness(tester);
    addTearDown(harness.dispose);
    await _open(tester);
    await tester.tap(find.widgetWithText(OutlinedButton, 'Cancel'));
    await tester.pumpAndSettle();
    expect(harness.repository.created, isEmpty);
    expect(harness.container.read(posNewSaleCartProvider).hasItems, isTrue);
  });

  testWidgets('loading blocks cancel and duplicate submission', (tester) async {
    final repository = _Repository()..pending = Completer<PosHoldDto>();
    final harness = await _pumpHarness(tester, repository: repository);
    addTearDown(harness.dispose);
    await _open(tester);

    await tester.tap(find.byKey(const Key('park-sale-submit')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('park-sale-submit')));
    await tester.pump();

    expect(find.text('Parking sale'), findsOneWidget);
    expect(repository.created, hasLength(1));
    expect(
      tester
          .widget<OutlinedButton>(find.byKey(const Key('park-sale-cancel')))
          .onPressed,
      isNull,
    );

    repository.pending!.complete(_hold);
    await tester.pumpAndSettle();
    expect(find.byType(Dialog), findsNothing);
    expect(harness.container.read(posNewSaleCartProvider).hasItems, isFalse);
  });

  testWidgets('recoverable failure preserves note and cart', (tester) async {
    final repository = _Repository()..error = Exception('Park unavailable');
    final harness = await _pumpHarness(tester, repository: repository);
    addTearDown(harness.dispose);
    await _open(tester);
    await tester.enterText(
      find.byKey(const Key('park-sale-note')),
      'Customer will return shortly',
    );

    await tester.tap(find.byKey(const Key('park-sale-submit')));
    await tester.pumpAndSettle();

    expect(find.textContaining('Park unavailable'), findsOneWidget);
    expect(
      tester
          .widget<TextFormField>(find.byKey(const Key('park-sale-note')))
          .controller
          ?.text,
      'Customer will return shortly',
    );
    expect(harness.container.read(posNewSaleCartProvider).hasItems, isTrue);
    expect(repository.created, hasLength(1));
  });

  for (final size in [
    const Size(1280, 800),
    const Size(1680, 1050),
    const Size(2560, 1600)
  ]) {
    testWidgets('has no overflow at ${size.width} x ${size.height}',
        (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final harness = await _pumpHarness(tester);
      addTearDown(harness.dispose);
      await _open(tester);
      expect(tester.takeException(), isNull);
      expect(find.widgetWithText(FilledButton, 'Park Sale'), findsOneWidget);
    });
  }

  testWidgets('increased text scale keeps footer visible without overflow',
      (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 1.5;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final harness = await _pumpHarness(tester);
    addTearDown(harness.dispose);
    await _open(tester);
    expect(tester.takeException(), isNull);
    expect(find.byKey(const Key('park-sale-submit')), findsOneWidget);
    expect(find.byKey(const Key('park-sale-cancel')), findsOneWidget);
  });
}

Future<_Harness> _pumpHarness(
  WidgetTester tester, {
  _Repository? repository,
}) async {
  repository ??= _Repository();
  const parkPermissions = {
    PosPermissionCodes.createParkedSale,
    PosPermissionCodes.heldSalesCreate,
    PosPermissionCodes.heldSalesPopupView,
    PosPermissionCodes.heldSalesPopupReference,
    PosPermissionCodes.heldSalesPopupNote,
    PosPermissionCodes.heldSalesPopupExpiry,
    PosPermissionCodes.viewBackendParkedSales,
  };
  final container = ProviderContainer(overrides: [
    posParkedSaleRepositoryProvider.overrideWithValue(repository),
    effectivePermissionSetProvider.overrideWithValue(
      EffectivePermissionSet.fromIterable(parkPermissions),
    ),
    posParkedSaleAccessContextProvider
        .overrideWithValue(const PosParkedSaleAccessContext(
      authenticated: true,
      trustedDevice: true,
      deviceId: '11111111-1111-1111-1111-111111111111',
      permissions: parkPermissions,
    )),
  ]);
  container.read(posNewSaleCartProvider.notifier).addToCart(_product);
  await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(home: Scaffold(body: _OpenButton()))));
  return _Harness(container, repository);
}

Future<void> _open(WidgetTester tester) async {
  await tester.tap(find.text('Open Park Sale'));
  await tester.pumpAndSettle();
}

class _OpenButton extends ConsumerWidget {
  const _OpenButton();
  @override
  Widget build(BuildContext context, WidgetRef ref) => FilledButton(
        onPressed: () => showPosParkSaleDialog(
            context: context, ref: ref, cart: ref.read(posNewSaleCartProvider)),
        child: const Text('Open Park Sale'),
      );
}

class _Harness {
  const _Harness(this.container, this.repository);
  final ProviderContainer container;
  final _Repository repository;
  void dispose() => container.dispose();
}

class _Repository implements PosParkedSaleRepository {
  final created = <PosCreateHoldRequestDto>[];
  Completer<PosHoldDto>? pending;
  Object? error;

  @override
  Future<PosHoldDto> create(PosCreateHoldRequestDto request) async {
    created.add(request);
    final failure = error;
    if (failure != null) throw failure;
    final completer = pending;
    if (completer != null) return completer.future;
    return _hold;
  }

  @override
  Future<PosHoldListDto> list(
          {required String deviceId,
          required String scope,
          required int page,
          required int pageSize}) async =>
      const PosHoldListDto([], 0);
  @override
  Future<void> cancel(String holdId, {String? reason}) =>
      throw UnimplementedError();
  @override
  Future<PosRecallHoldDto> recall(String holdId, String deviceId) =>
      throw UnimplementedError();
}

final _hold = PosHoldDto(
    holdId: 'hold',
    holdNumber: 'PS-2026-00012',
    saleId: 'sale',
    saleNumber: 'SALE-1',
    status: 'Held',
    itemCount: 1,
    subtotal: 1500,
    discount: 0,
    tax: 0,
    total: 1500,
    currency: 'LKR',
    heldAt: DateTime.utc(2026, 8, 6),
    lines: const [
      PosHoldLineDto(
          lineId: 'line',
          variantId: 'variant',
          name: 'Product',
          qty: 1,
          unitPrice: 1500,
          lineTotal: 1500)
    ]);
const _product = PosNewSaleProduct(
    id: 'product',
    productId: 'product',
    variantId: 'variant',
    name: 'Product',
    category: 'General',
    price: 1500);
