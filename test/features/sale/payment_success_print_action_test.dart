import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nytroz_pos/core/storage/app_secure_storage.dart';
import 'package:nytroz_pos/features/auth/data/datasources/auth_session_storage.dart';
import 'package:nytroz_pos/features/auth/domain/entities/auth_session.dart';
import 'package:nytroz_pos/features/auth/presentation/providers/session_provider.dart';
import 'package:nytroz_pos/features/device_activation/application/usecases/activate_device.dart';
import 'package:nytroz_pos/features/device_activation/data/datasources/device_context_storage.dart';
import 'package:nytroz_pos/features/device_activation/domain/entities/pos_device_context.dart';
import 'package:nytroz_pos/features/device_activation/domain/repositories/device_activation_repository.dart';
import 'package:nytroz_pos/features/device_activation/presentation/providers/device_activation_provider.dart';
import 'package:nytroz_pos/features/hardware/receipt_printer/adapters/receipt_printer_adapter.dart';
import 'package:nytroz_pos/features/hardware/receipt_printer/models/local_print_agent_models.dart';
import 'package:nytroz_pos/features/hardware/receipt_printer/models/pos_device_printer_config.dart';
import 'package:nytroz_pos/features/hardware/receipt_printer/pos_receipt_printer_service.dart';
import 'package:nytroz_pos/features/sale/data/mappers/completed_sale_receipt_mapper.dart';
import 'package:nytroz_pos/features/sale/domain/entities/pos_checkout_summary.dart';
import 'package:nytroz_pos/features/sale/presentation/providers/completed_sale_print_provider.dart';
import 'package:nytroz_pos/features/sale/presentation/providers/pos_cash_payment_success_provider.dart';
import 'package:nytroz_pos/features/sale/presentation/widgets/print_receipt/print_receipt_actions.dart';

