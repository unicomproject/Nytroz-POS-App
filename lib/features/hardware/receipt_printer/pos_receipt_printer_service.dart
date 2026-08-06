import 'dart:developer' as developer;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../returns_refunds/domain/entities/return_receipt.dart';
import 'adapters/bluetooth_receipt_printer_adapter.dart';
import 'adapters/network_receipt_printer_adapter.dart';
import 'adapters/local_print_agent_adapter.dart';
import 'adapters/receipt_printer_adapter.dart';
import 'adapters/usb_receipt_printer_adapter.dart';
import 'config/pos_device_printer_config_store.dart';
import 'esc_pos/esc_pos_receipt_generator.dart';
import 'models/pos_device_printer_config.dart';
import 'models/printer_exception.dart';
import 'clients/local_print_agent_client.dart';
import 'models/completed_sale_receipt.dart';
import 'models/local_print_agent_models.dart';

typedef PosPrinterConfigLoader = Future<PosDevicePrinterConfig?> Function(
  String deviceId,
);

class PosReceiptPrinterService {
  PosReceiptPrinterService({
    required PosPrinterConfigLoader loadConfiguration,
    EscPosReceiptGenerator generator = const EscPosReceiptGenerator(),
    ReceiptPrinterAdapter? usbAdapter,
    ReceiptPrinterAdapter? bluetoothAdapter,
    ReceiptPrinterAdapter? networkAdapter,
    ReceiptPrinterAdapter? localPrintAgentAdapter,
  })  : _loadConfiguration = loadConfiguration,
        _generator = generator,
        _usbAdapter = usbAdapter ?? UsbReceiptPrinterAdapter(),
        _bluetoothAdapter =
            bluetoothAdapter ?? BluetoothReceiptPrinterAdapter(),
        _networkAdapter = networkAdapter ?? NetworkReceiptPrinterAdapter(),
        _localPrintAgentAdapter = localPrintAgentAdapter ??
            LocalPrintAgentAdapter(LocalPrintAgentClient());

  final PosPrinterConfigLoader _loadConfiguration;
  final EscPosReceiptGenerator _generator;
  final ReceiptPrinterAdapter _usbAdapter;
  final ReceiptPrinterAdapter _bluetoothAdapter;
  final ReceiptPrinterAdapter _networkAdapter;
  final ReceiptPrinterAdapter _localPrintAgentAdapter;

  Future<PosDevicePrinterConfig?> loadConfiguration(String deviceId) {
    return _loadConfiguration(deviceId);
  }

  ReceiptPrinterAdapter selectAdapter(PosDevicePrinterConfig config) {
    switch (config.connectionType) {
      case PrinterConnectionType.usb:
        return _usbAdapter;
      case PrinterConnectionType.bluetooth:
        return _bluetoothAdapter;
      case PrinterConnectionType.network:
        return _networkAdapter;
      case PrinterConnectionType.localPrintAgent:
        return _localPrintAgentAdapter;
    }
  }

  Future<CompletedSalePrintResult> printCompletionReceipt({
    required String deviceId,
    required ReturnReceipt receipt,
    required String printRequestId,
    String copyType = 'CUSTOMER',
    int copyIndex = 1,
    bool isReprint = false,
  }) async {
    final config = await loadConfiguration(deviceId);
    if (config == null || !config.enabled) {
      throw const PrinterNotConfiguredException();
    }
    if (config.deviceId.trim().isNotEmpty &&
        config.deviceId.trim() != deviceId.trim()) {
      throw const PrinterNotConfiguredException(
        'Printer configuration does not belong to the current POS device.',
      );
    }
    final adapter = selectAdapter(config);
    final receiptType = receipt.receiptType?.trim().toUpperCase();
    final purpose = receipt.isExchange
        ? 'exchange'
        : receiptType == 'RETURN'
            ? 'return'
            : 'refund';
    final routingPurpose = switch (purpose) {
      'exchange' => 'exchangeReceipt',
      'return' => 'returnReceipt',
      _ => 'refundReceipt',
    };
    if (!config.supportedPurposes.contains(routingPurpose)) {
      throw const PrinterUnsupportedException(
        'The configured printer is not assigned for this receipt purpose.',
      );
    }
    // Only one transport runs per print action.
    try {
      await adapter.connect(config);
      await adapter.checkStatus(config);
      if (config.connectionType == PrinterConnectionType.localPrintAgent) {
        if (adapter is! StructuredReceiptPrinterAdapter) {
          throw const PrinterUnsupportedException(
            'The selected Local Print Agent adapter does not support structured receipts.',
          );
        }
        final result = await (adapter as StructuredReceiptPrinterAdapter)
            .printStructuredReceipt(
          config,
          _returnAgentRequest(
            receipt,
            printRequestId,
            purpose: purpose,
            copyType: copyType,
            copyIndex: copyIndex,
            config: config,
            isReprint: isReprint,
          ),
        );
        return CompletedSalePrintResult(
          transport: config.connectionType.name,
          printerName: result.printerName,
          agentResult: result.code,
          printerConfigurationId: config.configurationId,
          printerConfigurationVersion: config.configurationVersion,
          routingPurpose: routingPurpose,
        );
      }
      final bytes = _generator.generate(receipt: receipt, config: config);
      await adapter.printBytes(config, bytes);
      return CompletedSalePrintResult(
        transport: config.connectionType.name,
        printerName: config.displayName,
        agentResult: 'transport_completed',
        printerConfigurationId: config.configurationId,
        printerConfigurationVersion: config.configurationVersion,
        routingPurpose: routingPurpose,
      );
    } finally {
      await adapter.disconnect();
    }
  }

