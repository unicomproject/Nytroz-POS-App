import 'package:flutter_test/flutter_test.dart';
import 'package:nytroz_pos/features/hardware/receipt_printer/adapters/receipt_printer_adapter.dart';
import 'package:nytroz_pos/features/hardware/receipt_printer/models/local_print_agent_models.dart';
import 'package:nytroz_pos/features/hardware/receipt_printer/models/pos_device_printer_config.dart';
import 'package:nytroz_pos/features/hardware/receipt_printer/non_sale_receipt_print_orchestrator.dart';
import 'package:nytroz_pos/features/hardware/receipt_printer/pos_receipt_printer_service.dart';
import 'package:nytroz_pos/features/hardware/receipt_printer/receipt_print_identity.dart';
import 'package:nytroz_pos/features/returns_refunds/domain/entities/return_receipt.dart';

void main() {
  group('non-sale receipt copy orchestration', () {
    test('customer and merchant copies have stable independent identities',
        () async {
      final adapter = _AgentAdapter();
      final audits = <Map<String, dynamic>>[];
      final orchestrator = _orchestrator(adapter, audits);

      final first = await orchestrator.print(
        deviceId: 'device-1',
        receipt: _receipt(),
        isReprint: false,
      );
      final firstIds =
          first.outcomes.map((item) => item.printRequestId).toList();
      final second = await orchestrator.print(
        deviceId: 'device-1',
        receipt: _receipt(),
        isReprint: false,
      );

      expect(first.outcomes, hasLength(2));
      expect(firstIds.toSet(), hasLength(2));
      expect(
        second.outcomes.map((item) => item.printRequestId),
        firstIds,
      );
      expect(audits.take(2).map((item) => item['copyType']),
          ['CUSTOMER', 'MERCHANT']);
      expect(audits.take(2).map((item) => item['copyIndex']), [1, 1]);
    });

    test('authorized historical exchange reprint labels every intended copy',
        () async {
      final adapter = _AgentAdapter();
      final audits = <Map<String, dynamic>>[];
      const operationId = 'eeeeeeee-eeee-4eee-aeee-eeeeeeeeeeee';

      final result = await _orchestrator(adapter, audits).print(
        deviceId: 'device-1',
        receipt: _receipt(exchange: true),
        isReprint: true,
        reprintOperationId: operationId,
        reprintReasonCode: 'CUSTOMER_REQUEST',
      );

      expect(result.allPrinted, isTrue);
      expect(adapter.requests, hasLength(2));
      expect(adapter.requests.every((request) => request.isReprint), isTrue);
      expect(
        adapter.requests.map((request) => request.receiptPurpose),
        everyElement('exchange'),
      );
      expect(audits.every((audit) => audit['isReprint'] == true), isTrue);
      expect(
        audits.every((audit) => audit['reprintOperationId'] == operationId),
        isTrue,
      );
    });

    test('one copy failure does not repeat a successful copy', () async {
      final adapter = _AgentAdapter(failMerchant: true);
      final audits = <Map<String, dynamic>>[];

      final result = await _orchestrator(adapter, audits).print(
        deviceId: 'device-1',
        receipt: _receipt(),
        isReprint: false,
      );

      expect(result.outcomes[0].status, ReceiptCopyOutcomeStatus.printed);
      expect(result.outcomes[1].status, ReceiptCopyOutcomeStatus.failed);
      expect(
        adapter.requests
            .where((request) => request.copyType == 'CUSTOMER')
            .length,
        1,
      );
      expect(audits, hasLength(2));
    });

    test('identity changes for a new controlled reprint operation', () {
      final first = ReceiptPrintIdentity.forCopy(
        operationId: 'operation-1',
        receiptPurpose: 'refundReprint',
        copyType: 'CUSTOMER',
        copyIndex: 1,
      );
      final second = ReceiptPrintIdentity.forCopy(
        operationId: 'operation-2',
        receiptPurpose: 'refundReprint',
        copyType: 'CUSTOMER',
        copyIndex: 1,
      );
      expect(first, isNot(second));
    });
  });
}

NonSaleReceiptPrintOrchestrator _orchestrator(
  _AgentAdapter adapter,
  List<Map<String, dynamic>> audits,
) {
  final service = PosReceiptPrinterService(
    loadConfiguration: (_) async => _config(),
    localPrintAgentAdapter: adapter,
  );
  return NonSaleReceiptPrintOrchestrator(
    printer: service,
    submitAudit: (_, audit) async => audits.add(Map.of(audit)),
  );
}

