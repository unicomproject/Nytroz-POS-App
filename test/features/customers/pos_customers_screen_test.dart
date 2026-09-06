import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:nytroz_pos/core/access/pos_access_codes.dart';
import 'package:nytroz_pos/core/network/dio_provider.dart';
import 'package:nytroz_pos/core/storage/app_secure_storage.dart';
import 'package:nytroz_pos/features/auth/data/datasources/auth_session_storage.dart';
import 'package:nytroz_pos/features/auth/domain/entities/auth_session.dart';
import 'package:nytroz_pos/features/auth/presentation/providers/session_provider.dart';
import 'package:nytroz_pos/features/cart/presentation/providers/pos_new_sale_cart_provider.dart';
import 'package:nytroz_pos/features/customers/presentation/providers/customers_provider.dart';
import 'package:nytroz_pos/features/customers/presentation/screens/pos_customers_screen.dart';
import 'package:nytroz_pos/features/customers/presentation/widgets/customer_details_panel.dart';
import 'package:nytroz_pos/features/customers/presentation/widgets/customers_table_section.dart';
import 'package:nytroz_pos/features/device_activation/application/usecases/activate_device.dart';
import 'package:nytroz_pos/features/device_activation/data/datasources/device_context_storage.dart';
import 'package:nytroz_pos/features/device_activation/domain/entities/pos_device_context.dart';
import 'package:nytroz_pos/features/device_activation/domain/repositories/device_activation_repository.dart';
import 'package:nytroz_pos/features/device_activation/presentation/providers/device_activation_provider.dart';
import 'package:nytroz_pos/features/sale/domain/entities/pos_customer.dart';
import 'package:nytroz_pos/features/till/application/usecases/open_till.dart';
import 'package:nytroz_pos/features/till/data/datasources/till_session_storage.dart';
import 'package:nytroz_pos/features/till/domain/entities/open_till.dart';
import 'package:nytroz_pos/features/till/domain/repositories/till_repository.dart';
import 'package:nytroz_pos/features/till/presentation/providers/till_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('renders header, add action, and list without summary cards',
      (tester) async {
    final container = _createContainer(
      dio: _dioWithHandlers({
        'GET /api/v1/customers': (options) {
          final pageSize = int.tryParse(
                options.queryParameters['pageSize']?.toString() ?? '',
              ) ??
              8;
          if (pageSize == 1) {
            return _pageResponse(items: const [], totalCount: 2);
          }
          return _pageResponse(
            items: [
              _customerJson(
                id: 'cust-100',
                name: 'Alpha Customer',
                phone: '0111111111',
                email: 'alpha@example.com',
              ),
              _customerJson(
                id: 'cust-200',
                name: 'Beta Customer',
                phone: '0222222222',
                email: 'beta@example.com',
              ),
            ],
            totalCount: 2,
          );
        },
      }),
      tillOpen: true,
    );

    await _pumpCustomers(tester, container);
    await tester.pumpAndSettle();

    expect(find.text('Customers'), findsWidgets);
    expect(
      find.text('Search, select, and manage customers during checkout'),
      findsOneWidget,
    );
    expect(find.text('New Customer'), findsNothing);
    expect(find.widgetWithText(FilledButton, 'Add Customer'), findsOneWidget);
    expect(find.text('Total Customers'), findsNothing);
    expect(find.text('Active Customers'), findsNothing);
    expect(find.text('Customers With Orders'), findsNothing);
    expect(find.text('New Customers This Month'), findsNothing);
    expect(find.text('Alpha Customer'), findsOneWidget);
    expect(find.text('Beta Customer'), findsOneWidget);
    expect(find.byType(CustomerDetailsPanel), findsNothing);
    expect(
      find.descendant(
        of: find.byType(CustomersTableSection),
        matching: find.byType(ListView),
      ),
      findsNothing,
    );

    await tester.tap(find.text('Beta Customer').first);
    await tester.pumpAndSettle();

    expect(find.byType(CustomerDetailsPanel), findsOneWidget);
    expect(container.read(customersProvider).selectedCustomerId, 'cust-200');

    await tester.tap(find.text('Beta Customer').first);
    await tester.pumpAndSettle();

    expect(find.byType(CustomerDetailsPanel), findsNothing);
    expect(container.read(customersProvider).selectedCustomerId, isNull);
  });

  testWidgets('shows list error and retry', (tester) async {
    var fail = true;
    final container = _createContainer(
      dio: _dioWithHandlers({
        'GET /api/v1/customers': (options) {
          if (fail) {
            throw DioException(
              requestOptions: options,
              response: Response(
                requestOptions: options,
                statusCode: 500,
                data: {'message': 'Customer service down'},
              ),
              type: DioExceptionType.badResponse,
            );
          }
          return _pageResponse(
            items: [
              _customerJson(id: 'cust-1', name: 'Recovered Customer'),
            ],
            totalCount: 1,
          );
        },
      }),
    );

    await _pumpCustomers(tester, container);
    await tester.pumpAndSettle();

    expect(find.text('Unable to load customers'), findsOneWidget);
    expect(find.text('Customer service down'), findsOneWidget);

    fail = false;
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();

    expect(find.text('Recovered Customer'), findsOneWidget);
  });

  testWidgets('hides Add Customer without customers.create permission',
      (tester) async {
    final container = _createContainer(
      dio: _dioWithHandlers({
        'GET /api/v1/customers': (_) =>
            _pageResponse(items: const [], totalCount: 0),
      }),
      canCreateCustomer: false,
    );

    await _pumpCustomers(tester, container);
    await tester.pumpAndSettle();

    expect(find.text('Add Customer'), findsNothing);
  });

  testWidgets('Attach to Sale stores selected customer on cart',
      (tester) async {
    final container = _createContainer(
      dio: _dioWithCustomerDefaults({
        'GET /api/v1/customers': (options) {
          final pageSize = int.tryParse(
                options.queryParameters['pageSize']?.toString() ?? '',
              ) ??
              8;
          if (pageSize == 1) {
            return _pageResponse(items: const [], totalCount: 1);
          }
          return _pageResponse(
            items: [
              _customerJson(id: 'cust-attach', name: 'Attach Me'),
            ],
            totalCount: 1,
          );
        },
      }),
      tillOpen: true,
      canStartSale: true,
    );

    await _pumpCustomers(tester, container);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Attach Me'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Attach to Sale'));
    await tester.pumpAndSettle();

    final cart = container.read(posNewSaleCartProvider);
    expect(cart.selectedCustomer?.customerId, 'cust-attach');
    expect(cart.selectedCustomer?.displayName, 'Attach Me');
    expect(find.text('New Sale Route'), findsOneWidget);
  });

  testWidgets('Attach to Sale is disabled without open till', (tester) async {
    final container = _createContainer(
      dio: _dioWithHandlers({
        'GET /api/v1/customers': (options) {
          final pageSize = int.tryParse(
                options.queryParameters['pageSize']?.toString() ?? '',
              ) ??
              8;
          if (pageSize == 1) {
            return _pageResponse(items: const [], totalCount: 1);
          }
          return _pageResponse(
            items: [
              _customerJson(id: 'cust-1', name: 'No Till Customer'),
            ],
            totalCount: 1,
          );
        },
      }),
      tillOpen: false,
    );

    await _pumpCustomers(tester, container);
    await tester.pumpAndSettle();

    await tester.tap(find.text('No Till Customer'));
    await tester.pumpAndSettle();

    final button = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Attach to Sale'),
    );
    expect(button.onPressed, isNull);
  });

  testWidgets('narrow layout opens details sheet on select', (tester) async {
    tester.view.physicalSize = const Size(700, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final container = _createContainer(
      dio: _dioWithCustomerDefaults({
        'GET /api/v1/customers': (options) {
          final pageSize = int.tryParse(
                options.queryParameters['pageSize']?.toString() ?? '',
              ) ??
              8;
          if (pageSize == 1) {
            return _pageResponse(items: const [], totalCount: 1);
          }
          return _pageResponse(
            items: [
              _customerJson(id: 'cust-narrow', name: 'Narrow Customer'),
            ],
            totalCount: 1,
          );
        },
      }),
      tillOpen: true,
      canEditCustomer: true,
    );

    await _pumpCustomers(tester, container, width: 700, height: 1000);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Narrow Customer'));
    await tester.pumpAndSettle();

    expect(find.text('Attach to Sale'), findsOneWidget);
    expect(find.text('View Purchase History'), findsOneWidget);
    expect(find.text('Edit Customer'), findsOneWidget);
  });

  test('selection uses customerId and survives reload of same page', () async {
    final container = _createContainer(
      dio: _dioWithHandlers({
        'GET /api/v1/customers': (options) {
          return _pageResponse(
            items: [
              _customerJson(id: 'id-a', name: 'A'),
              _customerJson(id: 'id-b', name: 'B'),
            ],
            totalCount: 2,
          );
        },
      }),
    );

    final notifier = container.read(customersProvider.notifier);
    await notifier.load(resetPage: true);
    notifier.selectCustomer('id-b');
    expect(container.read(customersProvider).selectedCustomerId, 'id-b');

    await notifier.load();
    expect(container.read(customersProvider).selectedCustomerId, 'id-b');
  });

  test('status filter clears selection when customer is no longer visible',
      () async {
    final container = _createContainer(
      dio: _dioWithHandlers({
        'GET /api/v1/customers': (options) {
          final status = options.queryParameters['status']?.toString();
          if (status == 'INACTIVE') {
            return _pageResponse(items: const [], totalCount: 0);
          }
          return _pageResponse(
            items: [
              _customerJson(
                id: 'active-1',
                name: 'Active One',
                status: 'ACTIVE',
              ),
            ],
            totalCount: 1,
          );
        },
      }),
    );

    final notifier = container.read(customersProvider.notifier);
    await notifier.load(resetPage: true);
    await notifier.selectCustomer('active-1');
    notifier.setStatusFilter(CustomerStatusFilter.inactive);
    await notifier.load(resetPage: true);

    final state = container.read(customersProvider);
    expect(state.selectedCustomerId, isNull);
    expect(state.visibleItems, isEmpty);
  });

  test('PosCustomer helpers derive initials from real name', () {
    const customer = PosCustomer(
      customerId: 'abc',
      fullName: 'Ada Lovelace',
      status: 'ACTIVE',
    );
    expect(customer.initials, 'AL');
    expect(customer.isActive, isTrue);
    expect(customer.statusLabel, 'Active');
  });
}

