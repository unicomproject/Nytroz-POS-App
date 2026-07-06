import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nytroz_pos/core/network/dio_provider.dart';
import 'package:nytroz_pos/features/device_activation/application/usecases/activate_device.dart';
import 'package:nytroz_pos/features/device_activation/data/datasources/device_context_storage.dart';
import 'package:nytroz_pos/features/device_activation/domain/entities/pos_device_context.dart';
import 'package:nytroz_pos/features/device_activation/domain/repositories/device_activation_repository.dart';
import 'package:nytroz_pos/features/device_activation/presentation/providers/device_activation_provider.dart';
import 'package:nytroz_pos/features/sale/presentation/widgets/new_sale/pos_new_sale_customer_dialog.dart';

void main() {
  testWidgets('customer dialog visibly loads and selects customers', (
    tester,
  ) async {
    await tester.pumpWidget(
      _CustomerDialogTestApp(
        dio: _dioWithResponse(
          statusCode: 200,
          data: {
            'success': true,
            'data': [
              {
                'CustomerId': 'customer-1',
                'FullName': 'Tom',
                'Phone': '0771234567',
                'Email': 'tom@example.com',
                'Status': 'active',
              },
            ],
          },
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pump();
    expect(find.text('Select Customer'), findsOneWidget);
    expect(find.text('Loading customers...'), findsOneWidget);

    await tester.pumpAndSettle();

    expect(find.text('Tom'), findsOneWidget);
    expect(find.text('0771234567 • tom@example.com'), findsOneWidget);
    expect(find.text('Quick Add Customer'), findsOneWidget);
    expect(find.byIcon(Icons.close_rounded), findsOneWidget);

    await tester.tap(find.text('Tom'));
    await tester.pumpAndSettle();

    expect(find.text('Selected: Tom'), findsOneWidget);
  });

  testWidgets('customer dialog shows API error and retry', (tester) async {
    await tester.pumpWidget(
      _CustomerDialogTestApp(
        dio: _dioWithResponse(statusCode: 500, data: {'message': 'Failed'}),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.text('Unable to load customers. Try again.'), findsOneWidget);
    expect(find.widgetWithText(TextButton, 'Retry'), findsOneWidget);
    expect(find.widgetWithText(TextButton, 'Close'), findsOneWidget);
  });

  testWidgets('quick add validates required fields and optional email', (
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

    final createButton = find.widgetWithText(FilledButton, 'Create Customer');
    await tester.ensureVisible(createButton);
    await tester.tap(createButton);
    await tester.pumpAndSettle();

    expect(find.text('Name is required'), findsOneWidget);
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

    expect(find.text('Enter a valid email'), findsOneWidget);
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
}) {
  final dio = Dio(BaseOptions(baseUrl: 'https://test.local'));
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
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
  _TestDeviceContextStorage() : super(const FlutterSecureStorage());

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
