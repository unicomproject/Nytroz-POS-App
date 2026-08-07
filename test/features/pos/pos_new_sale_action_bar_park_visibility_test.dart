import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nytroz_pos/core/access/pos_access_codes.dart';
import 'package:nytroz_pos/core/storage/app_secure_storage.dart';
import 'package:nytroz_pos/features/auth/data/datasources/auth_session_storage.dart';
import 'package:nytroz_pos/features/auth/domain/entities/auth_session.dart';
import 'package:nytroz_pos/features/auth/presentation/providers/session_provider.dart';
import 'package:nytroz_pos/features/cart/data/models/pos_parked_sale_dtos.dart';
import 'package:nytroz_pos/features/cart/domain/repositories/pos_parked_sale_repository.dart';
import 'package:nytroz_pos/features/cart/domain/entities/pos_cart_discount.dart';
import 'package:nytroz_pos/features/cart/presentation/providers/pos_new_sale_cart_provider.dart';
import 'package:nytroz_pos/features/cart/presentation/providers/pos_parked_sale_provider.dart';
import 'package:nytroz_pos/features/pos/presentation/widgets/new_sale/actions/pos_new_sale_action_bar.dart';
import 'package:nytroz_pos/features/sale/domain/entities/pos_customer.dart';
import 'package:nytroz_pos/features/tenant_admin/presentation/theme/tenant_admin_theme.dart';

