import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nytroz_pos/core/access/pos_access_codes.dart';
import 'package:nytroz_pos/core/network/dio_provider.dart';
import 'package:nytroz_pos/core/storage/app_secure_storage.dart';
import 'package:nytroz_pos/features/auth/data/datasources/auth_session_storage.dart';
import 'package:nytroz_pos/features/auth/domain/entities/auth_session.dart';
import 'package:nytroz_pos/features/auth/presentation/providers/session_provider.dart';
import 'package:nytroz_pos/features/cart/presentation/providers/pos_new_sale_cart_provider.dart';
import 'package:nytroz_pos/features/customers/presentation/providers/checkout_customer_provider.dart';
import 'package:nytroz_pos/features/customers/presentation/providers/customers_provider.dart';
import 'package:nytroz_pos/features/customers/presentation/widgets/checkout_customer/checkout_customer_header.dart';
import 'package:nytroz_pos/features/device_activation/application/usecases/activate_device.dart';
import 'package:nytroz_pos/features/device_activation/data/datasources/device_context_storage.dart';
import 'package:nytroz_pos/features/device_activation/domain/entities/pos_device_context.dart';
import 'package:nytroz_pos/features/device_activation/domain/repositories/device_activation_repository.dart';
import 'package:nytroz_pos/features/device_activation/presentation/providers/device_activation_provider.dart';
import 'package:nytroz_pos/features/sale/data/datasources/pos_checkout_remote_datasource.dart';
import 'package:nytroz_pos/features/sale/data/datasources/pos_customer_remote_datasource.dart';
import 'package:nytroz_pos/features/sale/domain/entities/pos_customer.dart';
import 'package:nytroz_pos/features/sale/presentation/providers/pos_checkout_summary_provider.dart';
import 'package:nytroz_pos/features/sale/presentation/widgets/payment_method/widgets/payment_top_bar_content.dart';
import 'package:nytroz_pos/features/sale/presentation/widgets/payment_method/widgets/sale_summary/customer_card.dart';

final _deviceContext = PosDeviceContext(
  deviceId: 'device-1',
  deviceCode: 'DEV-001',
  deviceName: 'Front POS',
  deviceType: 'fixed_pos_tablet',
  platform: 'web',
  deviceFingerprint: 'test-device-fingerprint',
  isTrusted: true,
  tenantId: 'tenant-1',
  outletId: 'outlet-1',
  outletName: 'Main Outlet',
  tillId: 'till-1',
  tillCode: 'TILL-001',
  tillName: 'Front Till',
  pairedAt: DateTime.utc(2026, 7, 1),
);

const _authSession = AuthSession(
  accessToken: 'test-token',
  userId: 'user-1',
  userDisplayName: 'Cashier One',
  permissionCodes: [
    PosPermissionCodes.createSale,
    PosPermissionCodes.checkoutSale,
    PosPermissionCodes.acceptCashPayment,
    PosPermissionCodes.viewNewSaleCustomers,
    PosPermissionCodes.createNewSaleCustomer,
    // Chunk 14: attach is independent — create/view must not parent-infer.
    PosPermissionCodes.customersAttachSale,
  ],
);

class _TestAuthSessionStorage extends AuthSessionStorage {
  _TestAuthSessionStorage()
      : super(const AppSecureStorage(FlutterSecureStorage()));

  @override
  Future<AuthSession?> read() async => _authSession;

  @override
  Future<void> save(AuthSession session) async {}

  @override
  Future<void> clear() async {}
}

class _PresetAuthSessionNotifier extends AuthSessionNotifier {
  _PresetAuthSessionNotifier() : super(_TestAuthSessionStorage()) {
    state = _authSession;
  }
}

class _FakeDeviceActivationRepository implements DeviceActivationRepository {
  @override
  Future<PosDeviceContext> activateDevice(DeviceActivationForm form) async =>
      _deviceContext;

  @override
  Future<PosDeviceContext?> getCurrentDevice(DeviceActivationForm form) async =>
      _deviceContext;
}

