import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:nytroz_pos/app/app.dart';
import 'package:nytroz_pos/core/access/pos_access_codes.dart';
import 'package:nytroz_pos/core/network/dio_provider.dart';
import 'package:nytroz_pos/core/storage/app_secure_storage.dart';
import 'package:nytroz_pos/features/auth/data/datasources/auth_session_storage.dart';
import 'package:nytroz_pos/features/auth/domain/entities/auth_session.dart';
import 'package:nytroz_pos/features/auth/presentation/providers/post_login_navigation_provider.dart';
import 'package:nytroz_pos/features/auth/presentation/providers/session_provider.dart';
import 'package:nytroz_pos/features/pos/presentation/providers/pos_catalog_provider.dart';
import 'package:nytroz_pos/features/pos/domain/entities/pos_catalog_models.dart';
import 'package:nytroz_pos/features/cart/presentation/providers/pos_new_sale_cart_provider.dart';
import 'package:nytroz_pos/features/device_activation/application/usecases/activate_device.dart';
import 'package:nytroz_pos/features/device_activation/data/datasources/device_context_storage.dart';
import 'package:nytroz_pos/features/device_activation/domain/entities/pos_device_context.dart';
import 'package:nytroz_pos/features/device_activation/domain/repositories/device_activation_repository.dart';
import 'package:nytroz_pos/features/device_activation/presentation/providers/device_activation_provider.dart';
import 'package:nytroz_pos/features/pos_shell/application/state/pos_home_dashboard_state.dart';
import 'package:nytroz_pos/features/pos_shell/domain/entities/pos_home_action.dart';
import 'package:nytroz_pos/features/pos_shell/presentation/providers/pos_home_dashboard_provider.dart';
import 'package:nytroz_pos/features/pos_shell/presentation/screens/pos_home_screen.dart';
import 'package:nytroz_pos/features/pos/presentation/screens/new_sale/pos_new_sale_screen.dart';
import 'package:nytroz_pos/features/sale/presentation/widgets/new_sale/pos_product_variant_sheet.dart';
import 'package:nytroz_pos/features/sale/data/datasources/pos_checkout_remote_datasource.dart';
import 'package:nytroz_pos/features/sale/domain/entities/pos_checkout_summary.dart';
import 'package:nytroz_pos/features/sale/presentation/providers/pos_checkout_summary_provider.dart';
import 'package:nytroz_pos/shared/pos_session/pos_session_bootstrap_provider.dart';

import '../../support/pos_catalog_test_fixtures.dart';

Future<void> _tapProduct(WidgetTester tester, String productName) async {
  final productFinder = find.text(productName);
  final productCard = find
      .ancestor(
        of: productFinder,
        matching: find.byType(InkWell),
      )
      .first;
  final inkWell = tester.widget<InkWell>(productCard);
  expect(inkWell.onTap, isNotNull);
  inkWell.onTap!();
  await tester.pumpAndSettle();
}

