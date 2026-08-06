import '../../returns_refunds/domain/entities/return_receipt.dart';
import 'models/local_print_agent_models.dart';
import 'models/pos_device_printer_config.dart';
import 'models/printer_exception.dart';
import 'pos_receipt_printer_service.dart';
import 'receipt_print_identity.dart';

typedef ReceiptPrintAuditSubmitter = Future<void> Function(
  String saleId,
  Map<String, dynamic> audit,
);

enum ReceiptCopyOutcomeStatus {
  printed,
  failed,
  unknown,
  auditPending,
}

class ReceiptCopyOutcome {
  const ReceiptCopyOutcome({
    required this.copyType,
    required this.copyIndex,
    required this.printRequestId,
    required this.status,
    this.message,
    this.pendingAudit,
  });

  final String copyType;
  final int copyIndex;
  final String printRequestId;
  final ReceiptCopyOutcomeStatus status;
  final String? message;
  final Map<String, dynamic>? pendingAudit;
}

class ReceiptPrintBatchResult {
  const ReceiptPrintBatchResult(this.outcomes);

  final List<ReceiptCopyOutcome> outcomes;

  bool get hasUnknown =>
      outcomes.any((item) => item.status == ReceiptCopyOutcomeStatus.unknown);
  bool get hasFailures =>
      outcomes.any((item) => item.status == ReceiptCopyOutcomeStatus.failed);
  bool get hasAuditPending => outcomes
      .any((item) => item.status == ReceiptCopyOutcomeStatus.auditPending);
  bool get allPrinted =>
      outcomes.isNotEmpty &&
      outcomes.every((item) =>
          item.status == ReceiptCopyOutcomeStatus.printed ||
          item.status == ReceiptCopyOutcomeStatus.auditPending);
}

class NonSaleReceiptPrintOrchestrator {
  const NonSaleReceiptPrintOrchestrator({
    required PosReceiptPrinterService printer,
    required ReceiptPrintAuditSubmitter submitAudit,
  })  : _printer = printer,
        _submitAudit = submitAudit;

  final PosReceiptPrinterService _printer;
  final ReceiptPrintAuditSubmitter _submitAudit;

  Future<ReceiptPrintBatchResult> print({
    required String deviceId,
    required ReturnReceipt receipt,
    required bool isReprint,
    String? reprintOperationId,
    String? reprintReasonCode,
    String? reprintReasonNote,
  }) async {
    final saleId = receipt.originalSaleId?.trim() ?? '';
    final receiptId = receipt.receiptId?.trim() ?? '';
    if (saleId.isEmpty || receiptId.isEmpty) {
      throw const PrinterConfigurationException(
        'The authoritative receipt identity is unavailable.',
      );
    }
    if (isReprint && (reprintOperationId?.trim().isEmpty ?? true)) {
      throw const PrinterConfigurationException(
        'An authorized reprint operation is required.',
      );
    }

    final config = await _printer.loadConfiguration(deviceId);
    if (config == null || !config.enabled) {
      throw const PrinterNotConfiguredException();
    }
    final copies = intendedCopies(config);
    if (copies.isEmpty) {
      throw const PrinterConfigurationException(
        'No receipt copies are enabled for this POS device.',
      );
    }

    final purpose = receiptPurpose(receipt);
    final identityOperation =
        isReprint ? reprintOperationId!.trim() : receiptId;
    final outcomes = <ReceiptCopyOutcome>[];
    for (final copy in copies) {
      final requestId = ReceiptPrintIdentity.forCopy(
        operationId: identityOperation,
        receiptPurpose: isReprint ? '${purpose}Reprint' : purpose,
        copyType: copy.$1,
        copyIndex: copy.$2,
      );
      CompletedSalePrintResult? printResult;
      Object? printFailure;
      var unknown = false;
      try {
        printResult = await _printer.printCompletionReceipt(
          deviceId: deviceId,
          receipt: receipt,
          printRequestId: requestId,
          copyType: copy.$1,
          copyIndex: copy.$2,
          isReprint: isReprint,
        );
      } catch (error) {
        printFailure = error;
        unknown = error is LocalPrintAgentException &&
            (error.type == LocalPrintAgentFailureType.timeout ||
                error.type == LocalPrintAgentFailureType.unknown);
      }

      final audit = _audit(
        deviceId: deviceId,
        receipt: receipt,
        purpose: purpose,
        copyType: copy.$1,
        copyIndex: copy.$2,
        requestId: requestId,
        result: printResult,
        failure: printFailure,
        unknown: unknown,
        isReprint: isReprint,
        reprintOperationId: reprintOperationId,
        reprintReasonCode: reprintReasonCode,
        reprintReasonNote: reprintReasonNote,
      );
      try {
        await _submitAudit(saleId, audit);
      } catch (_) {
        outcomes.add(ReceiptCopyOutcome(
          copyType: copy.$1,
          copyIndex: copy.$2,
          printRequestId: requestId,
          status: ReceiptCopyOutcomeStatus.auditPending,
          message: printResult == null
              ? safePrintMessage(printFailure)
              : 'Receipt printed, but its audit is pending.',
          pendingAudit: audit,
        ));
        continue;
      }

      outcomes.add(ReceiptCopyOutcome(
        copyType: copy.$1,
        copyIndex: copy.$2,
        printRequestId: requestId,
        status: unknown
            ? ReceiptCopyOutcomeStatus.unknown
            : printResult == null
                ? ReceiptCopyOutcomeStatus.failed
                : ReceiptCopyOutcomeStatus.printed,
        message: printResult == null ? safePrintMessage(printFailure) : null,
      ));
    }
    return ReceiptPrintBatchResult(outcomes);
  }