class _TestDeviceContextStorage extends DeviceContextStorage {
  _TestDeviceContextStorage()
      : super(const AppSecureStorage(FlutterSecureStorage()));

  @override
  Future<PosDeviceContext?> read() async => _deviceContext;

  @override
  Future<String> readOrCreateDeviceFingerprint() async =>
      _deviceContext.deviceFingerprint;

  @override
  Future<List<String>> readDeviceFingerprintCandidates() async =>
      [_deviceContext.deviceFingerprint];

  @override
  Future<void> save(PosDeviceContext context) async {}

  @override
  Future<void> clear() async {}
}

class _PresetDeviceActivationController extends DeviceActivationController {
  _PresetDeviceActivationController()
      : super(
          ActivateDevice(_FakeDeviceActivationRepository()),
          _TestDeviceContextStorage(),
        ) {
    state = DeviceActivationState(deviceContext: _deviceContext);
  }
}

Dio _mockCheckoutDio(List<Map<String, dynamic>> requests) {
  final dio = Dio(BaseOptions(baseUrl: 'https://test.local'));
  dio.interceptors.add(InterceptorsWrapper(onRequest: (options, handler) {
    if (options.data is Map) {
      requests.add(Map<String, dynamic>.from(options.data as Map));
    }
    handler.resolve(Response<Map<String, dynamic>>(
      requestOptions: options,
      statusCode: 200,
      data: {
        'data': {
          'subtotal': 2800,
          'totalPayable': 2800,
          'tax': 0,
          'currency': 'LKR',
          'paymentMethods': ['cash'],
          'lines': [],
          'validationMessages': [],
          'discountAmount': 0,
        },
      },
    ));
  }));
  return dio;
}

Dio _mockCustomerDio(
    List<Map<String, dynamic>> requests, PosCustomer createdCustomer) {
  final dio = Dio(BaseOptions(baseUrl: 'https://test.local'));
  dio.interceptors.add(InterceptorsWrapper(onRequest: (options, handler) {
    if (options.data is Map) {
      requests.add(Map<String, dynamic>.from(options.data as Map));
    }
    if (options.method == 'POST') {
      handler.resolve(Response<Map<String, dynamic>>(
        requestOptions: options,
        statusCode: 201,
        data: {
          'data': {
            'customerId': createdCustomer.customerId,
            'fullName': createdCustomer.fullName,
            'phone': createdCustomer.phone,
            'status': 'ACTIVE',
            'customerCode': 'CUST-001',
            'sourceType': 'POS',
            'createdAt': DateTime.now().toIso8601String(),
          },
        },
      ));
      return;
    }
    handler.resolve(Response<Map<String, dynamic>>(
      requestOptions: options,
      statusCode: 200,
      data: {
        'data': {
          'items': [],
          'page': 1,
          'pageSize': 20,
          'totalCount': 0,
          'totalPages': 0,
        },
      },
    ));
  }));
  return dio;
}