PosDevicePrinterConfig _config() => const PosDevicePrinterConfig(
      deviceId: 'device-1',
      enabled: true,
      connectionType: PrinterConnectionType.localPrintAgent,
      displayName: 'Configured printer',
      paperWidth: PrinterPaperWidth.mm80,
      agentBaseUrl: 'http://192.0.2.10:9101',
      localApiKey: 'test-only-secret-value-1234',
      supportedPurposes: {
        'returnReceipt',
        'exchangeReceipt',
        'refundReceipt',
      },
      printCustomerCopy: true,
      customerCopyCount: 1,
      printMerchantCopy: true,
      merchantCopyCount: 1,
      configurationId: 'cccccccc-cccc-4ccc-accc-cccccccccccc',
      configurationVersion: 2,
    );

ReturnReceipt _receipt({bool exchange = false}) => ReturnReceipt(
      returnId: 'aaaaaaaa-aaaa-4aaa-aaaa-aaaaaaaaaaaa',
      receiptId: 'bbbbbbbb-bbbb-4bbb-abbb-bbbbbbbbbbbb',
      originalSaleId: 'dddddddd-dddd-4ddd-addd-dddddddddddd',
      receiptNumber: exchange ? 'EX-100' : 'RF-100',
      originalInvoiceNo: 'SALE-100',
      returnedItemCount: 1,
      settlementMethodCode: exchange ? 'NO_SETTLEMENT' : 'CASH_REFUND',
      settlementMethodLabel: exchange ? 'No settlement' : 'Cash refund',
      settlementDisplay: exchange ? 'Even exchange' : 'Cash refund',
      settlementResult: exchange ? 'NO_SETTLEMENT' : 'CUSTOMER_RECEIVES',
      currency: 'LKR',
      refundAmount: exchange ? 0 : 1000,
      customerCreditAmount: 1000,
      completedAt: DateTime.utc(2026, 7, 29),
      returnStatus: 'COMPLETED',
      customerName: 'Customer',
      cashierName: 'Cashier',
      tillName: 'Till 01',
      approvalStatus: 'COMPLETED',
      customerAcknowledgement: '',
      resolution: exchange ? 'EXCHANGE' : 'REFUND',
      outletName: 'Main outlet',
      tillId: 'till-1',
      processedByUserId: 'user-1',
      processedByName: 'Cashier',
      receiptType: exchange ? 'EXCHANGE' : 'REFUND',
      returnNumber: 'RET-100',
      exchangeNumber: exchange ? 'EX-100' : null,
      returnedItems: const [
        ReturnCompletionItem(
          saleLineId: 'line-1',
          name: 'Product',
          variantLabel: 'SKU-1',
          quantity: 1,
          unitPrice: 1000,
          lineAmount: 1000,
          total: 1000,
        ),
      ],
      replacementItems: exchange
          ? const [
              ReturnCompletionItem(
                saleLineId: 'replacement-1',
                name: 'Replacement',
                variantLabel: 'SKU-2',
                quantity: 1,
                unitPrice: 1000,
                lineAmount: 1000,
                total: 1000,
                isReplacement: true,
              ),
            ]
          : const [],
      returnSubtotal: 1000,
      returnTotal: 1000,
      replacementSubtotal: exchange ? 1000 : null,
      replacementTotal: exchange ? 1000 : null,
    );

class _AgentAdapter
    implements ReceiptPrinterAdapter, StructuredReceiptPrinterAdapter {
  _AgentAdapter({this.failMerchant = false});

  final bool failMerchant;
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
  ) async {}

  @override
  Future<LocalPrintAgentPrintResult> printStructuredReceipt(
    PosDevicePrinterConfig config,
    LocalPrintAgentReceiptRequest request,
  ) async {
    requests.add(request);
    if (failMerchant && request.copyType == 'MERCHANT') {
      throw const LocalPrintAgentException(
        LocalPrintAgentFailureType.printerUnavailable,
        'Merchant copy failed.',
      );
    }
    return LocalPrintAgentPrintResult(
      success: true,
      code: 'printed',
      message: 'Printed',
      requestId: request.requestId,
      duplicate: false,
      printerName: 'Configured printer',
    );
  }
}
