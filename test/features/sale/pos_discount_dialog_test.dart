import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nytroz_pos/core/access/pos_access_codes.dart';
import 'package:nytroz_pos/core/storage/app_secure_storage.dart';
import 'package:nytroz_pos/features/auth/data/datasources/auth_session_storage.dart';
import 'package:nytroz_pos/features/auth/domain/entities/auth_session.dart';
import 'package:nytroz_pos/features/auth/presentation/providers/session_provider.dart';
import 'package:nytroz_pos/features/cart/domain/entities/pos_cart_discount.dart';
import 'package:nytroz_pos/features/cart/domain/entities/pos_discount_api_models.dart';
import 'package:nytroz_pos/features/cart/presentation/providers/pos_discount_provider.dart';
import 'package:nytroz_pos/features/cart/presentation/providers/pos_new_sale_cart_provider.dart';
import 'package:nytroz_pos/features/sale/presentation/widgets/new_sale/discount/discount_controller.dart';
import 'package:nytroz_pos/features/sale/presentation/widgets/new_sale/discount/discount_state.dart';
import 'package:nytroz_pos/features/sale/presentation/widgets/new_sale/pos_discount_dialog.dart';

void main() {
  group('PosDiscountController', () {
    test('starts at order percentage with neutral preview', () {
      final controller = PosDiscountController(
          currencyCode: 'LKR', subtotal: 4400, itemCount: 2);
      expect(controller.state.scope, PosDiscountScope.order);
      expect(controller.state.calculationMethod,
          PosDiscountCalculationMethod.percentage);
      expect(controller.state.selectedCartLineKey, isNull);
      expect(controller.state.requestedValueText, isEmpty);
      expect(controller.state.preview.discountAmount, isNull);
      expect(controller.state.preview.totalAfterDiscount, 4400);
    });

    test('order fixed normalizes to percentage when item scope is selected',
        () {
      final controller = PosDiscountController(
          currencyCode: 'LKR', subtotal: 4400, itemCount: 2);
      controller
          .selectCalculationMethod(PosDiscountCalculationMethod.fixedAmount);
      controller.selectScope(PosDiscountScope.item);
      expect(controller.state.calculationMethod,
          PosDiscountCalculationMethod.percentage);
      expect(controller.state.selectedCartLineKey, isNull);
    });

    test('validity requires value, item selection and backend validation',
        () async {
      final controller = PosDiscountController(
        currencyCode: 'LKR',
        subtotal: 4400,
        itemCount: 2,
        validateOnline: _validPreview,
      );
      controller.selectScope(PosDiscountScope.item);
      controller.updateValue('10');
      expect(controller.state.canApply, isFalse);
      controller.selectCartLine(_product.cartLineKey, _product.variantId, 3200);
      await Future<void>.delayed(const Duration(milliseconds: 400));
      expect(controller.state.canApply, isTrue);
      controller.updateValue('101');
      expect(controller.state.canApply, isFalse);
      expect(controller.state.valueError, contains('100'));
    });
  });

  testWidgets('popup renders target order states and never exposes policy UI',
      (tester) async {
    final harness = await _pump(tester);
    addTearDown(harness.dispose);

    expect(find.byKey(const Key('pos-discount-dialog')), findsOneWidget);
    expect(find.text('Add Discount'), findsOneWidget);
    expect(find.text('Order Level Discount'), findsOneWidget);
    expect(find.text('Item Level Discount'), findsOneWidget);
    expect(find.text('Percentage'), findsOneWidget);
    expect(find.text('Fixed Amount'), findsOneWidget);
    expect(find.text('Predefined'), findsNothing);
    expect(find.textContaining('Manager approval'), findsNothing);

    await tester.tap(find.byKey(const Key('discount-method-fixed')));
    await tester.pump();
    expect(find.text('LKR'), findsWidgets);
    expect(find.text('Discount Amount'), findsOneWidget);
  });

  testWidgets('item mode uses real cart lines and percentage only',
      (tester) async {
    final harness = await _pump(tester);
    addTearDown(harness.dispose);

    await tester.tap(find.byKey(const Key('discount-scope-item')));
    await tester.pump();

    expect(find.byKey(const Key('discount-cart-line-list')), findsOneWidget);
    expect(find.text('Training Jersey'), findsOneWidget);
    expect(find.text('Team Socks'), findsOneWidget);
    expect(find.byKey(const Key('discount-method-fixed')), findsNothing);

    final apply =
        tester.widget<FilledButton>(find.byKey(const Key('discount-apply')));
    expect(apply.onPressed, isNull);

    await tester
        .tap(find.byKey(Key('discount-cart-line-${_product.cartLineKey}')));
    await tester.enterText(find.byKey(const Key('discount-value-field')), '10');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump();
    expect(find.byKey(const Key('discount-selected-item-summary')),
        findsOneWidget);
    expect(find.text('LKR 3,200.00'), findsWidgets);
    expect(
        tester
            .widget<FilledButton>(find.byKey(const Key('discount-apply')))
            .onPressed,
        isNotNull);
  });

  testWidgets('reason is optional and helper chip only fills reason text',
      (tester) async {
    final harness = await _pump(tester);
    addTearDown(harness.dispose);

    await tester.ensureVisible(find.byKey(const Key('discount-reason-vip')));
    await tester.tap(find.byKey(const Key('discount-reason-vip')));
    await tester.pump();
    final field = tester
        .widget<TextField>(find.byKey(const Key('discount-reason-field')));
    expect(field.controller?.text, 'VIP');
    expect(find.text('Discount Policy'), findsNothing);
  });

  testWidgets('submit callback is invoked once after authoritative validation',
      (tester) async {
    var submissions = 0;
    final harness = await _pump(
      tester,
      onSubmit: (_) async => submissions++,
    );
    addTearDown(harness.dispose);
    final before = harness.container.read(posNewSaleCartProvider);

    await tester.enterText(find.byKey(const Key('discount-value-field')), '10');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump();
    await tester.ensureVisible(find.byKey(const Key('discount-apply')));
    expect(
      tester
          .widget<FilledButton>(find.byKey(const Key('discount-apply')))
          .onPressed,
      isNotNull,
    );
    await tester.tap(find.byKey(const Key('discount-apply')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('pos-discount-dialog')), findsOneWidget);
    expect(submissions, 1);
    expect(harness.container.read(posNewSaleCartProvider).discount,
        before.discount);
  });

  testWidgets('permission denial blocks add flow', (tester) async {
    final harness = await _pump(tester, permissions: const {});
    addTearDown(harness.dispose);
    expect(find.text('Discount permission required'), findsOneWidget);
    expect(find.byKey(const Key('discount-apply')), findsNothing);
  });

  testWidgets('existing discount blocks a second add flow', (tester) async {
    final harness = await _pump(tester, activeDiscount: true);
    addTearDown(harness.dispose);
    expect(find.text('Discount already applied'), findsOneWidget);
    expect(find.byKey(const Key('discount-apply')), findsNothing);
  });

  testWidgets('empty cart is safe', (tester) async {
    final harness = await _pump(tester, addItems: false);
    addTearDown(harness.dispose);
    expect(find.text('Cart is empty'), findsOneWidget);
    expect(find.byKey(const Key('discount-apply')), findsNothing);
  });

  testWidgets(
      'no overflow on small tablet, narrow layout, keyboard and text scale',
      (tester) async {
    for (final size in const [
      Size(2560, 1600),
      Size(1680, 1050),
      Size(1280, 800),
      Size(800, 600),
      Size(520, 720),
    ]) {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final harness = await _pump(
        tester,
        textScaler: const TextScaler.linear(1.25),
        viewInsets: const EdgeInsets.only(bottom: 180),
      );
      await tester.pump();
      expect(tester.takeException(), isNull, reason: 'viewport $size');
      expect(find.byKey(const Key('discount-dialog-scroll')), findsOneWidget);
      harness.dispose();
    }
  });
}