void main() {
  group('POS product variant flow', () {
    testWidgets('simple product tap adds directly to cart', (tester) async {
      await _pumpNewSaleWithVariantCatalog(tester);
      await _tapProduct(tester, 'General Admission');

      expect(find.text('Qty 1'), findsOneWidget);
      expect(find.byType(PosProductVariantSheet), findsNothing);
    });

    testWidgets('variant product tap opens selector with API option groups', (
      tester,
    ) async {
      await _pumpNewSaleWithVariantCatalog(
        tester,
        catalog: const PosNewSaleCatalogState(
          products: [testVariableProductSummary],
        ),
      );
      await _tapProduct(tester, 'Pro Team Jersey');

      expect(find.byType(PosProductVariantSheet), findsOneWidget);
      expect(find.text('Size'), findsOneWidget);
      expect(find.text('Color'), findsOneWidget);
      expect(find.text('Small'), findsOneWidget);
      expect(find.text('Blue'), findsOneWidget);
      expect(find.text('LKR 10,000.00'), findsWidgets);
      expect(
        find.descendant(
          of: find.byType(PosProductVariantSheet),
          matching: find.byType(AspectRatio),
        ),
        findsOneWidget,
      );
      expect(find.byKey(const Key('recommendation-panel')), findsOneWidget);
      expect(find.byKey(const Key('compact-quantity-stepper')), findsOneWidget);
      expect(find.widgetWithText(OutlinedButton, 'Cancel'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back), findsNothing);
      expect(find.byIcon(Icons.arrow_forward), findsNothing);
      expect(find.byType(ChoiceChip), findsNWidgets(4));
      final addButton = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Add to Cart'),
      );
      expect(
        addButton.style?.backgroundColor?.resolve(<WidgetState>{}),
        const Color(0xFFFF3B0A),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('variant selector remains usable at smaller tablet width', (
      tester,
    ) async {
      await _pumpNewSaleWithVariantCatalog(
        tester,
        size: const Size(800, 700),
        catalog: const PosNewSaleCatalogState(
          products: [testVariableProductSummary],
        ),
      );
      await _tapProduct(tester, 'Pro Team Jersey');

      expect(find.byType(PosProductVariantSheet), findsOneWidget);
      expect(find.text('Size'), findsOneWidget);
      expect(find.text('Color'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Add to Cart'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
      'wide tablet popup shows actions without details scrolling',
      (tester) async {
        await _pumpNewSaleWithVariantCatalog(
          tester,
          size: const Size(1280, 800),
          catalog: const PosNewSaleCatalogState(
            products: [testVariableProductSummary],
          ),
        );
        await _tapProduct(tester, 'Pro Team Jersey');

        final detailsScroll = find
            .descendant(
              of: find.byKey(const Key('variant-details-scroll')),
              matching: find.byType(Scrollable),
            )
            .first;
        final scrollable = tester.state<ScrollableState>(detailsScroll);
        expect(scrollable.position.maxScrollExtent, 0);
        expect(
          find.widgetWithText(FilledButton, 'Add to Cart').hitTestable(),
          findsOneWidget,
        );
        expect(
          find.widgetWithText(OutlinedButton, 'Cancel').hitTestable(),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('variant selector stacks safely at mobile portrait width', (
      tester,
    ) async {
      await _pumpNewSaleWithVariantCatalog(
        tester,
        size: const Size(390, 844),
        catalog: const PosNewSaleCatalogState(
          products: [testVariableProductSummary],
        ),
      );
      await _tapProduct(tester, 'Pro Team Jersey');

      expect(find.byType(PosProductVariantSheet), findsOneWidget);
      expect(find.byKey(const Key('recommendation-panel')), findsOneWidget);
      final addButton = find.widgetWithText(FilledButton, 'Add to Cart');
      await tester.ensureVisible(addButton);
      expect(addButton, findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('selected variant price updates and adds separate cart line', (
      tester,
    ) async {
      await _pumpNewSaleWithVariantCatalog(
        tester,
        catalog: const PosNewSaleCatalogState(
          products: [testVariableProductSummary],
        ),
      );
      await _tapProduct(tester, 'Pro Team Jersey');

      await tester.tap(find.text('Medium'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Blue'));
      await tester.pumpAndSettle();

      expect(find.text('LKR 12,000.00'), findsWidgets);

      final addButton = find.widgetWithText(FilledButton, 'Add to Cart');
      await tester.ensureVisible(addButton);
      expect(tester.widget<FilledButton>(addButton).onPressed, isNotNull);
      await tester.tap(addButton);
      await tester.pumpAndSettle();

      expect(find.text('Qty 1'), findsOneWidget);
      expect(find.text('LKR 12,000.00'), findsWidgets);

      final container = ProviderScope.containerOf(
        tester.element(find.byType(PosNewSaleScreen)),
      );
      final cartItems = container.read(posNewSaleCartProvider).itemList;
      expect(cartItems, hasLength(1));
      expect(cartItems.single.product.variantId, 'variant-medium-blue');
      expect(cartItems.single.product.price, 12000);
      expect(_lastCheckoutLines, isNotEmpty);
      expect(
        _lastCheckoutLines.every(
          (line) => RegExp(
            r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
          ).hasMatch(line.clientLineId ?? ''),
        ),
        isTrue,
      );
    });

    testWidgets('out-of-stock variant cannot be added', (tester) async {
      await _pumpNewSaleWithVariantCatalog(
        tester,
        catalog: const PosNewSaleCatalogState(
          products: [testVariableProductSummary],
        ),
      );
      await _tapProduct(tester, 'Pro Team Jersey');

      await tester.tap(find.text('Small'));
      await tester.pumpAndSettle();

      final redChip = tester.widget<ChoiceChip>(
        find.widgetWithText(ChoiceChip, 'Red'),
      );
      expect(redChip.onSelected, isNull);
      expect(
        tester
            .widget<FilledButton>(
                find.widgetWithText(FilledButton, 'Add to Cart'))
            .onPressed,
        isNull,
      );
    });

    testWidgets('local cart rejection keeps popup open and reports failure', (
      tester,
    ) async {
      const unavailableDetail = PosCatalogProductDetail(
        summary: testVariableProductSummary,
        currency: 'LKR',
        variantGroups: [
          PosCatalogVariantGroup(
            name: 'Size',
            options: ['Small'],
            optionId: 'option-size',
            values: [
              PosCatalogOptionValue(
                optionValueId: 'size-small',
                code: 'S',
                displayName: 'Small',
              ),
            ],
          ),
        ],
        variants: [
          PosCatalogVariant(
            variantId: 'variant-unavailable',
            sku: 'JER-S',
            price: 10000,
            stockStatus: 'InStock',
            stockQty: 1,
            attributes: {'Size': 'Small'},
            selectedOptionValueIds: ['size-small'],
            salesUomId: 'uom-each',
            authoritativePrice: 10000,
            currency: 'LKR',
            isDefault: true,
          ),
        ],
      );
      await _pumpNewSaleWithVariantCatalog(
        tester,
        catalog: const PosNewSaleCatalogState(
          products: [testVariableProductSummary],
        ),
        productDetail: unavailableDetail,
      );
      final container = ProviderScope.containerOf(
        tester.element(find.byType(PosNewSaleScreen)),
      );
      container.read(posNewSaleCartProvider.notifier).addToCart(
            const PosNewSaleProduct(
              id: 'variant-unavailable',
              productId: testVariableProductId,
              variantId: 'variant-unavailable',
              name: 'Pro Team Jersey',
              category: 'Retail',
              price: 10000,
              stockStatus: 'InStock',
              maxQuantity: 1,
              uomId: 'uom-each',
            ),
          );
      await _tapProduct(tester, 'Pro Team Jersey');

      final addButton = find.widgetWithText(FilledButton, 'Add to Cart');
      await tester.ensureVisible(addButton);
      expect(tester.widget<FilledButton>(addButton).onPressed, isNotNull);
      await tester.tap(addButton);
      await tester.pumpAndSettle();

      expect(find.byType(PosProductVariantSheet), findsOneWidget);
      expect(
        find.text('The requested quantity is no longer available.'),
        findsOneWidget,
      );
      expect(container.read(posNewSaleCartProvider).items, hasLength(1));
      expect(
          container.read(posNewSaleCartProvider).itemList.single.quantity, 1);
    });
  });
}

Future<void> _pumpNewSaleWithVariantCatalog(
  WidgetTester tester, {
  PosNewSaleCatalogState? catalog,
  PosCatalogProductDetail productDetail = testVariableProductDetail,
  Size size = const Size(1280, 900),
}) async {
  _lastCheckoutLines = const [];
  const permissionCodes = [
    PosPermissionCodes.viewHome,
    PosPermissionCodes.viewNewSale,
    PosPermissionCodes.viewProducts,
    PosPermissionCodes.addCartItem,
    PosPermissionCodes.updateCartItem,
    PosPermissionCodes.removeCartItem,
    PosPermissionCodes.viewReturns,
    PosPermissionCodes.viewNewSaleCustomers,
    PosPermissionCodes.createParkedSale,
    PosPermissionCodes.viewCashDrawer,
  ];
  const testSession = AuthSession(
    accessToken: 'test-access-token',
    userId: 'test-user',
    userDisplayName: 'Cashier',
    permissionCodes: permissionCodes,
  );

  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        appDioProvider.overrideWithValue(
          Dio(BaseOptions(baseUrl: 'https://test.local')),
        ),
        deviceContextStorageProvider.overrideWithValue(_TestDeviceStorage()),
        activateDeviceProvider.overrideWithValue(
          ActivateDevice(_TestDeviceRepository()),
        ),
        deviceActivationProvider.overrideWith(
          (ref) => _TestDeviceController(
            ref.watch(activateDeviceProvider),
            ref.watch(deviceContextStorageProvider),
          ),
        ),
        authSessionStorageProvider.overrideWithValue(
          _VariantFlowAuthSessionStorage(testSession),
        ),
        postLoginRouteProvider.overrideWithValue(PostLoginRoute.posHome),
        posSessionBootstrapProvider.overrideWith((ref) {
          final notifier = PosSessionBootstrapNotifier(ref, autoStart: false);
          notifier.state = const PosSessionBootstrapState(isReady: true);
          return notifier;
        }),
        posHomeDashboardProvider.overrideWith(
          (ref) async => PosHomeDashboardState(
            fallbackUserDisplayName: 'Cashier',
            tillLabel: 'Front Till',
            tillStatusLabel: 'Open',
            isTillOpen: true,
            statusMessage: 'Ready for sales',
            startSaleButtonLabel: 'Start New Sale',
            isPosEnabled: true,
            isTrustedDevice: true,
            hasOpenTillSession: true,
            enabledFeatureKeys: const {
              PosFeatureCodes.sales,
              PosFeatureCodes.customers,
              PosFeatureCodes.returns,
              PosFeatureCodes.till,
            },
            grantedPermissionKeys: permissionCodes.toSet(),
            actions: [
              const PosHomeAction(
                key: 'start-new-sale',
                label: 'Start New Sale',
                description: 'Begin a new in-store sale.',
                iconKey: 'new-sale',
                buttonLabel: 'Start New Sale',
                isEnabled: true,
                targetRoute: '/pos/new-sale',
                featureKey: PosFeatureCodes.sales,
                permissionKey: PosPermissionCodes.viewNewSale,
              ),
              const PosHomeAction(
                key: 'returns-refunds',
                label: 'Returns & Refunds',
                description: 'Review eligible items for return or refund.',
                iconKey: 'return',
                buttonLabel: 'Start Return',
                isEnabled: true,
                targetRoute: '/pos/returns-refunds',
                featureKey: PosFeatureCodes.returns,
                permissionKey: PosPermissionCodes.viewReturns,
              ),
              const PosHomeAction(
                key: 'add-customer',
                label: 'Add Customer',
                description: 'Create a customer profile for future visits.',
                iconKey: 'add-customer',
                buttonLabel: 'Add Customer',
                isEnabled: true,
                targetRoute: '/pos/customers',
                featureKey: PosFeatureCodes.customers,
                permissionKey: PosPermissionCodes.viewNewSaleCustomers,
              ),
              const PosHomeAction(
                key: 'parked-sales',
                label: 'Parked Sales',
                description: 'View sales that were parked for later.',
                iconKey: 'parked-sales',
                buttonLabel: 'View Parked Sales',
                isEnabled: true,
                targetRoute: '/pos/parked-sales',
                featureKey: PosFeatureCodes.sales,
                permissionKey: PosPermissionCodes.createParkedSale,
              ),
              const PosHomeAction(
                key: 'cash-drawer',
                label: 'Cash Drawer',
                description: 'View the current till cash summary.',
                iconKey: 'cash-drawer',
                buttonLabel: 'View Cash Drawer',
                isEnabled: true,
                targetRoute: '/pos/cash-drawer',
                featureKey: PosFeatureCodes.till,
                permissionKey: PosPermissionCodes.viewCashDrawer,
              ),
            ],
          ),
        ),
        posNewSaleCategoriesProvider.overrideWith(
          (ref) async => testPosCatalogCategories,
        ),
        posNewSaleCatalogProvider.overrideWith((ref) async {
          if (catalog != null) {
            return catalog;
          }

          final selectedCategoryId =
              ref.watch(posNewSaleSelectedCategoryIdProvider);
          return testPosCatalogStateForCategory(selectedCategoryId);
        }),
        posProductDetailProvider.overrideWith((ref, productId) async {
          if (productId == testVariableProductId) {
            return productDetail;
          }
          throw StateError('Unexpected product detail request: $productId');
        }),
        posCheckoutRemoteDatasourceProvider.overrideWithValue(
          _SuccessfulCheckoutDatasource(),
        ),
      ],
      child: const NytrozPosApp(),
    ),
  );
  await tester.pumpAndSettle();

  final context = tester.element(find.byType(PosHomeScreen));
  context.go('/pos/new-sale');
  await tester.pumpAndSettle();
}

class _SuccessfulCheckoutDatasource extends PosCheckoutRemoteDatasource {
  _SuccessfulCheckoutDatasource() : super(Dio());

  @override
  Future<PosCheckoutSummaryPayload> getCheckoutSummary({
    required String deviceId,
    required List<PosCheckoutLineRequest> lines,
    String saleType = 'NewSale',
    String? customerId,
    String? discountApplicationId,
  }) async {
    _lastCheckoutLines = List.unmodifiable(lines);
    return PosCheckoutSummaryPayload.fromJson(const {});
  }
}

List<PosCheckoutLineRequest> _lastCheckoutLines = const [];

final _testDeviceContext = PosDeviceContext(
  deviceId: '00000000-0000-0000-0000-000000000001',
  deviceCode: 'DEV-001',
  deviceName: 'Test POS',
  deviceType: 'fixed_pos_tablet',
  platform: 'test',
  deviceFingerprint: 'variant-popup-test-device',
  isTrusted: true,
  tenantId: 'tenant-1',
  outletId: 'outlet-1',
  outletName: 'Test Outlet',
  tillId: 'till-1',
  tillCode: 'TILL-1',
  tillName: 'Test Till',
  pairedAt: DateTime.utc(2026, 1, 1),
);

class _TestDeviceController extends DeviceActivationController {
  _TestDeviceController(super.activateDevice, super.storage) : super() {
    state = DeviceActivationState(deviceContext: _testDeviceContext);
  }
}

class _TestDeviceRepository implements DeviceActivationRepository {
  @override
  Future<PosDeviceContext> activateDevice(DeviceActivationForm form) async =>
      _testDeviceContext;

  @override
  Future<PosDeviceContext?> getCurrentDevice(DeviceActivationForm form) async =>
      _testDeviceContext;
}

class _TestDeviceStorage extends DeviceContextStorage {
  _TestDeviceStorage() : super(const AppSecureStorage(FlutterSecureStorage()));
  @override
  Future<PosDeviceContext?> read() async => _testDeviceContext;
  @override
  Future<String> readOrCreateDeviceFingerprint() async =>
      _testDeviceContext.deviceFingerprint;
  @override
  Future<List<String>> readDeviceFingerprintCandidates() async =>
      [_testDeviceContext.deviceFingerprint];
  @override
  Future<void> save(PosDeviceContext context) async {}
  @override
  Future<void> clear() async {}
}

class _VariantFlowAuthSessionStorage extends AuthSessionStorage {
  _VariantFlowAuthSessionStorage(this.session)
      : super(const AppSecureStorage(FlutterSecureStorage()));

  final AuthSession session;

  @override
  Future<AuthSession?> read() async => session;

  @override
  Future<void> save(AuthSession session) async {}

  @override
  Future<void> clear() async {}
}
