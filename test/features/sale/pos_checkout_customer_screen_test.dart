import 'dart:async';

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
import 'package:nytroz_pos/features/device_activation/application/usecases/activate_device.dart';
import 'package:nytroz_pos/features/device_activation/data/datasources/device_context_storage.dart';
import 'package:nytroz_pos/features/device_activation/domain/entities/pos_device_context.dart';
import 'package:nytroz_pos/features/device_activation/domain/repositories/device_activation_repository.dart';
import 'package:nytroz_pos/features/device_activation/presentation/providers/device_activation_provider.dart';
import 'package:nytroz_pos/features/sale/domain/entities/pos_customer.dart';
import 'package:nytroz_pos/features/sale/presentation/providers/checkout_customer_provider.dart';
import 'package:nytroz_pos/features/sale/presentation/providers/pos_checkout_summary_provider.dart';
import 'package:nytroz_pos/features/sale/presentation/screens/pos_checkout_customer_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('screen loads customer search and create form on tablet',
      (tester) async {
    final container = _container(dio: _customerDio());
    addTearDown(container.dispose);
    await _pumpScreen(tester, container, const Size(1200, 800));
    await tester.pumpAndSettle();

    expect(
        find.byKey(const ValueKey('checkout-customer-screen')), findsOneWidget);
    expect(find.text('SELECT / ADD CUSTOMER'), findsOneWidget);
    expect(find.text('Alice Customer'), findsOneWidget);
    expect(find.byKey(const ValueKey('checkout-customer-add')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('target shell and supported-contract controls render',
      (tester) async {
    final container = _container(dio: _customerDio());
    addTearDown(container.dispose);
    await _pumpScreen(tester, container, const Size(1280, 800));
    await tester.pumpAndSettle();

    expect(find.text('Proceed to Payment'), findsNothing);
    expect(find.byKey(const ValueKey('checkout-customer-workspace')),
        findsOneWidget);
    expect(
        find.byKey(const ValueKey('checkout-customer-back')), findsOneWidget);
    expect(find.text('FIND EXISTING CUSTOMER'), findsOneWidget);
    expect(find.text('ADD NEW CUSTOMER'), findsOneWidget);
    expect(find.text('The customer will be automatically added to this sale.'),
        findsOneWidget);
    final filter = tester.widget<OutlinedButton>(
      find.byKey(const ValueKey('checkout-customer-filter')),
    );
    expect(filter.onPressed, isNull);
    expect(find.text('Customer Type'), findsNothing);
    expect(find.text('Notes'), findsNothing);
    expect(find.text('RECENT CUSTOMERS'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  for (final scenario in <(Size, double)>[
    (const Size(1280, 800), 1),
    (const Size(1680, 1050), 1),
    (const Size(2560, 1600), 1),
    (const Size(1280, 800), 1.3),
  ]) {
    testWidgets(
        'target layout has no overflow at ${scenario.$1.width.toInt()}x${scenario.$1.height.toInt()} scale ${scenario.$2}',
        (tester) async {
      final container = _container(dio: _customerDio());
      addTearDown(container.dispose);
      await _pumpScreen(
        tester,
        container,
        scenario.$1,
        textScale: scenario.$2,
      );
      await tester.pumpAndSettle();

      final searchPanel =
          tester.getTopLeft(find.text('FIND EXISTING CUSTOMER'));
      final createPanel = tester.getTopLeft(find.text('ADD NEW CUSTOMER'));
      expect(searchPanel.dx, lessThan(createPanel.dx));
      expect((searchPanel.dy - createPanel.dy).abs(), lessThan(2));
      expect(
          find.byKey(const ValueKey('checkout-customer-add')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('view-only user can search but cannot create', (tester) async {
    final container = _container(
      dio: _customerDio(),
      permissions: const [PosPermissionCodes.viewNewSaleCustomers],
    );
    addTearDown(container.dispose);
    await _pumpScreen(tester, container, const Size(1000, 760));
    await tester.pumpAndSettle();

    expect(find.text('Alice Customer'), findsOneWidget);
    expect(find.textContaining('customers.create permission'), findsOneWidget);
    final add = tester.widget<FilledButton>(
      find.byKey(const ValueKey('checkout-customer-add')),
    );
    expect(add.onPressed, isNull);
  });

  testWidgets('empty, failure, retry and responsive states remain usable',
      (tester) async {
    var fail = true;
    final container = _container(
      dio: _customerDio(
        listHandler: (_) {
          if (fail) throw _apiError(500);
          return _listResponse(const []);
        },
      ),
    );
    addTearDown(container.dispose);
    await _pumpScreen(tester, container, const Size(700, 900), textScale: 1.3);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('checkout-customer-search-error')),
        findsOneWidget);

    fail = false;
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(
        find.byKey(const ValueKey('checkout-customer-empty')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('create form validates required fields and email',
      (tester) async {
    final container = _container(dio: _customerDio());
    addTearDown(container.dispose);
    await _pumpScreen(tester, container, const Size(1200, 800));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('checkout-customer-add')));
    await tester.pump();
    expect(find.text('Full name is required'), findsOneWidget);
    expect(find.text('Mobile number is required'), findsOneWidget);

    await tester.enterText(
        find.byKey(const ValueKey('checkout-customer-name')), 'New Customer');
    await tester.enterText(
        find.byKey(const ValueKey('checkout-customer-phone')), '123');
    await tester.enterText(
        find.byKey(const ValueKey('checkout-customer-email')), 'invalid');
    await tester.tap(find.byKey(const ValueKey('checkout-customer-add')));
    await tester.pump();
    expect(find.text('Enter a valid mobile number'), findsOneWidget);
    expect(find.text('Enter a valid email address'), findsOneWidget);
  });

  test('selection updates existing cart only after customer attach succeeds',
      () async {
    final container = _container(dio: _customerDio());
    addTearDown(container.dispose);
    final subscription = container.listen(checkoutCustomerProvider, (_, __) {});
    addTearDown(subscription.close);
    final cart = container.read(posNewSaleCartProvider.notifier);
    cart.addToCart(_product);
    const selected = PosCustomer(
      customerId: 'customer-2',
      fullName: 'Selected Customer',
      status: 'ACTIVE',
    );

    final result = await container
        .read(checkoutCustomerProvider.notifier)
        .applyCustomer(selected);

    expect(result, isTrue);
    expect(container.read(posNewSaleCartProvider).selectedCustomer?.customerId,
        selected.customerId);
    expect(container.read(posNewSaleCartProvider).itemList, hasLength(1));
    expect(container.read(posNewSaleCartProvider).total, 2800);
  });

  test('failed customer attach preserves previous customer and cart', () async {
    const previous = PosCustomer(
      customerId: 'customer-old',
      fullName: 'Previous Customer',
      status: 'ACTIVE',
    );
    final container = _container(dio: _customerDio(attachFails: true));
    addTearDown(container.dispose);
    final subscription = container.listen(checkoutCustomerProvider, (_, __) {});
    addTearDown(subscription.close);
    final cart = container.read(posNewSaleCartProvider.notifier);
    cart.addToCart(_product);
    cart.setCustomer(previous);

    final result = await container
        .read(checkoutCustomerProvider.notifier)
        .applyCustomer(const PosCustomer(
          customerId: 'customer-new',
          fullName: 'New Customer',
          status: 'ACTIVE',
        ));

    expect(result, isFalse);
    expect(container.read(posNewSaleCartProvider).selectedCustomer,
        same(previous));
    expect(container.read(posNewSaleCartProvider).itemList, hasLength(1));
  });

  test('create maps request, parses backend customer and blocks duplicate tap',
      () async {
    var requests = 0;
    Map<String, dynamic>? requestBody;
    final container = _container(
      dio: _customerDio(
        createHandler: (options) async {
          requests++;
          requestBody = Map<String, dynamic>.from(options.data as Map);
          await Future<void>.delayed(const Duration(milliseconds: 20));
          return {
            'data': {
              'customerId': 'server-customer',
              'customerCode': 'CUS000010',
              'fullName': 'Server Customer',
              'phone': '+94771234567',
              'status': 'ACTIVE',
              'sourceType': 'POS',
            },
          };
        },
      ),
    );
    addTearDown(container.dispose);
    final subscription = container.listen(checkoutCustomerProvider, (_, __) {});
    addTearDown(subscription.close);
    final notifier = container.read(checkoutCustomerProvider.notifier);
    final first = notifier.create(
      fullName: ' Server Customer ',
      phone: ' +94771234567 ',
      email: '',
    );
    final second = await notifier.create(
      fullName: 'Duplicate tap',
      phone: '+94770000000',
    );
    final created = await first;

    expect(second, isNull);
    expect(requests, 1);
    expect(requestBody, {
      'fullName': 'Server Customer',
      'phone': '+94771234567',
    });
    expect(created?.customerId, 'server-customer');
    expect(created?.customerCode, 'CUS000010');
    expect(created?.sourceType, 'POS');
    expect(container.read(checkoutCustomerProvider).items.first, same(created));
  });

  test('duplicate and permission API failures map to safe messages', () async {
    for (final entry in <(int, String, String)>[
      (409, 'pos_customers.duplicate_phone', 'phone number already exists'),
      (409, 'pos_customers.duplicate_email', 'email address already exists'),
      (403, 'pos_customers.create_permission_denied', 'do not have permission'),
    ]) {
      final container = _container(
        dio: _customerDio(
          createHandler: (_) => throw _apiError(entry.$1, code: entry.$2),
        ),
      );
      final subscription =
          container.listen(checkoutCustomerProvider, (_, __) {});
      final result =
          await container.read(checkoutCustomerProvider.notifier).create(
                fullName: 'Customer',
                phone: '+94771234567',
              );
      expect(result, isNull);
      expect(container.read(checkoutCustomerProvider).createError,
          contains(entry.$3));
      subscription.close();
      container.dispose();
    }
  });
}

Future<void> _pumpScreen(
  WidgetTester tester,
  ProviderContainer container,
  Size size, {
  double textScale = 1,
}) async {
  await tester.binding.setSurfaceSize(size);
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(
              size: size, textScaler: TextScaler.linear(textScale)),
          child: const Scaffold(
            body: PosCheckoutCustomerScreen(showChrome: false),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

ProviderContainer _container({
  required Dio dio,
  List<String> permissions = const [
    PosPermissionCodes.viewNewSaleCustomers,
    PosPermissionCodes.createNewSaleCustomer,
  ],
  bool checkoutFails = false,
}) {
  final session = AuthSession(
    accessToken: 'test-token',
    userId: 'cashier-1',
    userDisplayName: 'Cashier',
    permissionCodes: permissions,
  );
  return ProviderContainer(overrides: [
    appDioProvider.overrideWithValue(dio),
    authSessionStorageProvider.overrideWithValue(_TestAuthSessionStorage()),
    authSessionProvider
        .overrideWith((ref) => _PresetAuthSessionNotifier(session)),
    deviceContextStorageProvider.overrideWithValue(_TestDeviceContextStorage()),
    activateDeviceProvider
        .overrideWithValue(ActivateDevice(_FakeDeviceActivationRepository())),
    deviceActivationProvider.overrideWith(
      (ref) => _PresetDeviceActivationController(
        ref.watch(activateDeviceProvider),
        ref.watch(deviceContextStorageProvider),
      ),
    ),
    posCheckoutSummaryProvider.overrideWith((ref) async {
      if (checkoutFails) throw StateError('Revalidation failed');
      final cart = ref.watch(posNewSaleCartProvider);
      return PosCheckoutSummaryViewData(
        itemCount: cart.itemList.length,
        subtotal: cart.subtotal,
        discount: cart.discount,
        tax: cart.tax,
        totalPayable: cart.total,
        saleType: 'New Sale',
        itemsInCart: cart.itemList.length,
        saleDate: DateTime.utc(2026, 8, 7),
        cashierName: 'Cashier',
        paymentMethods: const [],
        usedFallback: false,
      );
    }),
  ]);
}

typedef _Handler = FutureOr<Map<String, dynamic>> Function(RequestOptions);

Dio _customerDio({
  _Handler? listHandler,
  _Handler? createHandler,
  bool attachFails = false,
}) {
  final dio = Dio(BaseOptions(baseUrl: 'https://test.local'));
  dio.interceptors.add(InterceptorsWrapper(onRequest: (options, handler) async {
    try {
      final isAttach = options.path.endsWith('/attach-to-sale');
      if (isAttach && attachFails) {
        throw _apiError(409, code: 'pos_customers.customer_inactive');
      }
      final data = options.method == 'POST'
          ? isAttach
              ? _attachResponse(options.path)
              : await (createHandler?.call(options) ?? _createdResponse)
          : await (listHandler?.call(options) ??
              _listResponse([
                {
                  'customerId': 'customer-1',
                  'fullName': 'Alice Customer',
                  'phone': '+94771234567',
                  'status': 'ACTIVE',
                },
              ]));
      handler.resolve(Response<Map<String, dynamic>>(
          requestOptions: options, statusCode: 200, data: data));
    } on DioException catch (error) {
      handler.reject(error.copyWith(requestOptions: options));
    }
  }));
  return dio;
}

Map<String, dynamic> _listResponse(List<Map<String, dynamic>> items) => {
      'data': items,
      'pagination': {
        'page': 1,
        'pageSize': 20,
        'totalCount': items.length,
        'totalPages': items.isEmpty ? 0 : 1,
      },
    };

final _createdResponse = {
  'data': {
    'customerId': 'created-1',
    'fullName': 'Created Customer',
    'phone': '+94771234567',
    'status': 'ACTIVE',
    'sourceType': 'POS',
  },
};

Map<String, dynamic> _attachResponse(String path) {
  final customerId =
      path.split('/').where((part) => part.isNotEmpty).elementAt(3);
  return {
    'data': {
      'customerId': customerId,
      'fullName': 'Selected Customer',
      'status': 'ACTIVE',
      'attachmentMode': 'CART_CONTEXT',
    },
  };
}

DioException _apiError(int status, {String? code}) {
  final options = RequestOptions(path: '/api/v1/customers');
  return DioException(
    requestOptions: options,
    type: DioExceptionType.badResponse,
    response: Response(
      requestOptions: options,
      statusCode: status,
      data: {'code': code, 'message': 'Safe API message'},
    ),
  );
}

const _product = PosNewSaleProduct(
  id: 'line-1',
  productId: 'product-1',
  variantId: 'variant-1',
  name: 'Match Shorts',
  category: 'Apparel',
  price: 2800,
);

final _deviceContext = PosDeviceContext(
  deviceId: '00000000-0000-0000-0000-000000000001',
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

class _PresetAuthSessionNotifier extends AuthSessionNotifier {
  _PresetAuthSessionNotifier(AuthSession session)
      : super(_TestAuthSessionStorage()) {
    state = session;
  }
}

class _TestAuthSessionStorage extends AuthSessionStorage {
  _TestAuthSessionStorage()
      : super(const AppSecureStorage(FlutterSecureStorage()));
  @override
  Future<AuthSession?> read() async => null;
  @override
  Future<void> save(AuthSession session) async {}
  @override
  Future<void> clear() async {}
}

class _PresetDeviceActivationController extends DeviceActivationController {
  _PresetDeviceActivationController(super.activateDevice, super.storage)
      : super() {
    state = DeviceActivationState(deviceContext: _deviceContext);
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
