import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:nytroz_pos/core/network/dio_provider.dart';
import 'package:nytroz_pos/features/pos/data/datasources/remote/pos_catalog_remote_datasource.dart';
import 'package:nytroz_pos/features/pos/domain/entities/pos_catalog_models.dart';
import 'package:nytroz_pos/features/pos/presentation/providers/pos_catalog_provider.dart';
import 'package:nytroz_pos/features/cart/presentation/providers/pos_new_sale_cart_provider.dart';
import 'package:nytroz_pos/features/pos/presentation/widgets/new_sale/catalogue/pos_product_category_chips.dart';
import 'package:nytroz_pos/features/pos/presentation/widgets/new_sale/product_card/pos_product_grid.dart';
import 'package:nytroz_pos/features/auth/presentation/providers/session_provider.dart';
import 'package:nytroz_pos/features/auth/domain/entities/auth_session.dart';
import 'package:nytroz_pos/features/auth/data/datasources/auth_session_storage.dart';
import 'package:nytroz_pos/features/device_activation/presentation/providers/device_activation_provider.dart';
import 'package:nytroz_pos/features/device_activation/domain/entities/pos_device_context.dart';
import 'package:nytroz_pos/features/device_activation/data/datasources/device_context_storage.dart';
import 'package:nytroz_pos/core/storage/app_secure_storage.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:nytroz_pos/features/sale/domain/entities/pos_customer.dart';

class FakeCatalogRemoteDatasource implements PosCatalogRemoteDatasource {
  @override
  Future<List<PosProductRecommendation>> getRecommendations({
    required String deviceId,
    required String productId,
    String? sourceVariantId,
  }) async =>
      const [];
  List<PosCatalogProductSummary> productsToReturn = [];
  String? lastSegment;
  String? lastCategoryId;
  String? lastSearch;
  int getProductsCount = 0;

  @override
  Future<List<PosCatalogProductSummary>> getProducts({
    required String deviceId,
    String? categoryId,
    String? search,
    String? segment,
  }) async {
    getProductsCount++;
    lastSegment = segment;
    lastCategoryId = categoryId;
    lastSearch = search;
    return productsToReturn;
  }

