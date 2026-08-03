import 'package:flutter_test/flutter_test.dart';
import 'package:nytroz_pos/features/hardware/receipt_printer/adapters/bluetooth_receipt_printer_adapter.dart';
import 'package:nytroz_pos/features/hardware/receipt_printer/adapters/network_receipt_printer_adapter.dart';
import 'package:nytroz_pos/features/hardware/receipt_printer/adapters/receipt_printer_adapter.dart';
import 'package:nytroz_pos/features/hardware/receipt_printer/adapters/usb_receipt_printer_adapter.dart';
import 'package:nytroz_pos/features/hardware/receipt_printer/esc_pos/esc_pos_receipt_generator.dart';
import 'package:nytroz_pos/features/hardware/receipt_printer/models/pos_device_printer_config.dart';
import 'package:nytroz_pos/features/hardware/receipt_printer/models/local_print_agent_models.dart';
import 'package:nytroz_pos/features/hardware/receipt_printer/models/printer_exception.dart';
import 'package:nytroz_pos/features/hardware/receipt_printer/pos_receipt_printer_service.dart';
import 'package:nytroz_pos/features/returns_refunds/domain/entities/return_receipt.dart';
import 'package:nytroz_pos/features/returns_refunds/presentation/providers/return_success_display.dart';

ReturnReceipt _completionReceipt({
  String settlementMethodCode = 'CASH_REFUND',
  String resolution = 'REFUND',
  String? maskedCard,
  String? cardBrand,
  String? providerRef,
  double? amountPaid,
  double? amountRefunded,
  String differenceDirection = 'EVEN_EXCHANGE',
  int printCount = 0,
}) {
  return ReturnReceipt(
    returnId: 'ret-1',
    receiptNumber: 'RCPT-1',
    originalInvoiceNo: 'INV-1',
    returnedItemCount: 1,
    settlementMethodCode: settlementMethodCode,
    settlementMethodLabel:
        settlementMethodCode == 'CASH_REFUND' ? 'Cash Refund' : 'Card Refund',
    settlementDisplay: settlementMethodCode == 'CASH_REFUND'
        ? 'Cash Refund'
        : 'Visa •••• 1111',
    settlementResult: 'completed',
    currency: 'LKR',
    refundAmount: 100,
    customerCreditAmount: 100,
    completedAt: DateTime(2026, 7, 18, 10),
    returnStatus: 'COMPLETED',
    customerName: 'Customer',
    cashierName: 'Cashier',
    tillName: 'Till 01',
    approvalStatus: 'NOT_REQUIRED',
    customerAcknowledgement: '',
    resolution: resolution,
    canPrint: true,
    receiptId: 'rcp-1',
    originalSaleId: 'sale-1',
    returnNumber: 'RET-1',
    exchangeNumber: resolution == 'EXCHANGE' ? 'EXC-1' : null,
    outletName: 'Main Outlet',
    maskedCard: maskedCard,
    cardBrand: cardBrand,
    providerTransactionReference: providerRef,
    amountPaidByCustomer: amountPaid,
    amountRefundedToCustomer: amountRefunded,
    differenceDirection: differenceDirection,
    differenceAmount: resolution == 'EXCHANGE' ? 25 : null,
    returnSubtotal: 90,
    returnDiscount: 10,
    returnTax: 5,
    returnTotal: 85,
    printCount: printCount,
    hasBeenPrinted: printCount > 0,
    returnedItems: const [
      ReturnCompletionItem(
        saleLineId: 'line-1',
        name: 'Item One',
        variantLabel: 'Default',
        quantity: 1,
        unitPrice: 100,
        lineAmount: 85,
        subtotal: 90,
        discount: 10,
        tax: 5,
        total: 85,
        reasonDisplay: 'Damaged',
        conditionDisplay: 'Opened',
      ),
    ],
    replacementItems: resolution == 'EXCHANGE'
        ? const [
            ReturnCompletionItem(
              saleLineId: 'rep-1',
              name: 'Replacement',
              variantLabel: 'Blue',
              quantity: 1,
              unitPrice: 110,
              lineAmount: 110,
              isReplacement: true,
              subtotal: 110,
              discount: 0,
              tax: 0,
              total: 110,
            ),
          ]
        : const [],
  );
}

