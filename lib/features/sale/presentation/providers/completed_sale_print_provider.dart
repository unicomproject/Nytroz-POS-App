import 'dart:math';
import 'dart:developer' as developer;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../hardware/receipt_printer/models/completed_sale_receipt.dart';
import '../../../hardware/receipt_printer/models/local_print_agent_models.dart';
import '../../../hardware/receipt_printer/models/printer_exception.dart';
import '../../../hardware/receipt_printer/pos_receipt_printer_service.dart';
import '../../../hardware/receipt_printer/recovery/print_operation.dart';
import '../../../hardware/receipt_printer/recovery/print_operation_store.dart';
import '../../../hardware/receipt_printer/receipt_print_identity.dart';
import 'pos_checkout_summary_provider.dart';

typedef CompletedSaleAuditSubmitter = Future<void> Function(
  String saleId,
  Map<String, dynamic> audit,
);

enum CompletedSalePrintStatus {
  idle,
  printing,
  printed,
  notConfigured,
  unavailable,
  authenticationFailed,
  failed,
  unknownOutcome,
}

class CompletedSalePrintState {
  const CompletedSalePrintState({
    this.status = CompletedSalePrintStatus.idle,
    this.saleId,
    this.receipt,
    this.printRequestId,
    this.message,
    this.auditPending = false,
    this.auditMessage,
  });

  final CompletedSalePrintStatus status;
  final String? saleId;
  final CompletedSaleReceipt? receipt;
  final String? printRequestId;
  final String? message;
  final bool auditPending;
  final String? auditMessage;

  bool get canRetryPrint =>
      status == CompletedSalePrintStatus.notConfigured ||
      status == CompletedSalePrintStatus.unavailable ||
      status == CompletedSalePrintStatus.authenticationFailed ||
      status == CompletedSalePrintStatus.failed;

  CompletedSalePrintState copyWith({
    CompletedSalePrintStatus? status,
    String? saleId,
    CompletedSaleReceipt? receipt,
    String? printRequestId,
    String? message,
    bool? auditPending,
    String? auditMessage,
  }) {
    return CompletedSalePrintState(
      status: status ?? this.status,
      saleId: saleId ?? this.saleId,
      receipt: receipt ?? this.receipt,
      printRequestId: printRequestId ?? this.printRequestId,
      message: message ?? this.message,
      auditPending: auditPending ?? this.auditPending,
      auditMessage: auditMessage ?? this.auditMessage,
    );
  }
}