class _Harness {
  const _Harness(this.container);
  final ProviderContainer container;
  void dispose() => container.dispose();
}

Future<_Harness> _pump(
  WidgetTester tester, {
  Set<String> permissions = const {PosPermissionCodes.applySaleDiscount},
  bool addItems = true,
  bool activeDiscount = false,
  TextScaler textScaler = TextScaler.noScaling,
  EdgeInsets viewInsets = EdgeInsets.zero,
  PosDiscountPresentationSubmit? onSubmit,
}) async {
  final session = AuthSession(
    accessToken: 'test-token',
    userId: 'cashier-1',
    userDisplayName: 'Cashier',
    permissionCodes: permissions.toList(),
  );
  final container = ProviderContainer(overrides: [
    authSessionProvider
        .overrideWith((ref) => _PresetAuthSessionNotifier(session)),
    posDiscountControllerProvider.overrideWith((ref, args) {
      return PosDiscountController(
        currencyCode: args.currencyCode,
        subtotal: args.subtotal,
        itemCount: args.itemCount,
        validateOnline: _validPreview,
      );
    }),
    posDiscountCatalogProvider.overrideWith((ref, query) async {
      return const PosDiscountCatalog(
        authority: PosDiscountAuthority(
          maxPercentage: 20,
          maxFixedAmount: 5000,
          currencyCode: 'LKR',
        ),
        discounts: [],
      );
    }),
  ]);
  if (addItems) {
    container.read(posNewSaleCartProvider.notifier)
      ..addToCart(_product)
      ..addToCart(_secondProduct);
  }
  if (activeDiscount) {
    container.read(posNewSaleCartProvider.notifier).applyCartDiscount(
          const PosCartDiscount(
              valueType: PosDiscountValueType.percentage, value: 10),
        );
  }

  await tester.pumpWidget(UncontrolledProviderScope(
    container: container,
    child: MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(
          size: tester.view.physicalSize,
          textScaler: textScaler,
          viewInsets: viewInsets,
        ),
        child: Scaffold(body: PosDiscountDialog(onSubmit: onSubmit)),
      ),
    ),
  ));
  await tester.pump();
  return _Harness(container);
}