class _FakeAdapter implements ReceiptPrinterAdapter {
  _FakeAdapter(this.connectionType);

  @override
  final PrinterConnectionType connectionType;
  int printCalls = 0;
  bool failSend = false;

  @override
  Future<void> connect(PosDevicePrinterConfig config) async {}

  @override
  Future<void> checkStatus(PosDevicePrinterConfig config) async {}

  @override
  Future<void> printBytes(
    PosDevicePrinterConfig config,
    List<int> bytes,
  ) async {
    printCalls++;
    if (failSend) {
      throw const PrinterSendException('fake send failed');
    }
  }

  @override
  Future<void> disconnect() async {}
}

class _FakeStructuredAdapter extends _FakeAdapter
    implements StructuredReceiptPrinterAdapter {
  _FakeStructuredAdapter() : super(PrinterConnectionType.localPrintAgent);

  LocalPrintAgentReceiptRequest? request;

  @override
  Future<LocalPrintAgentPrintResult> printStructuredReceipt(
    PosDevicePrinterConfig config,
    LocalPrintAgentReceiptRequest request,
  ) async {
    printCalls++;
    this.request = request;
    return LocalPrintAgentPrintResult(
      success: true,
      code: 'printed',
      message: 'accepted',
      requestId: request.requestId,
      duplicate: false,
      printerName: config.displayName,
    );
  }
}