  static List<(String, int)> intendedCopies(PosDevicePrinterConfig config) {
    final copies = <(String, int)>[];
    if (config.printCustomerCopy) {
      for (var index = 1;
          index <= config.customerCopyCount.clamp(0, 5);
          index++) {
        copies.add(('CUSTOMER', index));
      }
    }
    if (config.printMerchantCopy) {
      for (var index = 1;
          index <= config.merchantCopyCount.clamp(0, 5);
          index++) {
        copies.add(('MERCHANT', index));
      }
    }
    return copies;
  }

  static String receiptPurpose(ReturnReceipt receipt) {
    if (receipt.isExchange) return 'exchange';
    return receipt.receiptType?.trim().toUpperCase() == 'RETURN'
        ? 'return'
        : 'refund';
  }

  static String safePrintMessage(Object? error) {
    if (error is LocalPrintAgentException) return error.message;
    if (error is PrinterException) return error.message;
    return 'Receipt printing failed.';
  }

  static Map<String, dynamic> _audit({
    required String deviceId,
    required ReturnReceipt receipt,
    required String purpose,
    required String copyType,
    required int copyIndex,
    required String requestId,
    required CompletedSalePrintResult? result,
    required Object? failure,
    required bool unknown,
    required bool isReprint,
    required String? reprintOperationId,
    required String? reprintReasonCode,
    required String? reprintReasonNote,
  }) {
    return <String, dynamic>{
      'status': result == null ? 'failed' : 'success',
      'copies': 1,
      'receiptId': receipt.receiptId,
      'receiptPurpose': purpose,
      'copyType': copyType,
      'copyIndex': copyIndex,
      'deviceId': deviceId,
      'tillId': receipt.tillId,
      'cashierUserId': receipt.processedByUserId,
      'printerTransport': result?.transport ?? 'localPrintAgent',
      'configuredPrinterName': result?.printerName,
      'printRequestId': requestId,
      'requestedAt': DateTime.now().toUtc().toIso8601String(),
      'agentResult': result?.agentResult,
      'failureCategory': failureCategory(failure),
      'printerConfigurationId': result?.printerConfigurationId,
      'printerConfigurationVersion': result?.printerConfigurationVersion,
      'routingPurpose': result?.routingPurpose ??
          switch (purpose) {
            'exchange' => 'exchangeReceipt',
            'return' => 'returnReceipt',
            _ => 'refundReceipt',
          },
      'isRetry': false,
      'isReprint': isReprint,
      'clientCorrelationId': requestId,
      'reprintOperationId': reprintOperationId,
      'reprintReasonCode': reprintReasonCode,
      'reprintReasonNote': reprintReasonNote,
      'unknownOutcome': unknown,
    };
  }

  static String? failureCategory(Object? error) {
    if (error is LocalPrintAgentException) return error.type.name;
    if (error is PrinterException) return error.code;
    return error == null ? null : 'unknown';
  }
}
