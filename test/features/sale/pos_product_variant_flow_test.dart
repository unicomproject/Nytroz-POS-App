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
import 'package:nytroz_pos/features/cart/presentation/providers/pos_catalog_provider.dart';
import 'package:nytroz_pos/features/cart/presentation/providers/pos_new_sale_cart_provider.dart';
import 'package:nytroz_pos/features/pos_shell/application/state/pos_home_dashboard_state.dart';
import 'package:nytroz_pos/features/pos_shell/domain/entities/pos_home_action.dart';
import 'package:nytroz_pos/features/pos_shell/presentation/providers/pos_home_dashboard_provider.dart';
import 'package:nytroz_pos/features/pos_shell/presentation/screens/pos_home_screen.dart';
import 'package:nytroz_pos/features/sale/presentation/screens/pos_new_sale_screen.dart';
import 'package:nytroz_pos/features/sale/presentation/widgets/new_sale/pos_product_variant_sheet.dart';
import 'package:nytroz_pos/shared/pos_session/pos_session_bootstrap_provider.dart';

import '../../support/pos_catalog_test_fixtures.dart';

Future<void> _tapProduct(WidgetTester tester, String productName) async {
  final productFinder = find.text(productName);
  await tester.tap(productFinder);
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

      await tester.tap(find.widgetWithText(FilledButton, 'Add to Cart'));
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
  });
}

Future<void> _pumpNewSaleWithVariantCatalog(
  WidgetTester tester, {
  PosNewSaleCatalogState? catalog,
}) async {
  const size = Size(1280, 900);
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
            return testVariableProductDetail;
          }
          throw StateError('Unexpected product detail request: $productId');
        }),
      ],
      child: const NytrozPosApp(),
    ),
  );
  await tester.pumpAndSettle();

  final context = tester.element(find.byType(PosHomeScreen));
  context.go('/pos/new-sale');
  await tester.pumpAndSettle();
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