void main() {
  group('Step 10 completion display authority', () {
    test('builds display from Completion GET fields', () {
      final display =
          buildReturnSuccessDisplayFromReceipt(_completionReceipt());
      expect(display, isNotNull);
      expect(display!.tillName, 'Till 01');
      expect(display.returnDiscount, 10);
      expect(display.items.first.reasonDisplay, 'Damaged');
      expect(display.items.first.conditionDisplay, 'Opened');
      expect(display.showCardDetails, isFalse);
    });

    test('rejects STORE_CREDIT completions', () {
      expect(
        isValidCompletedReceipt(
          _completionReceipt(settlementMethodCode: 'STORE_CREDIT'),
        ),
        isFalse,
      );
    });

    test('cash hides card details; card shows safe mask', () {
      final cash = buildReturnSuccessDisplayFromReceipt(_completionReceipt());
      expect(cash!.showCardDetails, isFalse);

      final card = buildReturnSuccessDisplayFromReceipt(
        _completionReceipt(
          settlementMethodCode: 'CARD_REFUND',
          maskedCard: '•••• 1111',
          cardBrand: 'Visa',
          providerRef: 'ORIGINAL-PAY-1',
          differenceDirection: '',
        ),
      );
      expect(card!.showCardDetails, isTrue);
      expect(card.maskedCard, '•••• 1111');
      expect(card.providerTransactionReference, 'ORIGINAL-PAY-1');
    });

    test('EVEN_EXCHANGE hides paid/refunded amounts', () {
      final display = buildReturnSuccessDisplayFromReceipt(
        _completionReceipt(
          settlementMethodCode: 'EVEN_EXCHANGE',
          resolution: 'EXCHANGE',
          differenceDirection: 'EVEN_EXCHANGE',
          amountPaid: 0,
          amountRefunded: 0,
        ),
      );
      expect(display!.isEvenExchange, isTrue);
      expect(display.showPaidRefundedAmount, isFalse);
    });
  });

  group('Printer facade adapter selection', () {
    test('Local Agent exchange uses the structured completion contract',
        () async {
      final adapter = _FakeStructuredAdapter();
      final service = PosReceiptPrinterService(
        loadConfiguration: (_) async => const PosDevicePrinterConfig(
          deviceId: 'dev-1',
          enabled: true,
          connectionType: PrinterConnectionType.localPrintAgent,
          displayName: 'Configured receipt printer',
          paperWidth: PrinterPaperWidth.mm80,
          agentBaseUrl: 'http://192.168.1.20:9101',
          localApiKey: 'test-key-with-at-least-24-chars',
          configurationId: 'config-1',
          configurationVersion: 4,
        ),
        localPrintAgentAdapter: adapter,
      );

      final result = await service.printCompletionReceipt(
        deviceId: 'dev-1',
        receipt: _completionReceipt(resolution: 'EXCHANGE'),
        printRequestId: 'aaaaaaaa-aaaa-4aaa-aaaa-aaaaaaaaaaaa',
      );

      expect(adapter.printCalls, 1);
      expect(adapter.request!.receiptPurpose, 'exchange');
      expect(adapter.request!.originalReceiptReference, 'INV-1');
      expect(adapter.request!.items.first.itemGroup, 'Returned items');
      expect(adapter.request!.items.last.itemGroup, 'Replacement items');
      expect(adapter.request!.printerConfigurationVersion, 4);
      expect(result.routingPurpose, 'exchangeReceipt');
    });

    test('USB config selects only USB adapter', () async {
      final usb = _FakeAdapter(PrinterConnectionType.usb);
      final bt = _FakeAdapter(PrinterConnectionType.bluetooth);
      final net = _FakeAdapter(PrinterConnectionType.network);
      final service = PosReceiptPrinterService(
        loadConfiguration: (_) async => const PosDevicePrinterConfig(
          deviceId: 'dev-1',
          enabled: true,
          connectionType: PrinterConnectionType.usb,
          displayName: 'USB',
          paperWidth: PrinterPaperWidth.mm80,
          usbVendorId: 1,
          usbProductId: 2,
        ),
        usbAdapter: usb,
        bluetoothAdapter: bt,
        networkAdapter: net,
      );

      await service.printCompletionReceipt(
        deviceId: 'dev-1',
        receipt: _completionReceipt(),
        printRequestId: '11111111-1111-4111-a111-111111111111',
      );
      expect(usb.printCalls, 1);
      expect(bt.printCalls, 0);
      expect(net.printCalls, 0);
    });

    test('Bluetooth config selects only Bluetooth adapter', () async {
      final usb = _FakeAdapter(PrinterConnectionType.usb);
      final bt = _FakeAdapter(PrinterConnectionType.bluetooth);
      final net = _FakeAdapter(PrinterConnectionType.network);
      final service = PosReceiptPrinterService(
        loadConfiguration: (_) async => const PosDevicePrinterConfig(
          deviceId: 'dev-1',
          enabled: true,
          connectionType: PrinterConnectionType.bluetooth,
          displayName: 'BT',
          paperWidth: PrinterPaperWidth.mm58,
          bluetoothAddress: 'AA:BB',
        ),
        usbAdapter: usb,
        bluetoothAdapter: bt,
        networkAdapter: net,
      );

      await service.printCompletionReceipt(
        deviceId: 'dev-1',
        receipt: _completionReceipt(),
        printRequestId: '22222222-2222-4222-a222-222222222222',
      );
      expect(bt.printCalls, 1);
      expect(usb.printCalls, 0);
      expect(net.printCalls, 0);
    });

    test('Network config selects only network adapter', () async {
      final usb = _FakeAdapter(PrinterConnectionType.usb);
      final bt = _FakeAdapter(PrinterConnectionType.bluetooth);
      final net = _FakeAdapter(PrinterConnectionType.network);
      final service = PosReceiptPrinterService(
        loadConfiguration: (_) async => const PosDevicePrinterConfig(
          deviceId: 'dev-1',
          enabled: true,
          connectionType: PrinterConnectionType.network,
          displayName: 'LAN',
          paperWidth: PrinterPaperWidth.mm80,
          networkHost: '192.168.1.50',
        ),
        usbAdapter: usb,
        bluetoothAdapter: bt,
        networkAdapter: net,
      );

      await service.printCompletionReceipt(
        deviceId: 'dev-1',
        receipt: _completionReceipt(),
        printRequestId: '33333333-3333-4333-a333-333333333333',
      );
      expect(net.printCalls, 1);
      expect(usb.printCalls, 0);
      expect(bt.printCalls, 0);
    });

    test('no printer configured throws before any adapter send', () async {
      final usb = _FakeAdapter(PrinterConnectionType.usb);
      final service = PosReceiptPrinterService(
        loadConfiguration: (_) async => null,
        usbAdapter: usb,
        bluetoothAdapter: _FakeAdapter(PrinterConnectionType.bluetooth),
        networkAdapter: _FakeAdapter(PrinterConnectionType.network),
      );

      expect(
        () => service.printCompletionReceipt(
          deviceId: 'dev-1',
          receipt: _completionReceipt(),
          printRequestId: '44444444-4444-4444-a444-444444444444',
        ),
        throwsA(isA<PrinterNotConfiguredException>()),
      );
      expect(usb.printCalls, 0);
    });

    test('print failure does not claim success', () async {
      final usb = _FakeAdapter(PrinterConnectionType.usb)..failSend = true;
      final service = PosReceiptPrinterService(
        loadConfiguration: (_) async => const PosDevicePrinterConfig(
          deviceId: 'dev-1',
          enabled: true,
          connectionType: PrinterConnectionType.usb,
          displayName: 'USB',
          paperWidth: PrinterPaperWidth.mm80,
          usbVendorId: 1,
          usbProductId: 2,
        ),
        usbAdapter: usb,
      );

      expect(
        () => service.printCompletionReceipt(
          deviceId: 'dev-1',
          receipt: _completionReceipt(),
          printRequestId: '55555555-5555-4555-a555-555555555555',
        ),
        throwsA(isA<PrinterSendException>()),
      );
    });
  });

  group('ESC/POS generator', () {
    test('supports 58mm and 80mm without recalculating totals', () {
      const generator = EscPosReceiptGenerator();
      final receipt = _completionReceipt();
      final mm58 = generator.generate(
        receipt: receipt,
        config: const PosDevicePrinterConfig(
          deviceId: 'dev-1',
          enabled: true,
          connectionType: PrinterConnectionType.network,
          displayName: 'N',
          paperWidth: PrinterPaperWidth.mm58,
          networkHost: '127.0.0.1',
        ),
      );
      final mm80 = generator.generate(
        receipt: receipt,
        config: const PosDevicePrinterConfig(
          deviceId: 'dev-1',
          enabled: true,
          connectionType: PrinterConnectionType.network,
          displayName: 'N',
          paperWidth: PrinterPaperWidth.mm80,
          networkHost: '127.0.0.1',
        ),
      );
      expect(mm58, isNotEmpty);
      expect(mm80, isNotEmpty);
      final mm58Text =
          String.fromCharCodes(mm58.where((b) => b >= 32 && b < 127));
      final mm80Text =
          String.fromCharCodes(mm80.where((b) => b >= 32 && b < 127));
      expect(mm58Text, contains('85.00'));
      expect(mm80Text, contains('Till 01'));
    });
  });

  group('Platform adapter scaffolds', () {
    test('USB Bluetooth and Network adapters are selectable', () {
      expect(
        UsbReceiptPrinterAdapter().connectionType,
        PrinterConnectionType.usb,
      );
      expect(
        BluetoothReceiptPrinterAdapter().connectionType,
        PrinterConnectionType.bluetooth,
      );
      expect(
        NetworkReceiptPrinterAdapter().connectionType,
        PrinterConnectionType.network,
      );
    });
  });
}
