import 'package:flutter_test/flutter_test.dart';
import 'package:nytroz_pos/features/hardware/receipt_printer/adapters/receipt_printer_adapter.dart';
import 'package:nytroz_pos/features/hardware/receipt_printer/models/completed_sale_receipt.dart';
import 'package:nytroz_pos/features/hardware/receipt_printer/models/local_print_agent_models.dart';
import 'package:nytroz_pos/features/hardware/receipt_printer/models/pos_device_printer_config.dart';
import 'package:nytroz_pos/features/hardware/receipt_printer/pos_receipt_printer_service.dart';
import 'package:nytroz_pos/features/hardware/receipt_printer/recovery/print_operation.dart';
import 'package:nytroz_pos/features/sale/presentation/providers/completed_sale_print_provider.dart';

void main() {
  group('completed-sale Local Print Agent', () {
    test('routes authoritative receipt through structured HTTP adapter',
        () async {
      final adapter = _StructuredAgentAdapter();
      final service = _service(adapter);

      final result = await service.printCompletedSale(
        receipt: _receipt(),
        printRequestId: _receipt().saleId,
      );

      expect(adapter.structuredPrintCalls, 1);
      expect(adapter.bytePrintCalls, 0);
      expect(adapter.lastRequest?.receiptNumber, 'REC-100');
      expect(adapter.lastRequest?.items.single.lineTotal, 1250);
      expect(adapter.lastRequest?.total, 1250);
      expect(adapter.lastRequest?.barcodeValue, 'REC-100');
      expect(adapter.lastRequest?.toJson()['barcodeValue'], 'REC-100');
      expect(result.transport, 'localPrintAgent');
      expect(result.agentResult, 'printed');
    });

    test('one sale triggers one physical print and one audit', () async {
      final adapter = _StructuredAgentAdapter();
      var audits = 0;
      final controller = CompletedSalePrintController(
        _service(adapter),
        (_, __) async => audits++,
      );

      await controller.printAutomatically(_receipt());
      await controller.printAutomatically(_receipt());

      expect(adapter.structuredPrintCalls, 1);
      expect(audits, 1);
      expect(controller.state.status, CompletedSalePrintStatus.printed);
    });

    test('audit-only retry never resends the physical receipt', () async {
      final adapter = _StructuredAgentAdapter();
      var audits = 0;
      final controller = CompletedSalePrintController(
        _service(adapter),
        (_, __) async {
          audits++;
          if (audits == 1) throw Exception('temporary audit failure');
        },
      );

      await controller.printAutomatically(_receipt());
      expect(controller.state.auditPending, isTrue);
      await controller.retryAuditOnly();

      expect(adapter.structuredPrintCalls, 1);
      expect(audits, 2);
      expect(controller.state.auditPending, isFalse);
    });

    test('operator confirmation records a linked audit without reprinting',
        () async {
      final adapter = _StructuredAgentAdapter();
      final audits = <Map<String, dynamic>>[];
      final controller = CompletedSalePrintController(
        _service(adapter),
        (_, audit) async => audits.add(Map<String, dynamic>.from(audit)),
      );
      const physicalRequestId = 'aaaaaaaa-aaaa-4aaa-aaaa-aaaaaaaaaaaa';
      final now = DateTime.utc(2026, 7, 29);
      final operation = PrintOperation(
        operationId: 'operation-1',
        receipt: _receipt(),
        printRequestId: physicalRequestId,
        operatorUserId: _receipt().cashierId,
        deviceId: _receipt().deviceId,
        createdAt: now,
        updatedAt: now,
        state: PrintOperationState.requiresOperatorDecision,
        audit: const {
          'status': 'failed',
          'printRequestId': physicalRequestId,
          'unknownOutcome': true,
        },
      );

      await controller.confirmPrinted(operation);

      expect(adapter.structuredPrintCalls, 0);
      expect(audits, hasLength(1));
      expect(audits.single['status'], 'success');
      expect(audits.single['printRequestId'], isNot(physicalRequestId));
      expect(audits.single['recoveryPrintRequestId'], physicalRequestId);
      expect(audits.single['agentResult'], 'operator_confirmed_printed');
    });

    test(
        'customer and merchant copies use independent stable print and audit identities',
        () async {
      final adapter = _StructuredAgentAdapter();
      final audits = <Map<String, dynamic>>[];
      final controller = CompletedSalePrintController(
        _service(adapter),
        (_, audit) async => audits.add(Map<String, dynamic>.from(audit)),
      );
      final receipt = _receipt().forCopy(copyType: 'CUSTOMER', copyIndex: 1);
      final configured = CompletedSaleReceipt.fromJson({
        ...receipt.toJson(),
        'copyPolicy': const CompletedSaleCopyPolicy(
          customerCopyCount: 1,
          merchantCopyCount: 1,
          printCustomerCopy: true,
          printMerchantCopy: true,
        ).toJson(),
      });

      await controller.printAutomatically(configured);
      await controller.printAutomatically(configured);

      expect(adapter.requests, hasLength(2));
      expect(adapter.requests.map((x) => x.copyType), ['CUSTOMER', 'MERCHANT']);
      expect(
          adapter.requests[0].requestId, isNot(adapter.requests[1].requestId));
      expect(audits, hasLength(2));
      expect(audits.map((x) => x['copyType']), ['CUSTOMER', 'MERCHANT']);
      expect(audits.map((x) => x['copyIndex']), [1, 1]);
    });
  });
}