void main() {
  const sampleProduct = PosNewSaleProduct(
    id: 'prod-1',
    productId: 'prod-1',
    variantId: 'var-1',
    name: 'Sample Tea',
    category: 'Beverages',
    price: 2800,
    stockStatus: 'InStock',
  );

  const sampleCustomer = PosCustomer(
    customerId: 'cust-existing-1',
    fullName: 'Perera Silva',
    phone: '+94712345678',
    status: 'ACTIVE',
    totalOrderCount: 5,
  );

  group('Complete POS Checkout Journey — Cart -> Customer -> Payment', () {
    test(
        'Flow A (Walk-in / SKIP): skips customer selection with customerId = null',
        () async {
      final requests = <Map<String, dynamic>>[];
      final mockDio = _mockCheckoutDio(requests);
      final checkoutDs = PosCheckoutRemoteDatasource(mockDio);

      final container = ProviderContainer(
        overrides: [
          appDioProvider.overrideWithValue(mockDio),
          authSessionProvider
              .overrideWith((ref) => _PresetAuthSessionNotifier()),
          posCheckoutRemoteDatasourceProvider.overrideWithValue(checkoutDs),
          deviceActivationProvider
              .overrideWith((ref) => _PresetDeviceActivationController()),
        ],
      );
      addTearDown(container.dispose);

      // 1. Add product to cart
      final cartNotifier = container.read(posNewSaleCartProvider.notifier);
      cartNotifier.addToCart(sampleProduct);
      expect(container.read(posNewSaleCartProvider).hasItems, isTrue);

      // 2. Customer screen SKIP invoked
      final customerNotifier =
          container.read(checkoutCustomerProvider.notifier);
      final skipped = await customerNotifier.skip();
      expect(skipped, isTrue);

      // 3. Customer is null (Walk-in)
      final cartState = container.read(posNewSaleCartProvider);
      expect(cartState.selectedCustomer, isNull);

      // 4. Fingerprint verifies walk-in customer (customerId = '')
      final fingerprint = checkoutPricingInputFingerprint(cartState);
      expect(fingerprint, contains('customer:'));
      expect(fingerprint, isNot(contains('customer:cust-')));
    });

    test(
        'Flow B (Existing Customer): confirmFound attaches customer to cart and revalidates',
        () async {
      final requests = <Map<String, dynamic>>[];
      final mockDio = _mockCheckoutDio(requests);
      final checkoutDs = PosCheckoutRemoteDatasource(mockDio);

      final container = ProviderContainer(
        overrides: [
          appDioProvider.overrideWithValue(mockDio),
          authSessionProvider
              .overrideWith((ref) => _PresetAuthSessionNotifier()),
          posCheckoutRemoteDatasourceProvider.overrideWithValue(checkoutDs),
          deviceActivationProvider
              .overrideWith((ref) => _PresetDeviceActivationController()),
        ],
      );
      addTearDown(container.dispose);

      // 1. Cart has product
      container.read(posNewSaleCartProvider.notifier).addToCart(sampleProduct);

      // 2. Simulate customer found in checkout provider
      final customerNotifier =
          container.read(checkoutCustomerProvider.notifier);
      container.read(checkoutCustomerProvider.notifier).state =
          container.read(checkoutCustomerProvider).copyWith(
                stage: CheckoutCustomerStage.customerFound,
                foundCustomer: sampleCustomer,
              );

      // 3. Cashier confirms: ADD TO SALE & CONTINUE
      final confirmed = await customerNotifier.confirmFound();
      expect(confirmed, isTrue);

      // 4. Cart has selected customer
      final cartState = container.read(posNewSaleCartProvider);
      expect(cartState.selectedCustomer?.customerId, 'cust-existing-1');
      expect(cartState.selectedCustomer?.fullName, 'Perera Silva');

      // 5. Pricing fingerprint contains customer ID
      final fingerprint = checkoutPricingInputFingerprint(cartState);
      expect(fingerprint, contains('customer:cust-existing-1'));
    });

    test(
        'Flow C (New Customer Quick-Create): createAndContinue creates and attaches customer',
        () async {
      const createdCustomer = PosCustomer(
        customerId: 'cust-created-99',
        fullName: 'Kamal Gunaratne',
        phone: '+94771234567',
        status: 'ACTIVE',
      );
      final checkoutRequests = <Map<String, dynamic>>[];
      final customerRequests = <Map<String, dynamic>>[];
      final mockCheckoutDio = _mockCheckoutDio(checkoutRequests);
      final checkoutDs = PosCheckoutRemoteDatasource(mockCheckoutDio);
      final customerDs = PosCustomerRemoteDatasource(
          _mockCustomerDio(customerRequests, createdCustomer));

      final container = ProviderContainer(
        overrides: [
          appDioProvider.overrideWithValue(mockCheckoutDio),
          authSessionProvider
              .overrideWith((ref) => _PresetAuthSessionNotifier()),
          posCheckoutRemoteDatasourceProvider.overrideWithValue(checkoutDs),
          posCustomerRemoteDatasourceProvider.overrideWithValue(customerDs),
          deviceActivationProvider
              .overrideWith((ref) => _PresetDeviceActivationController()),
        ],
      );
      addTearDown(container.dispose);

      // 1. Cart has product
      container.read(posNewSaleCartProvider.notifier).addToCart(sampleProduct);

      // 2. Set phone and name in checkout customer provider
      final customerNotifier =
          container.read(checkoutCustomerProvider.notifier);
      customerNotifier.state = customerNotifier.state.copyWith(
        stage: CheckoutCustomerStage.customerNotFound,
        dialCode: '+94',
        localPhone: '771234567',
      );
      customerNotifier.beginCreate();
      customerNotifier.setCustomerName('Kamal Gunaratne');

      expect(container.read(checkoutCustomerProvider).stage,
          CheckoutCustomerStage.createReady);

      // 3. Cashier presses ADD CUSTOMER & CONTINUE
      final created = await customerNotifier.createAndContinue();
      expect(created, isTrue);
      expect(customerRequests.length, 1);
      expect(customerRequests.single['fullName'], 'Kamal Gunaratne');

      // 4. Returned customer attached to cart
      final cartState = container.read(posNewSaleCartProvider);
      expect(cartState.selectedCustomer?.fullName, 'Kamal Gunaratne');
      expect(cartState.selectedCustomer?.customerId, 'cust-created-99');
    });

    testWidgets(
        'Payment Method CustomerCard displays Walk-in vs Selected Customer',
        (tester) async {
      // Walk-in state
      final walkInCart = PosNewSaleCartState(items: {
        'line-1': PosNewSaleCartItem(product: sampleProduct, quantity: 1)
      });
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomerCard(cart: walkInCart),
          ),
        ),
      );
      expect(find.text('Walk-in Customer'), findsOneWidget);
      expect(find.text('Guest'), findsOneWidget);

      // Selected customer state
      final customerCart = PosNewSaleCartState(
        items: {
          'line-1': PosNewSaleCartItem(product: sampleProduct, quantity: 1)
        },
        selectedCustomer: sampleCustomer,
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomerCard(cart: customerCart),
          ),
        ),
      );
      expect(find.text('Perera Silva'), findsOneWidget);
      expect(find.text('Active'), findsOneWidget);
    });

    testWidgets(
        'CheckoutCustomerHeader renders Back to Cart and SKIP buttons in phone entry',
        (tester) async {
      bool backTapped = false;
      bool skipTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CheckoutCustomerHeader(
              isCreateMode: false,
              onBack: () => backTapped = true,
              onSkip: () => skipTapped = true,
            ),
          ),
        ),
      );

      expect(find.text('FIND OR ADD CUSTOMER'), findsOneWidget);
      expect(find.text('Back to Cart'), findsOneWidget);
      expect(find.text('SKIP'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('checkout-customer-back')));
      expect(backTapped, isTrue);

      await tester.tap(find.byKey(const ValueKey('checkout-customer-skip')));
      expect(skipTapped, isTrue);
    });

    testWidgets(
        'CheckoutCustomerHeader in create mode hides SKIP and shows Back',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CheckoutCustomerHeader(
              isCreateMode: true,
              onBack: () {},
            ),
          ),
        ),
      );

      expect(find.text('ADD NEW CUSTOMER'), findsOneWidget);
      expect(find.text('Back'), findsOneWidget);
      expect(find.text('SKIP'), findsNothing);
    });

    testWidgets('PaymentTopBarContent includes Back button', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            deviceActivationProvider
                .overrideWith((ref) => _PresetDeviceActivationController()),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: PaymentTopBarContent(),
            ),
          ),
        ),
      );

      expect(
          find.byKey(const ValueKey('payment-top-bar-back')), findsOneWidget);
      expect(find.text('Proceed to Payment'), findsOneWidget);
    });
  });
}