void main() {
  group('Checkout + Payment Success receipt print', () {
    test('checkout retains authoritative payment for first original print', () {
      final notifier = PosCashPaymentSuccessNotifier();
      final payment = _completedPayment();
      notifier.recordCheckoutPayment(payment);

      expect(notifier.state, isNotNull);
      expect(notifier.state!.saleId, payment.saleId);
      expect(notifier.state!.authoritativePayment!.saleId, payment.saleId);
      expect(
        notifier.state!.authoritativePayment!.receiptNumber,
        payment.receiptNumber,
      );
      expect(
        notifier.state!.authoritativePayment!.grandTotal,
        payment.grandTotal,
      );
    });

    test(
        'first original print from authoritative payload prints once and blocks duplicates',
        () async {
      final adapter = _StructuredAgentAdapter();
      final controller = CompletedSalePrintController(
        PosReceiptPrinterService(
          loadConfiguration: (_) async => _config(),
          localPrintAgentAdapter: adapter,
        ),
        (_, __) async {},
      );
      final receipt = const CompletedSaleReceiptMapper().fromCompletedPayment(
        payment: _completedPayment(),
        device: _device(),
        session: _session(),
      );

      await controller.printAutomatically(receipt);
      await controller.printAutomatically(receipt);

      expect(adapter.structuredPrintCalls, 1);
      expect(controller.state.status, CompletedSalePrintStatus.printed);
      expect(controller.state.saleId, receipt.saleId);
    });

    test('print-again after original success sends a second physical copy',
        () async {
      final adapter = _StructuredAgentAdapter();
      final controller = CompletedSalePrintController(
        PosReceiptPrinterService(
          loadConfiguration: (_) async => _config(),
          localPrintAgentAdapter: adapter,
        ),
        (_, __) async {},
      );
      final receipt = const CompletedSaleReceiptMapper().fromCompletedPayment(
        payment: _completedPayment(),
        device: _device(),
        session: _session(),
      );

      await controller.printAutomatically(receipt);
      await controller.printAgainFromPaymentSuccess();

      expect(adapter.structuredPrintCalls, 2);
      expect(controller.state.status, CompletedSalePrintStatus.printed);
    });

    test('printer failure leaves sale print state retryable', () async {
      final adapter = _StructuredAgentAdapter(fail: true);
      final controller = CompletedSalePrintController(
        PosReceiptPrinterService(
          loadConfiguration: (_) async => _config(),
          localPrintAgentAdapter: adapter,
        ),
        (_, __) async {},
      );
      final receipt = const CompletedSaleReceiptMapper().fromCompletedPayment(
        payment: _completedPayment(),
        device: _device(),
        session: _session(),
      );

      await controller.printAutomatically(receipt);

      expect(adapter.structuredPrintCalls, 1);
      expect(controller.state.canRetryPrint, isTrue);
      expect(controller.state.status, isNot(CompletedSalePrintStatus.printed));
    });

    testWidgets(
      'Print Receipt button starts original print from idle completed-sale state',
      (tester) async {
        final adapter = _StructuredAgentAdapter();
        final payment = _completedPayment();
        final container = ProviderContainer(
          overrides: [
            completedSalePrintProvider.overrideWith(
              (ref) => CompletedSalePrintController(
                PosReceiptPrinterService(
                  loadConfiguration: (_) async => _config(),
                  localPrintAgentAdapter: adapter,
                ),
                (_, __) async {},
              ),
            ),
            posCashPaymentSuccessProvider.overrideWith(
              (ref) {
                final notifier = PosCashPaymentSuccessNotifier();
                notifier.recordCheckoutPayment(payment);
                return notifier;
              },
            ),
            authSessionProvider.overrideWith(
              (ref) => _PresetAuthSessionNotifier(_session()),
            ),
            activateDeviceProvider.overrideWithValue(
              ActivateDevice(_FakeDeviceActivationRepository(_device())),
            ),
            deviceContextStorageProvider.overrideWithValue(
              _TestDeviceContextStorage(_device()),
            ),
            deviceActivationProvider.overrideWith(
              (ref) => _PresetDeviceActivationController(
                ref.watch(activateDeviceProvider),
                ref.watch(deviceContextStorageProvider),
                _device(),
              ),
            ),
          ],
        );
        addTearDown(container.dispose);

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              home: Scaffold(
                body: Consumer(
                  builder: (context, ref, _) {
                    return TextButton(
                      onPressed: () => executeReceiptPrint(
                        context,
                        ref,
                        payment.saleId,
                      ),
                      child: const Text('Print Receipt'),
                    );
                  },
                ),
              ),
            ),
          ),
        );

        expect(
          container.read(completedSalePrintProvider).status,
          CompletedSalePrintStatus.idle,
        );

        await tester.tap(find.text('Print Receipt'));
        await tester.pumpAndSettle();

        expect(adapter.structuredPrintCalls, 1);
        expect(
          container.read(completedSalePrintProvider).status,
          CompletedSalePrintStatus.printed,
        );

        await tester.tap(find.text('Print Receipt'));
        await tester.pumpAndSettle();
        // Second tap is deliberate print-again (reprint), not duplicate original.
        expect(adapter.structuredPrintCalls, 2);
      },
    );

    testWidgets(
      'checkout auto-print helper prints once; button print-again adds second copy',
      (tester) async {
        final adapter = _StructuredAgentAdapter();
        final payment = _completedPayment();
        final container = ProviderContainer(
          overrides: [
            completedSalePrintProvider.overrideWith(
              (ref) => CompletedSalePrintController(
                PosReceiptPrinterService(
                  loadConfiguration: (_) async => _config(),
                  localPrintAgentAdapter: adapter,
                ),
                (_, __) async {},
              ),
            ),
            posCashPaymentSuccessProvider.overrideWith(
              (ref) {
                final notifier = PosCashPaymentSuccessNotifier();
                notifier.recordCheckoutPayment(payment);
                return notifier;
              },
            ),
            authSessionProvider.overrideWith(
              (ref) => _PresetAuthSessionNotifier(_session()),
            ),
            activateDeviceProvider.overrideWithValue(
              ActivateDevice(_FakeDeviceActivationRepository(_device())),
            ),
            deviceContextStorageProvider.overrideWithValue(
              _TestDeviceContextStorage(_device()),
            ),
            deviceActivationProvider.overrideWith(
              (ref) => _PresetDeviceActivationController(
                ref.watch(activateDeviceProvider),
                ref.watch(deviceContextStorageProvider),
                _device(),
              ),
            ),
          ],
        );
        addTearDown(container.dispose);

        await triggerCheckoutReceiptAutoPrint(
          container.read,
          saleId: payment.saleId,
        );
        expect(adapter.structuredPrintCalls, 1);
        expect(
          container.read(completedSalePrintProvider).status,
          CompletedSalePrintStatus.printed,
        );

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              home: Scaffold(
                body: Consumer(
                  builder: (context, ref, _) {
                    return TextButton(
                      onPressed: () => executeReceiptPrint(
                        context,
                        ref,
                        payment.saleId,
                      ),
                      child: const Text('Print Again'),
                    );
                  },
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Print Again'));
        await tester.pumpAndSettle();
        expect(adapter.structuredPrintCalls, 2);
      },
    );
  });
}

PosDevicePrinterConfig _config() => const PosDevicePrinterConfig(
      deviceId: 'device-1',
      enabled: true,
      connectionType: PrinterConnectionType.localPrintAgent,
      displayName: 'Agent',
      paperWidth: PrinterPaperWidth.mm80,
      agentBaseUrl: 'http://127.0.0.1:9101',
      localApiKey: '123456789012345678901234',
    );