  LocalPrintAgentReceiptRequest _returnAgentRequest(
    ReturnReceipt receipt,
    String requestId, {
    required String purpose,
    required String copyType,
    required int copyIndex,
    required PosDevicePrinterConfig config,
    required bool isReprint,
  }) {
    final merchantName = receipt.outletName?.trim() ?? '';
    if (merchantName.isEmpty) {
      throw const PrinterConfigurationException(
        'The authoritative receipt does not include an outlet or merchant name.',
      );
    }
    final returned = receipt.returnedItems.map(
      (line) => LocalPrintAgentReceiptLine(
        name: line.variantLabel.trim().isEmpty
            ? line.name
            : '${line.name} (${line.variantLabel})',
        quantity: line.quantity,
        unitPrice: line.unitPrice,
        lineTotal: line.total ?? line.lineAmount,
        saleLineId: line.saleLineId,
        itemGroup: 'Returned items',
        discountAmount: line.discount,
        taxAmount: line.tax,
        reason: line.reasonDisplay,
      ),
    );
    final replacements = receipt.replacementItems.map(
      (line) => LocalPrintAgentReceiptLine(
        name: line.variantLabel.trim().isEmpty
            ? line.name
            : '${line.name} (${line.variantLabel})',
        quantity: line.quantity,
        unitPrice: line.unitPrice,
        lineTotal: line.total ?? line.lineAmount,
        saleLineId: line.saleLineId,
        itemGroup: 'Replacement items',
        discountAmount: line.discount,
        taxAmount: line.tax,
      ),
    );
    final items = [...returned, ...replacements];
    final subtotal = receipt.isExchange
        ? (receipt.replacementSubtotal ??
            receipt.replacementItemValue ??
            receipt.replacementItems.fold<num>(
              0,
              (sum, line) => sum + (line.subtotal ?? line.lineAmount),
            ))
        : (receipt.returnSubtotal ??
            receipt.returnItemValue ??
            receipt.returnedItems.fold<num>(
              0,
              (sum, line) => sum + (line.subtotal ?? line.lineAmount),
            ));
    final discount = receipt.isExchange
        ? (receipt.replacementDiscount ?? 0)
        : (receipt.returnDiscount ?? 0);
    final tax = receipt.isExchange
        ? (receipt.replacementTax ?? 0)
        : (receipt.returnTax ?? 0);
    final total = receipt.isExchange
        ? (receipt.replacementTotal ??
            receipt.replacementItemValue ??
            receipt.differenceAmount ??
            0)
        : (receipt.returnTotal ?? receipt.refundAmount);

    final settlements = <LocalPrintAgentSettlementLine>[
      if ((receipt.amountPaidByCustomer ?? 0) > 0)
        LocalPrintAgentSettlementLine(
          label: 'Customer paid',
          amount: receipt.amountPaidByCustomer!,
          currency: receipt.currency,
          method: receipt.settlementMethodLabel,
          safeReference: receipt.providerTransactionReference,
        ),
      if ((receipt.amountRefundedToCustomer ?? receipt.refundAmount) > 0)
        LocalPrintAgentSettlementLine(
          label: 'Refunded',
          amount: receipt.amountRefundedToCustomer ?? receipt.refundAmount,
          currency: receipt.currency,
          method: receipt.settlementMethodLabel,
          safeReference: receipt.providerTransactionReference,
        ),
      if (receipt.isExchange && receipt.differenceAmount != null)
        LocalPrintAgentSettlementLine(
          label: 'Price difference',
          amount: receipt.differenceAmount!,
          currency: receipt.currency,
          method: receipt.settlementMethodLabel,
        ),
    ];

    return LocalPrintAgentReceiptRequest(
      requestId: requestId,
      receiptId: receipt.receiptId,
      receiptNumber: receipt.receiptNumber,
      receiptPurpose: purpose,
      printedAt: receipt.completedAt ?? DateTime.now().toUtc(),
      merchantName: merchantName,
      outletName: receipt.outletName,
      tillName: receipt.tillName,
      cashierName: receipt.processedByName ?? receipt.cashierName,
      currency: receipt.currency,
      items: items,
      subtotal: subtotal,
      discountTotal: discount,
      taxTotal: tax,
      total: total,
      paymentMethod: receipt.settlementMethodLabel,
      barcodeValue: receipt.receiptNumber,
      originalReceiptReference: receipt.originalInvoiceNo,
      referenceLines: [
        if (receipt.returnNumber?.trim().isNotEmpty == true)
          LocalPrintAgentReferenceLine(
            label: 'Return',
            value: receipt.returnNumber!,
          ),
        if (receipt.exchangeNumber?.trim().isNotEmpty == true)
          LocalPrintAgentReferenceLine(
            label: 'Exchange',
            value: receipt.exchangeNumber!,
          ),
      ],
      settlementLines: settlements,
      footerLines: const ['Thank you'],
      copyType: copyType,
      copyIndex: copyIndex,
      isReprint: isReprint,
      printerConfigurationId: config.configurationId,
      printerConfigurationVersion: config.configurationVersion,
    );
  }