  @override
  Future<PosCatalogProductDetail> getProductDetail({
    required String deviceId,
    required String productId,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<List<PosCatalogCategory>> getCategories(
      {required String deviceId}) async {
    return const [
      PosCatalogCategory(id: 'cat-1', name: 'Apparel'),
      PosCatalogCategory(id: 'cat-2', name: 'Services'),
    ];
  }
}

class FakeAuthSessionStorage extends AuthSessionStorage {
  FakeAuthSessionStorage(this.session)
      : super(const AppSecureStorage(FlutterSecureStorage()));
  final AuthSession session;

  @override
  Future<AuthSession?> read() async => session;

  @override
  Future<void> save(AuthSession session) async {}

  @override
  Future<void> clear() async {}
}

class FakeDeviceContextStorage extends DeviceContextStorage {
  FakeDeviceContextStorage(this.context)
      : super(const AppSecureStorage(FlutterSecureStorage()));
  final PosDeviceContext context;

  @override
  Future<String?> readStoredDeviceFingerprint() async =>
      context.deviceFingerprint;

  @override
  Future<List<String>> readDeviceFingerprintCandidates() async =>
      [context.deviceFingerprint];

  @override
  Future<String> readOrCreateDeviceFingerprint() async =>
      context.deviceFingerprint;

  @override
  Future<PosDeviceContext?> read() async => context;

  @override
  Future<void> save(PosDeviceContext context) async {}

  @override
  Future<void> clear() async {}

  @override
  Future<void> clearContext() async {}
}

void main() {
  group('POS Offers Flow Tests', () {
    late FakeCatalogRemoteDatasource fakeDatasource;
    late AuthSession fakeSession;
    late PosDeviceContext fakeDeviceContext;

    const offerProduct = PosCatalogProductSummary(
      productId: 'prod-offer-1',
      categoryId: 'cat-1',
      name: 'Offer Product',
      categoryName: 'Apparel',
      basePrice: 2000,
      hasVariants: false,
      stockStatus: 'InStock',
      hasOffer: true,
      offerType: 'PERCENTAGE',
      offerPrice: 1600,
      discountLabel: '20% OFF',
      requiresCartValidation: false,
      requiresManagerApproval: true,
    );

    const conditionalOfferProduct = PosCatalogProductSummary(
      productId: 'prod-offer-2',
      categoryId: 'cat-2',
      name: 'Conditional Product',
      categoryName: 'Services',
      basePrice: 5000,
      hasVariants: false,
      stockStatus: 'InStock',
      hasOffer: true,
      offerType: 'FIXED_AMOUNT',
      discountLabel: 'Offer available',
      requiresCartValidation: true,
      requiresManagerApproval: false,
    );

    setUp(() {
      fakeDatasource = FakeCatalogRemoteDatasource();
      fakeSession = const AuthSession(
        accessToken: 'dummy-token',
        userId: 'user-1',
        userDisplayName: 'Cashier One',
        permissionCodes: ['products.view'],
      );
      fakeDeviceContext = PosDeviceContext(
        deviceId: 'device-1',
        deviceCode: 'DEV-1',
        deviceName: 'Register 1',
        deviceType: 'fixed_pos_tablet',
        platform: 'android',
        deviceFingerprint: 'fingerprint-1',
        isTrusted: true,
        tenantId: 'tenant-1',
        outletId: 'outlet-1',
        outletName: 'Main Store',
        tillId: 'till-1',
        tillCode: 'TILL-1',
        tillName: 'Front Till',
        pairedAt: DateTime(2026, 7, 1),
      );
    });

    ProviderContainer createContainer() {
      final container = ProviderContainer(
        overrides: [
          appDioProvider
              .overrideWithValue(Dio(BaseOptions(baseUrl: 'http://localhost'))),
          authSessionStorageProvider
              .overrideWithValue(FakeAuthSessionStorage(fakeSession)),
          deviceContextStorageProvider
              .overrideWithValue(FakeDeviceContextStorage(fakeDeviceContext)),
          posCatalogRemoteDatasourceProvider
              .overrideWith((ref) => fakeDatasource),
        ],
      );
      container.read(authSessionProvider.notifier);
      container.read(deviceActivationProvider.notifier);
      return container;
    }

    Future<void> hydrate(ProviderContainer container) async {
      await container.read(deviceActivationProvider.notifier).ensureHydrated();
      if (!container.read(authSessionHydratedProvider)) {
        await container
            .read(authSessionHydratedProvider.notifier)
            .stream
            .firstWhere((hydrated) => hydrated);
      }
    }

    testWidgets('Offers Segment Selection Invokes API and Renders Products',
        (tester) async {
      fakeDatasource.productsToReturn = [offerProduct];
      final container = createContainer();
      await hydrate(container);

      // Force eagerly initializing the providers to fetch data on launch
      container.read(posNewSaleCatalogProvider);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(
              body: Column(
                children: [
                  PosProductCategoryChips(),
                  Expanded(child: PosProductGrid()),
                ],
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Expect default category load (segment: 'popular')
      expect(fakeDatasource.lastSegment, equals('popular'));

      // Tap the Offers Chip
      final offersChipFinder = find.text('Offers');
      expect(offersChipFinder, findsOneWidget);
      await tester.tap(offersChipFinder);
      await tester.pumpAndSettle();

      // Verify the datasource was queried with segment = offers
      expect(fakeDatasource.lastSegment, equals('offers'));
      expect(find.text('Offer Product'), findsOneWidget);

      // Verify immediate offer price is shown, and original price is struck through
      expect(find.text('LKR 1,600.00'), findsOneWidget); // Discounted price
      expect(find.text('LKR 2,000.00'),
          findsOneWidget); // Struck-through original price

      // Verify discount label and manager approval warnings are rendered
      expect(find.text('20% OFF'), findsOneWidget);
      expect(find.text('REQ APP'), findsOneWidget);
    });

    testWidgets(
        'Conditional Offers Renders Base Price as Active with Conditions Label',
        (tester) async {
      fakeDatasource.productsToReturn = [conditionalOfferProduct];
      final container = createContainer();
      await hydrate(container);

      container.read(posNewSaleCatalogProvider);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(
              body: Column(
                children: [
                  PosProductCategoryChips(),
                  Expanded(child: PosProductGrid()),
                ],
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Select Offers Segment
      await tester.tap(find.text('Offers'));
      await tester.pumpAndSettle();

      expect(find.text('Conditional Product'), findsOneWidget);

      // Active price should remain base price
      expect(find.text('LKR 5,000.00'), findsOneWidget);

      // Should show 'Offer available' tag but NOT 'REQ APP'
      expect(find.text('Offer available'), findsOneWidget);
      expect(find.text('REQ APP'), findsNothing);
    });

    testWidgets('Offers Empty State Displays Correct Wording', (tester) async {
      fakeDatasource.productsToReturn = [];
      final container = createContainer();
      await hydrate(container);

      container.read(posNewSaleCatalogProvider);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(
              body: Column(
                children: [
                  PosProductCategoryChips(),
                  Expanded(child: PosProductGrid()),
                ],
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Select Offers Segment
      await tester.tap(find.text('Offers'));
      await tester.pumpAndSettle();

      // Verify custom empty state view
      expect(find.text('No active offers'), findsOneWidget);
      expect(
          find.text('Check back later or try selecting a different category.'),
          findsOneWidget);
    });

    test(
        'Cart state (items, customer, totals) is preserved when switching segments to offers',
        () async {
      final container = createContainer();
      addTearDown(container.dispose);
      await hydrate(container);

      const cartProduct = PosNewSaleProduct(
        id: 'prod-a',
        productId: 'prod-a',
        name: 'Product A',
        category: 'Category 1',
        price: 1500,
        stockStatus: 'InStock',
        maxQuantity: 10,
      );

      final cartNotifier = container.read(posNewSaleCartProvider.notifier);
      cartNotifier.addToCart(cartProduct, quantity: 2);
      cartNotifier.setCustomer(const PosCustomer(
        customerId: 'cust-1',
        fullName: 'John Doe',
        phone: '1234567890',
        status: 'ACTIVE',
      ));

      var cartState = container.read(posNewSaleCartProvider);
      expect(cartState.itemList, hasLength(1));
      expect(cartState.selectedCustomer?.fullName, 'John Doe');
      expect(cartState.total, 3000);

      // Change segment to offers
      container.read(posNewSaleSelectedSegmentProvider.notifier).state =
          'offers';

      // Verify cart state remains untouched
      cartState = container.read(posNewSaleCartProvider);
      expect(cartState.itemList, hasLength(1));
      expect(cartState.selectedCustomer?.fullName, 'John Doe');
      expect(cartState.total, 3000);
    });
  });
}