AuthSession _session() => const AuthSession(
      accessToken: 'token',
      refreshToken: 'refresh',
      userId: 'cashier-1',
      userDisplayName: 'Cashier',
      permissionCodes: ['receipts.print'],
    );

PosDeviceContext _device() => PosDeviceContext(
      deviceId: 'device-1',
      deviceCode: 'POS-1',
      deviceName: 'POS-1',
      deviceType: 'fixed_pos_tablet',
      platform: 'windows',
      deviceFingerprint: 'fp-1',
      isTrusted: true,
      tenantId: 'tenant-1',
      outletId: 'outlet-1',
      outletName: 'Main Outlet',
      tillId: 'till-1',
      tillCode: 'T1',
      tillName: 'Till 01',
      pairedAt: DateTime.utc(2026, 8, 1),
    );

PosCheckoutStartPaymentPayload _completedPayment() {
  final completedAt = DateTime.utc(2026, 8, 16, 10);
  return PosCheckoutStartPaymentPayload(
    checkoutSessionId: 'checkout',
    saleId: 'aaaaaaaa-aaaa-4aaa-aaaa-aaaaaaaaaaaa',
    saleNumber: 'SALE-1',
    paymentMethod: 'cash',
    grandTotal: 1000,
    currency: 'LKR',
    saleStatus: 'completed',
    nextAction: 'completed',
    receiptNumber: 'REC-1',
    barcodeValue: 'REC-1',
    completedAt: completedAt,
    subtotal: 1000,
    discount: 0,
    tax: 0,
    cashReceived: 1000,
    changeDue: 0,
    receiptId: 'bbbbbbbb-bbbb-4bbb-abbb-bbbbbbbbbbbb',
    merchantName: 'OneVerz',
    outletName: 'Main Outlet',
    tillId: 'till-1',
    tillName: 'Till 01',
    cashierId: 'cashier-1',
    cashierName: 'Cashier',
    items: const [
      PosCheckoutCompletedLinePayload(
        name: 'Item',
        quantity: 1,
        unitPrice: 1000,
        lineTotal: 1000,
      ),
    ],
    tenders: const [
      PosReceiptTenderPayload(
        paymentId: 'payment-1',
        methodCode: 'CASH',
        methodName: 'Cash',
        methodType: 'CASH',
        amount: 1000,
        amountTendered: 1000,
        changeAmount: 0,
        currency: 'LKR',
        status: 'CAPTURED',
      ),
    ],
  );
}

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

class _FakeDeviceActivationRepository implements DeviceActivationRepository {
  _FakeDeviceActivationRepository(this.deviceContext);

  final PosDeviceContext deviceContext;

  @override
  Future<PosDeviceContext> activateDevice(DeviceActivationForm form) async =>
      deviceContext;

  @override
  Future<PosDeviceContext?> getCurrentDevice(DeviceActivationForm form) async =>
      deviceContext;
}

class _TestDeviceContextStorage extends DeviceContextStorage {
  _TestDeviceContextStorage(this.deviceContext)
      : super(const AppSecureStorage(FlutterSecureStorage()));

  final PosDeviceContext deviceContext;

  @override
  Future<PosDeviceContext?> read() async => deviceContext;

  @override
  Future<void> save(PosDeviceContext context) async {}

  @override
  Future<void> clear() async {}

  @override
  Future<void> clearContext() async {}

  @override
  Future<String> readOrCreateDeviceFingerprint() async => 'fp-1';

  @override
  Future<List<String>> readDeviceFingerprintCandidates() async =>
      const ['fp-1'];
}

class _StructuredAgentAdapter
    implements ReceiptPrinterAdapter, StructuredReceiptPrinterAdapter {
  _StructuredAgentAdapter({this.fail = false});

  final bool fail;
  int structuredPrintCalls = 0;

  @override
  PrinterConnectionType get connectionType =>
      PrinterConnectionType.localPrintAgent;

  @override
  Future<void> connect(PosDevicePrinterConfig config) async {}

  @override
  Future<void> checkStatus(PosDevicePrinterConfig config) async {}

  @override
  Future<void> printBytes(
    PosDevicePrinterConfig config,
    List<int> bytes,
  ) async {}

  @override
  Future<void> disconnect() async {}

  @override
  Future<LocalPrintAgentPrintResult> printStructuredReceipt(
    PosDevicePrinterConfig config,
    LocalPrintAgentReceiptRequest request,
  ) async {
    structuredPrintCalls++;
    if (fail) {
      throw const LocalPrintAgentException(
        LocalPrintAgentFailureType.printerUnavailable,
        'Printer offline',
      );
    }
    return LocalPrintAgentPrintResult(
      success: true,
      code: 'printed',
      message: 'ok',
      requestId: request.requestId,
      duplicate: false,
      printerName: 'POS80',
      bytesWritten: 10,
    );
  }
}