  Future<CompletedSalePrintResult> printCompletedSale({
    required CompletedSaleReceipt receipt,
    required String printRequestId,
  }) async {
    final config = await loadConfiguration(receipt.deviceId);
    if (config == null || !config.enabled) {
      throw const PrinterNotConfiguredException();
    }
    if (config.deviceId.trim().isNotEmpty &&
        config.deviceId.trim() != receipt.deviceId.trim()) {
      throw const PrinterNotConfiguredException(
        'Printer configuration does not belong to the current POS device.',
      );
    }

    final adapter = selectAdapter(config);
    developer.log(
      'saleId=${receipt.saleId} receiptId=${receipt.receiptId} '
      'printRequestId=$printRequestId '
      'connectionType=${config.connectionType.name} '
      'adapter=${adapter.runtimeType} '
      'agentBaseUrl=${config.connectionType == PrinterConnectionType.localPrintAgent ? config.agentBaseUrl : 'n/a'}',
      name: 'pos.receipt.print',
    );
    try {
      await adapter.connect(config);
      await adapter.checkStatus(config);
      if (config.connectionType == PrinterConnectionType.localPrintAgent) {
        if (adapter is! StructuredReceiptPrinterAdapter) {
          throw const PrinterUnsupportedException(
            'The selected Local Print Agent adapter does not support structured receipts.',
          );
        }
        final structuredAdapter = adapter as StructuredReceiptPrinterAdapter;
        final result = await structuredAdapter.printStructuredReceipt(
          config,
          _agentRequest(receipt, printRequestId, config),
        );
        developer.log(
          'saleId=${receipt.saleId} printRequestId=$printRequestId '
          'result=${result.code}',
          name: 'pos.receipt.print',
        );
        return CompletedSalePrintResult(
          transport: config.connectionType.name,
          printerName: result.printerName,
          agentResult: result.code,
          printerConfigurationId: config.configurationId,
          printerConfigurationVersion: config.configurationVersion,
          routingPurpose: receipt.copyType == 'MERCHANT'
              ? 'merchantReceipt'
              : 'customerReceipt',
        );
      }

      await adapter.printBytes(
        config,
        _generator.generateCompletedSale(receipt: receipt, config: config),
      );
      return CompletedSalePrintResult(
        transport: config.connectionType.name,
        printerName: config.displayName,
        agentResult: 'transport_completed',
        printerConfigurationId: config.configurationId,
        printerConfigurationVersion: config.configurationVersion,
        routingPurpose: receipt.copyType == 'MERCHANT'
            ? 'merchantReceipt'
            : 'customerReceipt',
      );
    } finally {
      await adapter.disconnect();
    }
  }