Future<void> _pumpCustomers(
  WidgetTester tester,
  ProviderContainer container, {
  double width = 1280,
  double height = 800,
}) async {
  tester.view.physicalSize = Size(width, height);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final router = GoRouter(
    initialLocation: '/pos/customers',
    routes: [
      GoRoute(
        path: '/pos/customers',
        builder: (context, state) => const Scaffold(
          body: PosCustomersScreen(),
        ),
      ),
      GoRoute(
        path: '/pos/new-sale',
        builder: (context, state) => const Scaffold(
          body: Text('New Sale Route'),
        ),
      ),
    ],
  );

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(routerConfig: router),
    ),
  );
}

ProviderContainer _createContainer({
  required Dio dio,
  bool tillOpen = true,
  bool canStartSale = true,
  bool canEditCustomer = false,
  bool canCreateCustomer = true,
  bool canAttachCustomer = true,
}) {
  // Chunk 14: list/detail field codes are exact-membership (not inferred from view).
  final permissions = <String>[
    PosPermissionCodes.viewNewSaleCustomers,
    if (canCreateCustomer) PosPermissionCodes.createNewSaleCustomer,
    PosPermissionCodes.manageCart,
    if (canStartSale) PosPermissionCodes.viewNewSale,
    if (canStartSale) PosPermissionCodes.createSale,
    if (canEditCustomer) PosPermissionCodes.updateNewSaleCustomer,
    // List / toolbar visibility
    PosPermissionCodes.customersListSearch,
    PosPermissionCodes.customersListFilters,
    PosPermissionCodes.customersListId,
    PosPermissionCodes.customersListName,
    PosPermissionCodes.customersListPhone,
    PosPermissionCodes.customersListEmail,
    PosPermissionCodes.customersListSource,
    PosPermissionCodes.customersListStatus,
    PosPermissionCodes.customersListOrderCount,
    PosPermissionCodes.customersListTotalSpend,
    PosPermissionCodes.customersListPagination,
    // Details / history actions
    PosPermissionCodes.customersDetailsJoinedDate,
    PosPermissionCodes.customersDetailsAverageOrderValue,
    PosPermissionCodes.customersHistoryRecentPurchases,
    PosPermissionCodes.customersHistoryPurchaseAmounts,
    PosPermissionCodes.customersHistoryPurchaseHistory,
    // Attach: grant so button is present; till-closed tests keep it disabled.
    if (canAttachCustomer) PosPermissionCodes.customersAttachSale,
  ];

  final session = AuthSession(
    accessToken: 'token',
    userId: 'user-1',
    userDisplayName: 'Cashier',
    permissionCodes: permissions,
  );

  final tillSession = tillOpen ? _openTillSession : null;

  return ProviderContainer(
    overrides: [
      appDioProvider.overrideWithValue(dio),
      authSessionStorageProvider.overrideWithValue(_TestAuthSessionStorage()),
      authSessionProvider.overrideWith(
        (ref) => _PresetAuthSessionNotifier(session),
      ),
      deviceContextStorageProvider.overrideWithValue(
        _TestDeviceContextStorage(_deviceContext),
      ),
      activateDeviceProvider.overrideWithValue(
        ActivateDevice(_FakeDeviceActivationRepository(_deviceContext)),
      ),
      deviceActivationProvider.overrideWith(
        (ref) => _PresetDeviceActivationController(
          ref.watch(activateDeviceProvider),
          ref.watch(deviceContextStorageProvider),
          _deviceContext,
        ),
      ),
      openTillProvider.overrideWithValue(
        OpenTill(_FakeTillRepository(tillSession)),
      ),
      tillSessionStorageProvider.overrideWithValue(
        _TestTillSessionStorage(tillSession),
      ),
      tillProvider.overrideWith(
        (ref) => _PresetTillController(
          ref.watch(openTillProvider),
          ref.watch(tillSessionStorageProvider),
          tillSession,
        ),
      ),
    ],
  );
}