class CompletedSalePrintController
    extends StateNotifier<CompletedSalePrintState> {
  CompletedSalePrintController(this._printer, this._submitAudit, [this._store])
      : super(const CompletedSalePrintState()) {
    _initialize();
  }

  final PosReceiptPrinterService _printer;
  final CompletedSaleAuditSubmitter _submitAudit;
  final PrintOperationStore? _store;
  final Set<String> _automaticOperations = {};
  Map<String, dynamic>? _pendingAudit;
  int _auditSubmissionCount = 0;
  bool _recovering = false;

  Future<void> printAutomatically(CompletedSaleReceipt receipt) async {
    if (!_automaticOperations.add(receipt.saleId)) {
      developer.log(
        'Duplicate automatic trigger ignored. saleId=${receipt.saleId}',
        name: 'pos.receipt.print',
      );
      return;
    }
    final existing = (await _store?.load() ?? const <PrintOperation>[]).where(
      (operation) =>
          operation.receipt.saleId == receipt.saleId &&
          operation.state != PrintOperationState.cancelled,
    );
    if (existing.isNotEmpty) {
      developer.log(
        'Durable duplicate trigger ignored. saleId=${receipt.saleId} '
        'state=${existing.first.state.name}',
        name: 'pos.receipt.recovery',
      );
      return;
    }
    for (final copy in _intendedCopies(receipt)) {
      final copyReceipt = receipt.forCopy(
        copyType: copy.$1,
        copyIndex: copy.$2,
      );
      await _print(
        copyReceipt,
        requestId:
            _copyRequestId(receipt.receiptId, copy.$1, copy.$2, 'ORIGINAL'),
        isRetry: false,
      );
      if (state.status != CompletedSalePrintStatus.printed ||
          state.auditPending) {
        break;
      }
    }
  }

  Future<void> retryPrint() async {
    final receipt = state.receipt;
    if (receipt == null || !state.canRetryPrint) return;
    await _print(receipt, requestId: _newRequestId(), isRetry: true);
  }

  Future<void> printAuthorizedReprint({
    required CompletedSaleReceipt receipt,
    required String reprintOperationId,
    required String reasonCode,
    String? reasonNote,
  }) async {
    final existing = (await _store?.load() ?? const <PrintOperation>[]).where(
      (operation) => operation.printRequestId == reprintOperationId,
    );
    if (existing.isNotEmpty) {
      await _initialize();
      return;
    }
    await _print(
      receipt,
      requestId: reprintOperationId,
      isRetry: false,
      isReprint: true,
      reprintOperationId: reprintOperationId,
      reprintReasonCode: reasonCode,
      reprintReasonNote: reasonNote,
    );
  }

  Future<void> retryAuditOnly() async {
    final audit = _pendingAudit;
    final saleId = state.saleId;
    if (audit == null || saleId == null || !state.auditPending) return;
    try {
      await _submitAuditOnce(saleId, audit);
      _pendingAudit = null;
      state = state.copyWith(auditPending: false, auditMessage: '');
    } catch (_) {
      state = state.copyWith(
        auditPending: true,
        auditMessage: 'Print status audit is still pending.',
      );
    }
  }

  Future<void> recoverPendingOperations() => _initialize();

  Future<void> confirmPrinted(PrintOperation operation) async {
    // This is an audit-only resolution of an ambiguous physical attempt. It
    // must have its own idempotency identity; reusing the original request ID
    // would return the already-recorded UNKNOWN row and lose the resolution.
    final audit = _successAudit(operation, _newRequestId());
    await _recoverAudit(operation.copyWith(
      state: PrintOperationState.pendingAudit,
      audit: audit,
    ));
  }

  Future<void> confirmNotPrinted(PrintOperation operation) async {
    await _persist(operation.copyWith(
      state: PrintOperationState.cancelled,
      failureCategory: 'operator_confirmed_not_printed',
      failureMessage:
          'Operator confirmed no receipt printed. Use Receipt History for a controlled reprint.',
    ));
  }

  Future<void> _initialize() async {
    if (_recovering) return;
    _recovering = true;
    try {
      final operations = await _store?.load() ?? const <PrintOperation>[];
      for (final operation in operations) {
        if (operation.state == PrintOperationState.pendingPrint) {
          await _print(
            operation.receipt,
            requestId: operation.printRequestId,
            isRetry: false,
            durableOperation: operation,
          );
        } else if (operation.state == PrintOperationState.printing) {
          await _reconcileInterrupted(operation);
        } else if (operation.state == PrintOperationState.pendingAudit ||
            operation.state == PrintOperationState.auditFailed ||
            operation.state == PrintOperationState.auditing) {
          await _recoverAudit(operation);
        } else if (operation.state == PrintOperationState.printOutcomeUnknown ||
            operation.state == PrintOperationState.requiresOperatorDecision) {
          _showUnknown(operation);
        }
      }
    } finally {
      _recovering = false;
    }
  }

  Future<void> _print(
    CompletedSaleReceipt receipt, {
    required String requestId,
    required bool isRetry,
    bool isReprint = false,
    String? reprintOperationId,
    String? reprintReasonCode,
    String? reprintReasonNote,
    PrintOperation? durableOperation,
  }) async {
    var operation = durableOperation ??
        PrintOperation(
          operationId: _newRequestId(),
          receipt: receipt,
          printRequestId: requestId,
          operatorUserId: receipt.cashierId,
          deviceId: receipt.deviceId,
          createdAt: DateTime.now().toUtc(),
          updatedAt: DateTime.now().toUtc(),
          state: PrintOperationState.pendingPrint,
        );
    await _persist(operation);
    operation = operation.copyWith(
      state: PrintOperationState.printing,
      physicalAttemptCount: operation.physicalAttemptCount + 1,
    );
    await _persist(operation);

    state = CompletedSalePrintState(
      status: CompletedSalePrintStatus.printing,
      saleId: receipt.saleId,
      receipt: receipt,
      printRequestId: requestId,
      message: 'Sale completed, printing receipt',
    );

    CompletedSalePrintResult? result;
    Object? failure;
    try {
      result = await _printer.printCompletedSale(
        receipt: receipt,
        printRequestId: requestId,
      );
      state = state.copyWith(
        status: CompletedSalePrintStatus.printed,
        message: 'Sale completed, receipt printed',
      );
    } catch (error) {
      failure = error;
      operation = operation.copyWith(
        state: _durableFailureState(error),
        failureCategory: _safeFailureCategory(error),
        failureMessage: _messageFor(error),
      );
      await _persist(operation);
      state = state.copyWith(
        status: _statusFor(error),
        message: _messageFor(error),
      );
    }

    developer.log(
      'saleId=${receipt.saleId} receiptId=${receipt.receiptId} '
      'printRequestId=$requestId result=${result == null ? _safeFailureCategory(failure) : 'success'}',
      name: 'pos.receipt.print',
    );

    final audit = <String, dynamic>{
      'status': result == null ? 'failed' : 'success',
      'copies': 1,
      'deviceId': receipt.deviceId,
      'tillId': receipt.tillId,
      'cashierUserId': receipt.cashierId,
      'printerTransport': result?.transport ?? 'unknown',
      'configuredPrinterName': result?.printerName,
      'printRequestId': requestId,
      'requestedAt': DateTime.now().toUtc().toIso8601String(),
      'agentResult': result?.agentResult,
      'failureCategory': _safeFailureCategory(failure),
      'isRetry': isRetry,
      'isReprint': isReprint,
      'clientCorrelationId': requestId,
      'reprintOperationId': reprintOperationId,
      'reprintReasonCode': reprintReasonCode,
      'reprintReasonNote': reprintReasonNote,
      'copyType': receipt.copyType,
      'copyIndex': receipt.copyIndex,
      'receiptId': receipt.receiptId,
      'receiptPurpose': isReprint ? 'saleReprint' : 'saleOriginal',
      'printerConfigurationId': result?.printerConfigurationId,
      'printerConfigurationVersion': result?.printerConfigurationVersion,
      'routingPurpose': result?.routingPurpose,
      'unknownOutcome':
          operation.state == PrintOperationState.printOutcomeUnknown,
    };

    if (result == null &&
        operation.state == PrintOperationState.printOutcomeUnknown) {
      operation = operation.copyWith(audit: audit);
      await _persist(operation);
      try {
        operation = operation.copyWith(
          state: PrintOperationState.auditing,
          auditAttemptCount: operation.auditAttemptCount + 1,
        );
        await _persist(operation);
        _auditSubmissionCount++;
        await _submitAudit(receipt.saleId, audit);
        operation = operation.copyWith(
          state: PrintOperationState.requiresOperatorDecision,
        );
        await _persist(operation);
      } catch (error) {
        operation = operation.copyWith(
          state: PrintOperationState.requiresOperatorDecision,
          failureMessage:
              'Print outcome is unknown and its audit is pending: ${_safeMessage(error)}',
        );
        await _persist(operation);
      }
      _showUnknown(operation);
      return;
    }

    operation = operation.copyWith(
      state: PrintOperationState.pendingAudit,
      audit: audit,
    );
    await _persist(operation);
    try {
      operation = operation.copyWith(
        state: PrintOperationState.auditing,
        auditAttemptCount: operation.auditAttemptCount + 1,
      );
      await _persist(operation);
      await _submitAuditOnce(receipt.saleId, audit);
      await _persist(operation.copyWith(
        state: result == null
            ? PrintOperationState.printFailedConfirmed
            : PrintOperationState.completed,
      ));
    } catch (_) {
      _pendingAudit = audit;
      await _persist(operation.copyWith(
        state: PrintOperationState.auditFailed,
      ));
      state = state.copyWith(
        auditPending: true,
        auditMessage: 'Print status audit pending. Receipt will not reprint.',
      );
    }
  }

  Future<void> _recoverAudit(PrintOperation operation) async {
    final audit = operation.audit;
    if (audit == null) {
      await _persist(operation.copyWith(
        state: PrintOperationState.requiresOperatorDecision,
        failureCategory: 'missing_audit_payload',
      ));
      return;
    }
    try {
      final auditing = operation.copyWith(
        state: PrintOperationState.auditing,
        auditAttemptCount: operation.auditAttemptCount + 1,
      );
      await _persist(auditing);
      await _submitAuditOnce(operation.receipt.saleId, audit);
      await _persist(auditing.copyWith(
        state: audit['status'] == 'success'
            ? PrintOperationState.completed
            : PrintOperationState.printFailedConfirmed,
      ));
    } catch (_) {
      await _persist(operation.copyWith(
        state: PrintOperationState.auditFailed,
      ));
      _pendingAudit = audit;
      state = CompletedSalePrintState(
        status: CompletedSalePrintStatus.printed,
        saleId: operation.receipt.saleId,
        receipt: operation.receipt,
        printRequestId: operation.printRequestId,
        auditPending: true,
        auditMessage: 'Print status audit pending. Receipt will not reprint.',
      );
    }
  }

  Future<void> _reconcileInterrupted(PrintOperation operation) async {
    try {
      final agentStatus = await _printer.lookupLocalAgentOperation(
        deviceId: operation.deviceId,
        printRequestId: operation.printRequestId,
      );
      if (agentStatus?.completedSuccessfully == true) {
        final audit = <String, dynamic>{
          'status': 'success',
          'copies': 1,
          'deviceId': operation.receipt.deviceId,
          'tillId': operation.receipt.tillId,
          'cashierUserId': operation.receipt.cashierId,
          'printerTransport': 'localPrintAgent',
          'printRequestId': operation.printRequestId,
          'requestedAt': operation.createdAt.toIso8601String(),
          'agentResult': agentStatus!.resultCode,
          'isRetry': false,
          'isReprint': false,
          'clientCorrelationId': operation.printRequestId,
          'copyType': operation.receipt.copyType,
          'copyIndex': operation.receipt.copyIndex,
        };
        await _recoverAudit(operation.copyWith(
          state: PrintOperationState.pendingAudit,
          audit: audit,
        ));
        return;
      }
    } catch (error) {
      developer.log(
        'Operation reconciliation failed requestId=${operation.printRequestId} '
        'category=${_safeFailureCategory(error)}',
        name: 'pos.receipt.recovery',
      );
    }
    final unknown = operation.copyWith(
      state: PrintOperationState.printOutcomeUnknown,
      failureCategory: 'process_interrupted',
      failureMessage:
          'The app stopped while printing. Verify the agent operation before retrying.',
    );
    await _persist(unknown);
    _showUnknown(unknown);
  }

  Map<String, dynamic> _successAudit(
    PrintOperation operation,
    String resolutionRequestId,
  ) =>
      {
        'status': 'success',
        'copies': 1,
        'deviceId': operation.receipt.deviceId,
        'tillId': operation.receipt.tillId,
        'cashierUserId': operation.receipt.cashierId,
        'printerTransport': 'operatorConfirmed',
        'printRequestId': resolutionRequestId,
        'requestedAt': DateTime.now().toUtc().toIso8601String(),
        'agentResult': 'operator_confirmed_printed',
        'isRetry': false,
        'isReprint': false,
        'clientCorrelationId': resolutionRequestId,
        'copyType': operation.receipt.copyType,
        'copyIndex': operation.receipt.copyIndex,
        'receiptId': operation.receipt.receiptId,
        'receiptPurpose': 'saleOriginal',
        'routingPurpose': 'saleOriginal',
        'unknownOutcome': false,
        'recoveryPrintRequestId': operation.printRequestId,
      };

  void _showUnknown(PrintOperation operation) {
    state = CompletedSalePrintState(
      status: CompletedSalePrintStatus.unknownOutcome,
      saleId: operation.receipt.saleId,
      receipt: operation.receipt,
      printRequestId: operation.printRequestId,
      message:
          'Print outcome is unknown. Verify the printer or agent operation before retrying.',
    );
  }

  Future<void> _persist(PrintOperation operation) async {
    await _store?.upsert(operation);
  }

  PrintOperationState _durableFailureState(Object error) {
    if (error is LocalPrintAgentException &&
        (error.type == LocalPrintAgentFailureType.timeout ||
            error.type == LocalPrintAgentFailureType.duplicate ||
            error.type == LocalPrintAgentFailureType.invalidResponse)) {
      return PrintOperationState.printOutcomeUnknown;
    }
    return PrintOperationState.printFailedConfirmed;
  }

  Future<void> _submitAuditOnce(
    String saleId,
    Map<String, dynamic> audit,
  ) async {
    _auditSubmissionCount += 1;
    developer.log(
      'saleId=$saleId printRequestId=${audit['printRequestId']} '
      'auditSubmissionCount=$_auditSubmissionCount',
      name: 'pos.receipt.audit',
    );
    await _submitAudit(saleId, audit);
  }

  CompletedSalePrintStatus _statusFor(Object error) {
    if (error is PrinterNotConfiguredException) {
      return CompletedSalePrintStatus.notConfigured;
    }
    if (error is LocalPrintAgentException) {
      return switch (error.type) {
        LocalPrintAgentFailureType.authentication =>
          CompletedSalePrintStatus.authenticationFailed,
        LocalPrintAgentFailureType.timeout ||
        LocalPrintAgentFailureType.duplicate =>
          CompletedSalePrintStatus.unknownOutcome,
        LocalPrintAgentFailureType.unreachable ||
        LocalPrintAgentFailureType.printerUnavailable =>
          CompletedSalePrintStatus.unavailable,
        _ => CompletedSalePrintStatus.failed,
      };
    }
    if (error is PrinterConnectionException) {
      return CompletedSalePrintStatus.unavailable;
    }
    return CompletedSalePrintStatus.failed;
  }

  String _messageFor(Object error) {
    final status = _statusFor(error);
    return switch (status) {
      CompletedSalePrintStatus.notConfigured =>
        'Sale completed, printer not configured',
      CompletedSalePrintStatus.unavailable =>
        'Sale completed, printer unavailable',
      CompletedSalePrintStatus.authenticationFailed =>
        'Sale completed, print authentication failed',
      CompletedSalePrintStatus.unknownOutcome =>
        'Sale completed. Print outcome is unknown; retry may duplicate the receipt.',
      _ => 'Sale completed, receipt print failed',
    };
  }

  String? _safeFailureCategory(Object? error) {
    if (error is LocalPrintAgentException) return error.type.name;
    if (error is PrinterException) return error.code;
    return error == null ? null : 'unknown';
  }

  String _safeMessage(Object error) {
    if (error is LocalPrintAgentException) return error.message;
    if (error is PrinterException) return error.message;
    return 'Print audit request failed.';
  }

  String _newRequestId() {
    final random = Random.secure();
    String hex(int length) => List.generate(
          length,
          (_) => random.nextInt(16).toRadixString(16),
        ).join();
    return '${hex(8)}-${hex(4)}-4${hex(3)}-a${hex(3)}-${hex(12)}';
  }

  List<(String, int)> _intendedCopies(CompletedSaleReceipt receipt) {
    final policy = receipt.copyPolicy;
    final copies = <(String, int)>[];
    if (policy.printCustomerCopy) {
      final count = policy.customerCopyCount.clamp(0, 5);
      for (var index = 1; index <= count; index++) {
        copies.add(('CUSTOMER', index));
      }
    }
    if (policy.printMerchantCopy) {
      final count = policy.merchantCopyCount.clamp(0, 5);
      for (var index = 1; index <= count; index++) {
        copies.add(('MERCHANT', index));
      }
    }
    return copies;
  }

  String _copyRequestId(
    String receiptId,
    String copyType,
    int copyIndex,
    String purpose,
  ) {
    final source = '$receiptId|$copyType|$copyIndex|$purpose';
    return ReceiptPrintIdentity.generate(source);
  }
}

final completedSalePrintProvider = StateNotifierProvider<
    CompletedSalePrintController, CompletedSalePrintState>((ref) {
  return CompletedSalePrintController(
    ref.watch(posReceiptPrinterServiceProvider),
    (saleId, audit) => ref
        .read(posCheckoutRemoteDatasourceProvider)
        .recordReceiptPrint(saleId: saleId, audit: audit),
    ref.watch(printOperationStoreProvider),
  );
});