class _FakeAuthSessionStorage extends AuthSessionStorage {
  _FakeAuthSessionStorage()
      : super(const AppSecureStorage(FlutterSecureStorage()));
  @override
  Future<AuthSession?> read() async => null;
  @override
  Future<void> save(AuthSession session) async {}
  @override
  Future<void> clear() async {}
}

class _PresetAuthSessionNotifier extends AuthSessionNotifier {
  _PresetAuthSessionNotifier(AuthSession session)
      : super(_FakeAuthSessionStorage()) {
    state = session;
  }
}

const _product = PosNewSaleProduct(
  id: 'product-1',
  productId: 'product-1',
  variantId: 'variant-small',
  name: 'Training Jersey',
  category: 'Apparel',
  price: 3200,
  selectedAttributes: {'Size': 'Small'},
);

const _secondProduct = PosNewSaleProduct(
  id: 'product-2',
  productId: 'product-2',
  variantId: 'variant-socks',
  name: 'Team Socks',
  category: 'Apparel',
  price: 1200,
);

Future<PosDiscountValidationResult> _validPreview(
  PosDiscountPresentationState state,
) async {
  final eligible = state.scope == PosDiscountScope.item
      ? state.preview.eligibleSubtotal
      : state.currentSubtotal;
  final requested = state.parsedRequestedValue ?? 0;
  final amount =
      state.calculationMethod == PosDiscountCalculationMethod.percentage
          ? (eligible * requested / 100).round()
          : requested.round();
  return PosDiscountValidationResult(
    discountId: '',
    isValid: true,
    outcome: 'DIRECT_APPLY',
    calculationMethod: state.calculationMethod.name.toUpperCase(),
    requestedValue: requested,
    cashierLimit: 20,
    absoluteLimit: 20,
    subtotal: state.currentSubtotal,
    eligibleSubtotal: eligible,
    discountAmount: amount,
    totalAfterDiscount: state.currentSubtotal - amount,
    currencyCode: state.currencyCode,
    cartHash: 'test-cart-hash',
    validationMessages: const [],
  );
}