Map<String, dynamic> _pageResponse({
  required List<Map<String, dynamic>> items,
  required int totalCount,
  int page = 1,
  int pageSize = 4,
}) {
  final totalPages =
      totalCount == 0 ? 0 : (totalCount / pageSize).ceil().clamp(1, 9999);
  return {
    'success': true,
    'data': {
      'items': items,
      'page': page,
      'pageSize': pageSize,
      'totalCount': totalCount,
      'totalPages': totalPages,
    },
  };
}

Map<String, dynamic> _customerJson({
  required String id,
  required String name,
  String? phone,
  String? email,
  String status = 'ACTIVE',
}) {
  return {
    'customerId': id,
    'fullName': name,
    'phone': phone,
    'email': email,
    'status': status,
  };
}

Dio _dioWithCustomerDefaults(
  Map<String, dynamic Function(RequestOptions)> handlers, {
  bool summaryFails = false,
}) {
  return _dioWithHandlers({
    ...handlers,
    'GET /api/v1/customers/summary': (_) {
      if (summaryFails) {
        throw DioException(
          requestOptions: RequestOptions(path: '/api/v1/customers/summary'),
          response: Response(
            requestOptions: RequestOptions(path: '/api/v1/customers/summary'),
            statusCode: 500,
          ),
          type: DioExceptionType.badResponse,
        );
      }
      return {
        'success': true,
        'data': {
          'totalCustomers': 1,
          'activeCustomers': 1,
          'customersWithOrders': 0,
          'newCustomersThisMonth': 0,
        },
      };
    },
  }, extraMatchers: _customerRouteMatchers(handlers));
}