PosReceiptPrinterService _service(_StructuredAgentAdapter adapter) {
  return PosReceiptPrinterService(
    loadConfiguration: (_) async => _config(),
    localPrintAgentAdapter: adapter,
  );
}

PosDevicePrinterConfig _config() => const PosDevicePrinterConfig(
      deviceId: 'device-1',
      enabled: true,
      connectionType: PrinterConnectionType.localPrintAgent,
      displayName: 'POSPrinter POS80',
      paperWidth: PrinterPaperWidth.mm80,
      agentBaseUrl: 'http://192.168.18.160:9101',
      localApiKey: 'secret-used-but-never-logged',
      connectionTimeoutMs: 5000,
    );

CompletedSaleReceipt _receipt() => CompletedSaleReceipt(
      receiptId: 'bbbbbbbb-bbbb-4bbb-abbb-bbbbbbbbbbbb',
      saleId: 'aaaaaaaa-aaaa-4aaa-aaaa-aaaaaaaaaaaa',
      receiptNumber: 'REC-100',
      completedAt: DateTime.utc(2026, 7, 28),
      merchantName: 'OneVerz',
      outletName: 'Main Outlet',
      tillId: 'cccccccc-cccc-4ccc-accc-cccccccccccc',
      tillName: 'Till 01',
      cashierId: 'dddddddd-dddd-4ddd-addd-dddddddddddd',
      cashierName: 'Cashier',
      deviceId: 'device-1',
      currency: 'LKR',
      items: const [
        CompletedSaleReceiptLine(
          name: 'Product',
          quantity: 1,
          unitPrice: 1250,
          lineTotal: 1250,
          variantOrSku: 'SKU-1',
        ),
      ],
      subtotal: 1250,
      discountTotal: 0,
      taxTotal: 0,
      total: 1250,
      paymentMethods: const ['cash'],
      amountTendered: 1500,
      change: 250,
      barcodeValue: 'REC-100',
    );

class _StructuredAgentAdapter
    implements ReceiptPrinterAdapter, StructuredReceiptPrinterAdapter {
  int structuredPrintCalls = 0;
  int bytePrintCalls = 0;
  LocalPrintAgentReceiptRequest? lastRequest;
  final List<LocalPrintAgentReceiptRequest> requests = [];

  @override
  PrinterConnectionType get connectionType =>
      PrinterConnectionType.localPrintAgent;

  @override
  Future<void> connect(PosDevicePrinterConfig config) async {}

  @override
  Future<void> checkStatus(PosDevicePrinterConfig config) async {}

  @override
  Future<void> disconnect() async {}

  @override
  Future<void> printBytes(
    PosDevicePrinterConfig config,
    List<int> bytes,
  ) async {
    bytePrintCalls++;
  }

  @override
  Future<LocalPrintAgentPrintResult> printStructuredReceipt(
    PosDevicePrinterConfig config,
    LocalPrintAgentReceiptRequest request,
  ) async {
    structuredPrintCalls++;
    lastRequest = request;
    requests.add(request);
    return LocalPrintAgentPrintResult(
      success: true,
      code: 'printed',
      message: 'Printed',
      requestId: request.requestId,
      duplicate: false,
      printerName: 'POSPrinter POS80',
    );
  }
}
