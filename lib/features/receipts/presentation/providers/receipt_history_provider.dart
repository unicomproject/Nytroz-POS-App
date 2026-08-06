import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_provider.dart';
import '../../../device_activation/presentation/providers/device_activation_provider.dart';
import '../../../hardware/receipt_printer/non_sale_receipt_print_orchestrator.dart';
import '../../../hardware/receipt_printer/pos_receipt_printer_service.dart';
import '../../domain/historical_return_receipt_mapper.dart';
import '../../data/receipt_remote_datasource.dart';
import '../../domain/receipt_history_models.dart';
import '../../../sale/presentation/providers/pos_checkout_summary_provider.dart';

final receiptRemoteDatasourceProvider = Provider<ReceiptRemoteDatasource>(
  (ref) => ReceiptRemoteDatasource(ref.watch(appDioProvider)),
);

final receiptSearchProvider = FutureProvider.autoDispose
    .family<({List<ReceiptHistoryItem> items, int total}), String>(
  (ref, query) => ref.watch(receiptRemoteDatasourceProvider).search(
        query: query,
      ),
);

final receiptDetailProvider =
    FutureProvider.autoDispose.family<ReceiptDetail, String>(
  (ref, id) => ref.watch(receiptRemoteDatasourceProvider).detail(id),
);

class ReceiptReprintAuditState {
  const ReceiptReprintAuditState({
    this.saleId,
    this.payload,
    this.submitting = false,
    this.physicalPrinted = false,
  });
  final String? saleId;
  final Map<String, dynamic>? payload;
  final bool submitting;
  final bool physicalPrinted;
  bool get pending => saleId != null && payload != null;
}

class ReceiptReprintAuditController
    extends StateNotifier<ReceiptReprintAuditState> {
  ReceiptReprintAuditController(this.ref)
      : super(const ReceiptReprintAuditState());
  final Ref ref;

  Future<bool> submit(String saleId, Map<String, dynamic> payload,
      {required bool physicalPrinted}) async {
    state = ReceiptReprintAuditState(
        saleId: saleId,
        payload: payload,
        submitting: true,
        physicalPrinted: physicalPrinted);
    try {
      await ref
          .read(posCheckoutRemoteDatasourceProvider)
          .recordReceiptPrint(saleId: saleId, audit: payload);
      state = const ReceiptReprintAuditState();
      return true;
    } catch (_) {
      state = ReceiptReprintAuditState(
          saleId: saleId, payload: payload, physicalPrinted: physicalPrinted);
      return false;
    }
  }

  Future<bool> retryAuditOnly() async {
    final saleId = state.saleId;
    final payload = state.payload;
    if (saleId == null || payload == null || state.submitting) return false;
    return submit(saleId, payload, physicalPrinted: state.physicalPrinted);
  }
}

final receiptReprintAuditProvider = StateNotifierProvider<
    ReceiptReprintAuditController, ReceiptReprintAuditState>(
  (ref) => ReceiptReprintAuditController(ref),
);

enum HistoricalReprintStatus {
  idle,
  printing,
  printed,
  partial,
  unknown,
  auditPending,
  failed,
}

class HistoricalReprintState {
  const HistoricalReprintState({
    this.status = HistoricalReprintStatus.idle,
    this.message,
    this.saleId,
    this.pendingAudits = const [],
  });

  final HistoricalReprintStatus status;
  final String? message;
  final String? saleId;
  final List<Map<String, dynamic>> pendingAudits;
}

class HistoricalReprintController
    extends StateNotifier<HistoricalReprintState> {
  HistoricalReprintController(this.ref) : super(const HistoricalReprintState());

  final Ref ref;
  bool _running = false;

  Future<void> print({
    required ReceiptDetail detail,
    required String reprintOperationId,
    required String reasonCode,
    String? reasonNote,
  }) async {
    if (_running) return;
    _running = true;
    state = const HistoricalReprintState(
      status: HistoricalReprintStatus.printing,
      message: 'Preparing configured receipt copies…',
    );
    try {
      final device = ref.read(deviceActivationProvider).deviceContext;
      if (device == null || device.deviceId.trim().isEmpty) {
        throw StateError('Trusted POS device is unavailable.');
      }
      final receipt = mapHistoricalNonSaleReceipt(detail);
      final result = await NonSaleReceiptPrintOrchestrator(
        printer: ref.read(posReceiptPrinterServiceProvider),
        submitAudit: (saleId, audit) => ref
            .read(receiptRemoteDatasourceProvider)
            .recordPrintAudit(saleId: saleId, audit: audit),
      ).print(
        deviceId: device.deviceId,
        receipt: receipt,
        isReprint: true,
        reprintOperationId: reprintOperationId,
        reprintReasonCode: reasonCode,
        reprintReasonNote: reasonNote,
      );
      final pendingAudits = result.outcomes
          .map((item) => item.pendingAudit)
          .whereType<Map<String, dynamic>>()
          .toList(growable: false);

      state = HistoricalReprintState(
        status: result.hasUnknown
            ? HistoricalReprintStatus.unknown
            : result.hasFailures
                ? HistoricalReprintStatus.partial
                : result.hasAuditPending
                    ? HistoricalReprintStatus.auditPending
                    : HistoricalReprintStatus.printed,
        saleId: detail.summary.saleId,
        pendingAudits: pendingAudits,
        message: result.hasUnknown
            ? 'A copy has an unknown outcome. Check the physical paper before another controlled reprint.'
            : result.hasFailures
                ? 'Some copies failed. Successfully printed copies were not repeated.'
                : result.hasAuditPending
                    ? 'Copies printed, but one or more audits are pending.'
                    : 'All configured reprint copies printed and were audited.',
      );
    } catch (_) {
      state = const HistoricalReprintState(
        status: HistoricalReprintStatus.failed,
        message: 'Historical receipt reprint failed.',
      );
    } finally {
      _running = false;
    }
  }

  Future<void> retryAuditOnly() async {
    if (_running || state.pendingAudits.isEmpty || state.saleId == null) return;
    _running = true;
    state = HistoricalReprintState(
      status: HistoricalReprintStatus.printing,
      message: 'Retrying print audits only…',
      saleId: state.saleId,
      pendingAudits: state.pendingAudits,
    );
    final failed = <Map<String, dynamic>>[];
    for (final audit in state.pendingAudits) {
      try {
        await ref.read(receiptRemoteDatasourceProvider).recordPrintAudit(
          saleId: state.saleId!,
          audit: {...audit, 'isRetry': true},
        );
      } catch (_) {
        failed.add(audit);
      }
    }
    state = HistoricalReprintState(
      status: failed.isEmpty
          ? HistoricalReprintStatus.printed
          : HistoricalReprintStatus.auditPending,
      message: failed.isEmpty
          ? 'All pending audits were recorded. No receipt was reprinted.'
          : 'One or more audits are still pending.',
      saleId: state.saleId,
      pendingAudits: failed,
    );
    _running = false;
  }
}

final historicalReprintProvider = StateNotifierProvider.autoDispose<
    HistoricalReprintController, HistoricalReprintState>(
  (ref) => HistoricalReprintController(ref),
);
