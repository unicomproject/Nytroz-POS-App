import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nytroz_pos/core/network/dio_provider.dart';
import 'package:nytroz_pos/core/storage/app_secure_storage.dart';
import 'package:nytroz_pos/features/device_activation/application/usecases/activate_device.dart';
import 'package:nytroz_pos/features/device_activation/data/datasources/device_context_storage.dart';
import 'package:nytroz_pos/features/device_activation/domain/entities/pos_device_context.dart';
import 'package:nytroz_pos/features/device_activation/domain/repositories/device_activation_repository.dart';
import 'package:nytroz_pos/features/device_activation/presentation/providers/device_activation_provider.dart';
import 'package:nytroz_pos/features/sale/presentation/widgets/new_sale/pos_new_sale_customer_dialog.dart';

void main() {
  testWidgets('dialog is add-only with exactly three customer fields',
      (tester) async {
    var requestCount = 0;
    await tester.pumpWidget(
      _CustomerDialogTestApp(
        dio: _dioWithResponse(
          statusCode: 200,
          data: const {'success': true, 'data': <String, dynamic>{}},
          onRequest: (_) => requestCount++,
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.text('Add Customer'), findsWidgets);
    expect(find.byType(TextFormField), findsNWidgets(3));
    expect(find.text('Full Name'), findsOneWidget);
    expect(find.text('Phone Number'), findsOneWidget);
    expect(find.text('Email (Optional)'), findsOneWidget);
    expect(find.byIcon(Icons.close_rounded), findsOneWidget);
    expect(find.text('Select Customer'), findsNothing);
    expect(find.text('Quick Add Customer'), findsNothing);
    expect(find.byType(ListTile), findsNothing);
    expect(find.byIcon(Icons.search_rounded), findsNothing);
    expect(requestCount, 0,
        reason: 'Opening add-only dialog must not GET list');
  });

  testWidgets('add-only form validates name, phone, and optional email', (
    tester,
  ) async {
    await tester.pumpWidget(
      _CustomerDialogTestApp(
        dio: _dioWithResponse(
          statusCode: 200,
          data: {'success': true, 'data': <Object>[]},
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    final createButton = find.byKey(
      const ValueKey('create-customer-button'),
    );
    await tester.ensureVisible(createButton);
    await tester.tap(createButton);
    await tester.pumpAndSettle();

    expect(find.text('Full name is required'), findsOneWidget);
    expect(find.text('Phone number is required'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).at(0), 'Maya');
    await tester.enterText(
      find.byType(TextFormField).at(1),
      '0711111111',
    );
    await tester.enterText(
      find.byType(TextFormField).at(2),
      'not-an-email',
    );
    await tester.ensureVisible(createButton);
    await tester.tap(createButton);
    await tester.pumpAndSettle();

    expect(find.text('Enter a valid email address'), findsOneWidget);
  });

  testWidgets('submits only fullName, phone, and email to create API',
      (tester) async {
    RequestOptions? captured;
    await tester.pumpWidget(
      _CustomerDialogTestApp(
        dio: _dioWithResponse(
          statusCode: 201,
          onRequest: (request) => captured = request,
          data: {
            'success': true,
            'data': {
              'customerId': 'customer-1',
              'fullName': 'Maya Silva',
              'phone': '0711111111',
              'email': 'maya@example.com',
              'status': 'ACTIVE',
            },
          },
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('add-customer-name')),
      '  Maya Silva  ',
    );
    await tester.enterText(
      find.byKey(const ValueKey('add-customer-phone')),
      '0711111111',
    );
    await tester.enterText(
      find.byKey(const ValueKey('add-customer-email')),
      'maya@example.com',
    );
    await tester.tap(find.byKey(const ValueKey('create-customer-button')));
    await tester.pumpAndSettle();

    expect(captured?.method, 'POST');
    expect(captured?.path, '/api/v1/customers');
    expect(captured?.data, {
      'fullName': 'Maya Silva',
      'phone': '0711111111',
      'email': 'maya@example.com',
    });
    expect(find.text('Selected: Maya Silva'), findsOneWidget);
  });

  testWidgets('shows backend create error without closing the form',
      (tester) async {
    await tester.pumpWidget(
      _CustomerDialogTestApp(
        dio: _dioWithResponse(
          statusCode: 409,
          data: {'message': 'Phone number already exists.'},
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('add-customer-name')),
      'Duplicate Customer',
    );
    await tester.enterText(
      find.byKey(const ValueKey('add-customer-phone')),
      '0711111111',
    );
    await tester.tap(find.byKey(const ValueKey('create-customer-button')));
    await tester.pumpAndSettle();

    expect(find.text('Phone number already exists.'), findsOneWidget);
    expect(find.byKey(const ValueKey('add-customer-name')), findsOneWidget);
  });
}

class _CustomerDialogTestApp extends StatefulWidget {
  const _CustomerDialogTestApp({required this.dio});

  final Dio dio;

  @override
  State<_CustomerDialogTestApp> createState() => _CustomerDialogTestAppState();
}

class _CustomerDialogTestAppState extends State<_CustomerDialogTestApp> {
  String? _selectedName;

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      overrides: [
        appDioProvider.overrideWithValue(widget.dio),
        deviceContextStorageProvider.overrideWithValue(
          _TestDeviceContextStorage(),
        ),
        activateDeviceProvider.overrideWithValue(
          ActivateDevice(_FakeDeviceActivationRepository()),
        ),
        deviceActivationProvider.overrideWith(
          (ref) => _PresetDeviceActivationController(
            ref.watch(activateDeviceProvider),
            ref.watch(deviceContextStorageProvider),
            _deviceContext,
          ),
        ),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: Consumer(
            builder: (context, ref, _) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FilledButton(
                      onPressed: () async {
                        final customer = await showPosNewSaleCustomerDialog(
                          context: context,
                          ref: ref,
                          canCreateCustomer: true,
                        );
                        setState(() => _selectedName = customer?.displayName);
                      },
                      child: const Text('Open'),
                    ),
                    if (_selectedName != null) Text('Selected: $_selectedName'),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

Dio _dioWithResponse({
  required int statusCode,
  required Map<String, dynamic> data,
  ValueChanged<RequestOptions>? onRequest,
}) {
  final dio = Dio(BaseOptions(baseUrl: 'https://test.local'));
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        onRequest?.call(options);
        final response = Response<Map<String, dynamic>>(
          requestOptions: options,
          statusCode: statusCode,
          data: data,
        );
        if (statusCode >= 400) {
          handler.reject(
            DioException(
              requestOptions: options,
              response: response,
              type: DioExceptionType.badResponse,
            ),
          );
          return;
        }
        handler.resolve(response);
      },
    ),
  );
  return dio;
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

class _FakeDeviceActivationRepository implements DeviceActivationRepository {
  @override
  Future<PosDeviceContext> activateDevice(DeviceActivationForm form) async {
    return _deviceContext;
  }

  @override
  Future<PosDeviceContext?> getCurrentDevice(DeviceActivationForm form) async {
    return _deviceContext;
  }
}

class _TestDeviceContextStorage extends DeviceContextStorage {
  _TestDeviceContextStorage()
      : super(const AppSecureStorage(FlutterSecureStorage()));

  @override
  Future<PosDeviceContext?> read() async => _deviceContext;

  @override
  Future<String> readOrCreateDeviceFingerprint() async {
    return _deviceContext.deviceFingerprint;
  }

  @override
  Future<List<String>> readDeviceFingerprintCandidates() async {
    return [_deviceContext.deviceFingerprint];
  }

  @override
  Future<void> save(PosDeviceContext context) async {}

  @override
  Future<void> clear() async {}
}
