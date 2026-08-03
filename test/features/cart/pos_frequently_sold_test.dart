import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:nytroz_pos/core/network/dio_provider.dart';
import 'package:nytroz_pos/features/cart/presentation/providers/pos_catalog_provider.dart';
import 'package:nytroz_pos/features/cart/presentation/providers/pos_new_sale_cart_provider.dart';
import 'package:nytroz_pos/features/cart/data/datasources/pos_catalog_remote_datasource.dart';
import 'package:nytroz_pos/features/cart/domain/entities/pos_catalog_models.dart';
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
  bool shouldThrow = false;

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
    if (shouldThrow) {
      throw DioException(
        requestOptions: RequestOptions(path: '/api/v1/pos/products'),
        type: DioExceptionType.connectionTimeout,
        error: 'Database query timeout',
      );
    }
    return productsToReturn;
  }

  @override
  Future<List<PosCatalogCategory>> getCategories(
      {required String deviceId}) async {
    return [];
  }

  @override
  Future<PosCatalogProductDetail> getProductDetail({
    required String deviceId,
    required String productId,
  }) async {
    throw UnimplementedError();
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
  group('POS Frequently Sold Flow Tests', () {
    late FakeCatalogRemoteDatasource fakeDatasource;
    late AuthSession fakeSession;
    late PosDeviceContext fakeDeviceContext;

    const sampleProductA = PosCatalogProductSummary(
      productId: 'prod-a',
      categoryId: 'cat-1',
      name: 'Product A',
      categoryName: 'Category 1',
      basePrice: 1500,
      hasVariants: false,
      stockStatus: 'InStock',
    );

    const sampleProductB = PosCatalogProductSummary(
      productId: 'prod-b',
      categoryId: 'cat-1',
      name: 'Product B',
      categoryName: 'Category 1',
      basePrice: 2000,
      hasVariants: false,
      stockStatus: 'InStock',
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
      // Eagerly instantiate controllers to start hydration
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

    test('Popular remains default segment when provider initializes', () {
      final container = createContainer();
      addTearDown(container.dispose);

      final segment = container.read(posNewSaleSelectedSegmentProvider);
      expect(segment, 'popular');
    });

    test('Frequently Sold selection updates the segment state', () {
      final container = createContainer();
      addTearDown(container.dispose);

      container.read(posNewSaleSelectedSegmentProvider.notifier).state =
          'frequently-sold';
      final segment = container.read(posNewSaleSelectedSegmentProvider);
      expect(segment, 'frequently-sold');
    });

    test('Catalog provider sends correct API query parameter for segments',
        () async {
      fakeDatasource.productsToReturn = [sampleProductA, sampleProductB];
      final container = createContainer();
      addTearDown(container.dispose);

      await hydrate(container);

      // Listen to catalog provider to keep it active
      container.listen(posNewSaleCatalogProvider, (_, __) {});

      container.read(posNewSaleSelectedSegmentProvider.notifier).state =
          'frequently-sold';
      await Future<void>.delayed(
          Duration.zero); // yield to event loop for invalidation

      final catalogState =
          await container.read(posNewSaleCatalogProvider.future);

      expect(fakeDatasource.lastSegment, 'frequently-sold');
      expect(catalogState.products, hasLength(2));
    });

    test('Catalog provider preserves backend ranking order', () async {
      fakeDatasource.productsToReturn = [sampleProductB, sampleProductA];
      final container = createContainer();
      addTearDown(container.dispose);

      await hydrate(container);

      container.listen(posNewSaleCatalogProvider, (_, __) {});

      container.read(posNewSaleSelectedSegmentProvider.notifier).state =
          'frequently-sold';
      await Future<void>.delayed(Duration.zero);

      final catalogState =
          await container.read(posNewSaleCatalogProvider.future);

      expect(catalogState.products.first.productId, 'prod-b');
      expect(catalogState.products.last.productId, 'prod-a');
    });

    test(
        'Search and category parameters combine correctly with Frequently Sold',
        () async {
      final container = createContainer();
      addTearDown(container.dispose);

      await hydrate(container);

      container.listen(posNewSaleCatalogProvider, (_, __) {});

      container.read(posNewSaleSelectedSegmentProvider.notifier).state =
          'frequently-sold';
      container.read(posNewSaleSelectedCategoryIdProvider.notifier).state =
          'cat-1';
      container.read(posNewSaleSearchQueryProvider.notifier).state =
          'Product B';
      await Future<void>.delayed(Duration.zero);

      // Wait for the 350ms search debounce delay to expire
      await Future<void>.delayed(const Duration(milliseconds: 400));
      await container.read(posNewSaleCatalogProvider.future);

      expect(fakeDatasource.lastSegment, 'frequently-sold');
      expect(fakeDatasource.lastCategoryId, 'cat-1');
      expect(fakeDatasource.lastSearch, 'Product B');
    });

    test('Error loading catalog and successful retry flow', () async {
      fakeDatasource.shouldThrow = true;
      final container = createContainer();
      addTearDown(container.dispose);

      await hydrate(container);

      container.listen(posNewSaleCatalogProvider, (_, __) {});

      container.read(posNewSaleSelectedSegmentProvider.notifier).state =
          'frequently-sold';
      await Future<void>.delayed(Duration.zero);

      expect(
        container.read(posNewSaleCatalogProvider.future),
        throwsA(isA<StateError>()),
      );

      // Reset error state and retry
      fakeDatasource.shouldThrow = false;
      container.invalidate(posNewSaleCatalogProvider);
      await Future<void>.delayed(Duration.zero);

      final catalogState =
          await container.read(posNewSaleCatalogProvider.future);
      expect(catalogState.products, isEmpty);
    });

    test(
        'Cart state (items, customer, totals) is preserved when switching segments',
        () {
      final container = createContainer();
      addTearDown(container.dispose);

      // Setup initial cart state
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

      // Check initial cart state
      var cartState = container.read(posNewSaleCartProvider);
      expect(cartState.itemList, hasLength(1));
      expect(cartState.selectedCustomer?.fullName, 'John Doe');
      expect(cartState.total, 3000);

      // Change segment to Frequently Sold
      container.read(posNewSaleSelectedSegmentProvider.notifier).state =
          'frequently-sold';

      // Verify cart state remains untouched
      cartState = container.read(posNewSaleCartProvider);
      expect(cartState.itemList, hasLength(1));
      expect(cartState.selectedCustomer?.fullName, 'John Doe');
      expect(cartState.total, 3000);
    });
  });
}