Dio _dioWithHandlers(
  Map<String, dynamic Function(RequestOptions)> handlers, {
  List<MapEntry<RegExp, dynamic Function(RequestOptions)>>? extraMatchers,
}) {
  final dio = Dio(BaseOptions(baseUrl: 'http://localhost'));
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        final key = '${options.method} ${options.path}';
        dynamic Function(RequestOptions)? matched = handlers[key];

        if (matched == null && extraMatchers != null) {
          for (final entry in extraMatchers) {
            if (entry.key.hasMatch('${options.method} ${options.path}')) {
              matched = entry.value;
              break;
            }
          }
        }

        if (matched == null) {
          handler.reject(
            DioException(
              requestOptions: options,
              error: 'Unhandled $key',
            ),
          );
          return;
        }
        try {
          final data = matched(options);
          handler.resolve(
            Response(
              requestOptions: options,
              statusCode: 200,
              data: data,
            ),
          );
        } on DioException catch (error) {
          handler.reject(error);
        } catch (error) {
          handler.reject(
            DioException(requestOptions: options, error: error),
          );
        }
      },
    ),
  );
  return dio;
}

List<MapEntry<RegExp, dynamic Function(RequestOptions)>> _customerRouteMatchers(
  Map<String, dynamic Function(RequestOptions)> handlers,
) {
  return [
    MapEntry(RegExp(r'^GET /api/v1/customers/[^/]+$'), (options) {
      final id = options.path.split('/').last;
      return {
        'success': true,
        'data': _customerJson(id: id, name: 'Customer $id'),
      };
    }),
    MapEntry(RegExp(r'^GET /api/v1/customers/[^/]+/orders$'), (_) {
      return {
        'success': true,
        'data': [],
      };
    }),
    MapEntry(RegExp(r'^POST /api/v1/customers/[^/]+/attach-to-sale$'),
        (options) {
      final segments = options.path.split('/');
      final id = segments[segments.length - 2];
      final name = id == 'cust-attach' ? 'Attach Me' : 'Customer $id';
      return {
        'success': true,
        'data': _customerJson(id: id, name: name),
      };
    }),
  ];
}

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