  Future<LocalPrintAgentOperationStatus?> lookupLocalAgentOperation({
    required String deviceId,
    required String printRequestId,
  }) async {
    final config = await loadConfiguration(deviceId);
    if (config == null ||
        !config.enabled ||
        config.connectionType != PrinterConnectionType.localPrintAgent) {
      return null;
    }
    return LocalPrintAgentClient().operationStatus(config, printRequestId);
  }

  LocalPrintAgentReceiptRequest _agentRequest(
    CompletedSaleReceipt receipt,
    String requestId,
    PosDevicePrinterConfig config,
  ) {
    return LocalPrintAgentReceiptRequest(
      requestId: requestId,
      receiptNumber: receipt.receiptNumber,
      printedAt: receipt.completedAt,
      merchantName: receipt.merchantName,
      outletName: receipt.outletName,
      tillName: receipt.tillName,
      cashierName: receipt.cashierName,
      currency: receipt.currency,
      items: receipt.items
          .map(
            (line) => LocalPrintAgentReceiptLine(
              name: line.variantOrSku?.trim().isNotEmpty == true
                  ? '${line.name} (${line.variantOrSku})'
                  : line.name,
              quantity: line.quantity,
              unitPrice: line.unitPrice,
              lineTotal: line.lineTotal,
              saleLineId: line.saleLineId,
            ),
          )
          .toList(growable: false),
      subtotal: receipt.subtotal,
      discountTotal: receipt.discountTotal,
      taxTotal: receipt.taxTotal,
      total: receipt.total,
      paymentMethod: receipt.paymentSummary,
      amountTendered: receipt.amountTendered,
      change: receipt.change,
      barcodeValue: receipt.barcodeValue,
      footerLines: receipt.footerLines,
      tenders: receipt.tenders
          .map(
            (line) => LocalPrintAgentTenderLine(
              methodCode: line.methodCode,
              methodName: line.methodName,
              methodType: line.methodType,
              amount: line.amount,
              amountTendered: line.amountTendered,
              changeAmount: line.changeAmount,
              currency: line.currency,
              status: line.status,
              providerName: line.providerName,
              cardBrand: line.cardBrand,
              maskedCardLast4: line.maskedCardLast4,
              authorizationReference: line.authorizationReference,
              terminalReference: line.terminalReference,
            ),
          )
          .toList(growable: false),
      discountLines: receipt.discountLines
          .map(
            (line) => LocalPrintAgentDiscountLine(
              scope: line.scope,
              saleLineId: line.saleLineId,
              name: line.name,
              code: line.code,
              promotionReference: line.promotionReference,
              amount: line.amount,
            ),
          )
          .toList(growable: false),
      taxLines: receipt.taxLines
          .map(
            (line) => LocalPrintAgentTaxLine(
              taxCode: line.taxCode,
              taxName: line.taxName,
              rate: line.rate,
              taxableAmount: line.taxableAmount,
              taxAmount: line.taxAmount,
            ),
          )
          .toList(growable: false),
      taxRegistrationNumber: receipt.taxRegistrationNumber,
      taxInvoiceLabel: receipt.taxInvoiceLabel,
      isReprint: receipt.isReprint,
      copyType: receipt.copyType,
      copyIndex: receipt.copyIndex,
      receiptPurpose: receipt.isReprint ? 'saleReprint' : 'saleOriginal',
      receiptId: receipt.receiptId,
      printerConfigurationId: config.configurationId,
      printerConfigurationVersion: config.configurationVersion,
    );
  }
}

class CompletedSalePrintResult {
  const CompletedSalePrintResult({
    required this.transport,
    required this.printerName,
    required this.agentResult,
    this.printerConfigurationId,
    this.printerConfigurationVersion,
    this.routingPurpose,
  });

  final String transport;
  final String printerName;
  final String agentResult;
  final String? printerConfigurationId;
  final int? printerConfigurationVersion;
  final String? routingPurpose;
}
final posReceiptPrinterServiceProvider =
    Provider<PosReceiptPrinterService>((ref) {
  final store = ref.watch(posDevicePrinterConfigStoreProvider);
  return PosReceiptPrinterService(
    loadConfiguration: store.load,
  );
});
