import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nytroz_pos/core/storage/app_secure_storage.dart';
import 'package:nytroz_pos/features/cart/data/datasources/pos_discount_remote_datasource.dart';
import 'package:nytroz_pos/features/cart/domain/entities/pos_cart_discount.dart';
import 'package:nytroz_pos/features/cart/domain/entities/pos_discount_api_models.dart';
import 'package:nytroz_pos/features/cart/presentation/providers/pos_discount_provider.dart';
import 'package:nytroz_pos/features/cart/presentation/providers/pos_new_sale_cart_provider.dart';
import 'package:nytroz_pos/features/device_activation/application/usecases/activate_device.dart';
import 'package:nytroz_pos/features/device_activation/data/datasources/device_context_storage.dart';
import 'package:nytroz_pos/features/device_activation/domain/entities/pos_device_context.dart';
import 'package:nytroz_pos/features/device_activation/domain/repositories/device_activation_repository.dart';
import 'package:nytroz_pos/features/device_activation/presentation/providers/device_activation_provider.dart';
import 'package:nytroz_pos/features/sale/domain/entities/pos_checkout_summary.dart';
import 'package:nytroz_pos/features/sale/domain/entities/pos_customer.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
      'customer change rebinds approved discount with new customerId',
      () async {
    final cancelIds = <String>[];
    final applyCustomerIds = <String?>[];
    final container = _container(
      discount: _FakeDiscountDatasource(
        onCancel: cancelIds.add,
        onApply: (customerId) {
          applyCustomerIds.add(customerId);
          return const PosDiscountApplyResult(
            applicationId: 'app-rebound',
            discountId: 'policy-1',
            applied: true,
            status: 'approved',
            subtotal: 1500,
            discountAmount: 150,
            totalAfterDiscount: 1350,
            requiresManagerApproval: false,
            cartHash: 'hash-with-customer',
            messages: [],
          );
        },
      ),
    );
    addTearDown(container.dispose);

    final cart = container.read(posNewSaleCartProvider.notifier);
    cart.addToCart(_product);
    cart.applyCartDiscount(const PosCartDiscount(
      valueType: PosDiscountValueType.percentage,
      value: 10,
      reason: 'Promo',
      policyId: 'policy-1',
      applicationId: 'app-original',
      status: 'approved',
      cartHash: 'hash-no-customer',
      source: 'MANUAL',
      discountAmount: 150,
      totalAfterDiscount: 1350,
    ));
    cart.setCustomer(const PosCustomer(
      customerId: 'customer-1',
      fullName: 'Alice',
    ));

    final error = await rebindPosDiscountsAfterCustomerChange(
      read: container.read,
      invalidate: container.invalidate,
    );

    expect(error, isNull);
    expect(cancelIds, ['app-original']);
    expect(applyCustomerIds, ['customer-1']);
    final rebound = container.read(posNewSaleCartProvider).cartDiscount;
    expect(rebound?.applicationId, 'app-rebound');
    expect(rebound?.cartHash, 'hash-with-customer');
    expect(rebound?.discountAmount, 150);
  });

  test('customer change with no discount skips discount APIs', () async {
    var cancelCalled = false;
    var applyCalled = false;
    final container = _container(
      discount: _FakeDiscountDatasource(
        onCancel: (_) => cancelCalled = true,
        onApply: (_) {
          applyCalled = true;
          throw StateError('should not apply');
        },
      ),
    );
    addTearDown(container.dispose);

    final cart = container.read(posNewSaleCartProvider.notifier);
    cart.addToCart(_product);
    cart.setCustomer(const PosCustomer(
      customerId: 'customer-1',
      fullName: 'Alice',
    ));

    final error = await rebindPosDiscountsAfterCustomerChange(
      read: container.read,
      invalidate: container.invalidate,
    );

    expect(error, isNull);
    expect(cancelCalled, isFalse);
    expect(applyCalled, isFalse);
  });
}

ProviderContainer _container({required PosDiscountRemoteDatasource discount}) {
  return ProviderContainer(overrides: [
    posDiscountRemoteDatasourceProvider.overrideWithValue(discount),
    activateDeviceProvider.overrideWithValue(
      ActivateDevice(_FakeDeviceActivationRepository()),
    ),
    deviceContextStorageProvider.overrideWithValue(_TestDeviceContextStorage()),
    deviceActivationProvider.overrideWith(
      (ref) => _PresetDeviceActivationController(
        ref.watch(activateDeviceProvider),
        ref.watch(deviceContextStorageProvider),
      ),
    ),
  ]);
}

const _product = PosNewSaleProduct(
  id: 'product-1',
  productId: 'product-1',
  variantId: 'variant-1',
  name: 'Jersey',
  category: 'Apparel',
  price: 1500,
);

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

class _FakeDiscountDatasource extends PosDiscountRemoteDatasource {
  _FakeDiscountDatasource({
    required this.onCancel,
    required this.onApply,
  }) : super(Dio());

  final void Function(String applicationId) onCancel;
  final PosDiscountApplyResult Function(String? customerId) onApply;

  @override
  Future<void> cancel({
    required String applicationId,
    required String deviceId,
    String? reason,
  }) async {
    onCancel(applicationId);
  }

  @override
  Future<PosDiscountApplyResult> apply({
    required String deviceId,
    String? discountId,
    required String discountSource,
    required String scope,
    required String calculationMethod,
    required List<PosCheckoutLineRequest> lines,
    required String idempotencyKey,
    double? requestedValue,
    String? targetVariantId,
    String? reason,
    String? customerId,
  }) async {
    return onApply(customerId);
  }
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