final _openTillSession = TillSession(
  sessionId: 'ts-1',
  tenantId: 'tenant-1',
  outletId: 'outlet-1',
  outletName: 'Main Outlet',
  tillId: 'till-1',
  tillCode: 'TILL-001',
  tillName: 'Front Till',
  openedDeviceId: '00000000-0000-0000-0000-000000000001',
  openingFloat: 0,
  status: 'open',
  openedAt: DateTime.utc(2026, 7, 1),
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
  _PresetDeviceActivationController(
    super.activateDevice,
    super.storage,
    PosDeviceContext deviceContext,
  ) : super() {
    state = DeviceActivationState(deviceContext: deviceContext);
  }
}

class _PresetTillController extends TillController {
  _PresetTillController(
    super.openTill,
    super.storage,
    TillSession? session,
  ) : super() {
    if (session != null) {
      state = TillState(session: session);
    }
  }
}

class _FakeDeviceActivationRepository implements DeviceActivationRepository {
  _FakeDeviceActivationRepository(this.deviceContext);

  final PosDeviceContext deviceContext;

  @override
  Future<PosDeviceContext> activateDevice(DeviceActivationForm form) async {
    return deviceContext;
  }

  @override
  Future<PosDeviceContext?> getCurrentDevice(DeviceActivationForm form) async {
    return deviceContext;
  }
}

class _FakeTillRepository implements TillRepository {
  _FakeTillRepository(this.session);

  final TillSession? session;

  @override
  Future<TillSession> openTill(OpenTillForm form) async => session!;

  @override
  Future<TillSession?> getCurrentSession(OpenTillForm form) async => session;

  @override
  Future<ClosedTillSession> closeTill(CloseTillForm form) {
    throw UnimplementedError();
  }
}

class _TestDeviceContextStorage extends DeviceContextStorage {
  _TestDeviceContextStorage(this.deviceContext)
      : super(const AppSecureStorage(FlutterSecureStorage()));

  final PosDeviceContext deviceContext;

  @override
  Future<PosDeviceContext?> read() async => deviceContext;

  @override
  Future<String> readOrCreateDeviceFingerprint() async {
    return deviceContext.deviceFingerprint;
  }

  @override
  Future<List<String>> readDeviceFingerprintCandidates() async {
    return [deviceContext.deviceFingerprint];
  }

  @override
  Future<void> save(PosDeviceContext context) async {}

  @override
  Future<void> clear() async {}
}

class _TestTillSessionStorage extends TillSessionStorage {
  _TestTillSessionStorage(this.session)
      : super(const AppSecureStorage(FlutterSecureStorage()));

  final TillSession? session;

  @override
  Future<TillSession?> read() async => session;

  @override
  Future<void> save(TillSession session) async {}

  @override
  Future<void> clear() async {}
}