// Verifies the mutually-exclusive Park Sale / Recall Sale visibility
// contract on `PosNewSaleActionBar`:
//   - non-empty cart + createParkedSale permission -> "Park Sale" only
//   - empty cart + viewBackendParkedSales permission -> "Recall Sale" only
//   - the applicable action's own permission gates it; the other action's
//     permission never substitutes and a disabled wrong-label button is
//     never shown.
void main() {
  testWidgets('non-empty cart with create permission shows Park Sale only',
      (tester) async {
    final harness = await _pump(
      tester,
      hasItems: true,
      permissions: const {PosPermissionCodes.createParkedSale},
    );
    addTearDown(harness.dispose);

    expect(find.text('Park Sale'), findsOneWidget);
    expect(find.text('Recall Sale'), findsNothing);
  });

  testWidgets('empty cart with view permission shows Recall Sale only',
      (tester) async {
    final harness = await _pump(
      tester,
      hasItems: false,
      permissions: const {PosPermissionCodes.viewBackendParkedSales},
    );
    addTearDown(harness.dispose);

    expect(find.text('Recall Sale'), findsOneWidget);
    expect(find.text('Park Sale'), findsNothing);
  });

  testWidgets(
      'non-empty cart missing create permission hides the action entirely '
      '(even though view permission is granted)', (tester) async {
    final harness = await _pump(
      tester,
      hasItems: true,
      permissions: const {PosPermissionCodes.viewBackendParkedSales},
    );
    addTearDown(harness.dispose);

    expect(find.text('Park Sale'), findsNothing);
    expect(find.text('Recall Sale'), findsNothing);
  });

  testWidgets(
      'empty cart missing view permission hides the action entirely '
      '(even though create permission is granted)', (tester) async {
    final harness = await _pump(
      tester,
      hasItems: false,
      permissions: const {PosPermissionCodes.createParkedSale},
    );
    addTearDown(harness.dispose);

    expect(find.text('Recall Sale'), findsNothing);
    expect(find.text('Park Sale'), findsNothing);
  });

  testWidgets(
      'both permissions granted still only shows the applicable '
      'action for a non-empty cart', (tester) async {
    final harness = await _pump(
      tester,
      hasItems: true,
      permissions: const {
        PosPermissionCodes.createParkedSale,
        PosPermissionCodes.viewBackendParkedSales,
      },
    );
    addTearDown(harness.dispose);

    expect(find.text('Park Sale'), findsOneWidget);
    expect(find.text('Recall Sale'), findsNothing);
  });

  testWidgets(
      'both permissions granted still only shows the applicable '
      'action for an empty cart', (tester) async {
    final harness = await _pump(
      tester,
      hasItems: false,
      permissions: const {
        PosPermissionCodes.createParkedSale,
        PosPermissionCodes.viewBackendParkedSales,
      },
    );
    addTearDown(harness.dispose);

    expect(find.text('Recall Sale'), findsOneWidget);
    expect(find.text('Park Sale'), findsNothing);
  });

  testWidgets('neither permission granted shows no parked-sale action',
      (tester) async {
    final harness = await _pump(
      tester,
      hasItems: true,
      permissions: const {},
    );
    addTearDown(harness.dispose);

    expect(find.text('Park Sale'), findsNothing);
    expect(find.text('Recall Sale'), findsNothing);
  });

  testWidgets(
      'clear-cart confirmation uses the POS destructive theme and sizing',
      (tester) async {
    final harness = await _pump(
      tester,
      hasItems: true,
      permissions: const {PosPermissionCodes.clearCart},
    );
    addTearDown(harness.dispose);

    await tester.tap(find.widgetWithText(FilledButton, 'Clear Cart'));
    await tester.pumpAndSettle();

    final dialog = tester.widget<AlertDialog>(
      find.byKey(const ValueKey('clear-cart-dialog')),
    );
    expect(dialog.backgroundColor, TenantAdminColors.surface);
    expect(dialog.surfaceTintColor, TenantAdminColors.surface);

    final cancel = tester.widget<OutlinedButton>(
      find.byKey(const ValueKey('clear-cart-cancel')),
    );
    expect(cancel.style?.minimumSize?.resolve(<WidgetState>{}),
        const Size(120, 48));

    final confirm = tester.widget<FilledButton>(
      find.byKey(const ValueKey('clear-cart-confirm')),
    );
    expect(confirm.style?.minimumSize?.resolve(<WidgetState>{}),
        const Size(148, 48));
    expect(
      confirm.style?.backgroundColor?.resolve(<WidgetState>{}),
      TenantAdminColors.posNewSaleClearAction,
    );
  });

  testWidgets('customer-only cart remains empty and shows Recall Sale only',
      (tester) async {
    final harness = await _pump(
      tester,
      hasItems: false,
      permissions: const {
        PosPermissionCodes.createParkedSale,
        PosPermissionCodes.viewBackendParkedSales,
      },
      attachCustomer: true,
    );
    addTearDown(harness.dispose);

    final cart = harness.container.read(posNewSaleCartProvider);
    expect(cart.hasItems, isFalse);
    expect(cart.selectedCustomer, isNotNull);
    expect(find.text('Recall Sale'), findsOneWidget);
    expect(find.text('Park Sale'), findsNothing);
  });

  testWidgets('discount-only cart remains empty and shows Recall Sale only',
      (tester) async {
    final harness = await _pump(
      tester,
      hasItems: false,
      permissions: const {
        PosPermissionCodes.createParkedSale,
        PosPermissionCodes.viewBackendParkedSales,
      },
      discountOnlyCart: true,
    );
    addTearDown(harness.dispose);

    final cart = harness.container.read(posNewSaleCartProvider);
    expect(cart.hasItems, isFalse);
    expect(cart.cartDiscount, isNotNull);
    expect(find.text('Recall Sale'), findsOneWidget);
    expect(find.text('Park Sale'), findsNothing);
  });
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

class _Repo implements PosParkedSaleRepository {
  @override
  Future<PosHoldListDto> list(
          {required String deviceId,
          required String scope,
          required int page,
          required int pageSize}) async =>
      const PosHoldListDto([], 0);
  @override
  Future<void> cancel(String holdId, {String? reason}) async {}
  @override
  Future<PosRecallHoldDto> recall(String holdId, String deviceId) =>
      throw UnimplementedError();
  @override
  Future<PosHoldDto> create(PosCreateHoldRequestDto request) =>
      throw UnimplementedError();
}

const _product = PosNewSaleProduct(
    id: 'product-1',
    productId: 'product-1',
    variantId: 'variant-1',
    name: 'Team Jersey',
    category: 'Apparel',
    price: 1500);

Future<_Harness> _pump(
  WidgetTester tester, {
  required bool hasItems,
  required Set<String> permissions,
  bool attachCustomer = false,
  bool discountOnlyCart = false,
}) async {
  final session = AuthSession(
    accessToken: 'test-token',
    userId: 'user-1',
    userDisplayName: 'Test Cashier',
    permissionCodes: permissions.toList(),
  );
  final container = ProviderContainer(overrides: [
    authSessionProvider.overrideWith(
      (ref) => _PresetAuthSessionNotifier(session),
    ),
    posParkedSaleRepositoryProvider.overrideWithValue(_Repo()),
    posParkedSaleAccessContextProvider.overrideWithValue(
      PosParkedSaleAccessContext(
        authenticated: true,
        trustedDevice: true,
        deviceId: 'device-1',
        permissions: permissions,
      ),
    ),
    if (discountOnlyCart)
      posNewSaleCartProvider.overrideWith(_DiscountOnlyCartNotifier.new),
  ]);
  if (hasItems) {
    container.read(posNewSaleCartProvider.notifier).addToCart(_product);
  }
  if (attachCustomer) {
    container.read(posNewSaleCartProvider.notifier).setCustomer(
          const PosCustomer(
            customerId: 'customer-1',
            fullName: 'Walk-in Guest',
          ),
        );
  }
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(
        home: Scaffold(body: PosNewSaleActionBar()),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return _Harness(container);
}

class _DiscountOnlyCartNotifier extends PosNewSaleCartNotifier {
  @override
  PosNewSaleCartState build() => const PosNewSaleCartState(
        cartDiscount: PosCartDiscount(
          valueType: PosDiscountValueType.fixedAmount,
          value: 100,
          reason: 'Promo',
        ),
      );
}

class _Harness {
  const _Harness(this.container);
  final ProviderContainer container;
  void dispose() => container.dispose();
}
