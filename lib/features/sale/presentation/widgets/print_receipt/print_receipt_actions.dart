import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../auth/presentation/providers/session_provider.dart';
import '../../../../device_activation/presentation/providers/device_activation_provider.dart';
import '../../../../hardware/receipt_printer/models/completed_sale_receipt.dart';
import '../../../data/mappers/completed_sale_receipt_mapper.dart';
import '../../providers/completed_sale_print_provider.dart';
import '../../providers/pos_cash_payment_success_provider.dart';

typedef ReceiptPrintReader = T Function<T>(ProviderListenable<T> provider);

/// Starts the exactly-once **original** receipt print for a completed sale.
///
/// Used by checkout auto-print and Payment Success "Print Receipt".
/// Returns `null` when mapping prerequisites are missing; never throws for
/// transport failures (those are recorded on [completedSalePrintProvider]).
Future<CompletedSaleReceipt?> startCompletedSaleOriginalPrint(
  ReceiptPrintReader read, {
  required String saleId,
}) async {
  final success = read(posCashPaymentSuccessProvider);
  final payment = success?.authoritativePayment;
  if (success == null ||
      success.saleId.trim() != saleId.trim() ||
      payment == null) {
    return null;
  }

  final device = read(deviceActivationProvider).deviceContext;
  final session = read(authSessionProvider);
  if (device == null || session == null) {
    return null;
  }

  final receipt = const CompletedSaleReceiptMapper().fromCompletedPayment(
    payment: payment,
    device: device,
    session: session,
    customerNameOverride: success.customerName,
    customerPhoneOverride: success.customerPhone,
  );
  await read(completedSalePrintProvider.notifier).printAutomatically(receipt);
  return receipt;
}

/// Fire-and-forget original print after authoritative checkout success.
///
/// Must never affect sale/payment completion or navigation.
Future<void> triggerCheckoutReceiptAutoPrint(
  ReceiptPrintReader read, {
  required String saleId,
}) async {
  try {
    final receipt = await startCompletedSaleOriginalPrint(read, saleId: saleId);
    final status = read(completedSalePrintProvider).status;
    developer.log(
      'Checkout auto-print finished. saleId=$saleId '
      'receiptMapped=${receipt != null} status=${status.name}',
      name: 'pos.receipt.print',
    );
  } on FormatException catch (error) {
    developer.log(
      'Checkout auto-print skipped: ${error.message}. saleId=$saleId',
      name: 'pos.receipt.print',
    );
  } catch (error, stackTrace) {
    developer.log(
      'Checkout auto-print failed without affecting sale. saleId=$saleId '
      'error=$error',
      name: 'pos.receipt.print',
      error: error,
      stackTrace: stackTrace,
    );
  }
}

/// Explicit Payment Success / dialog Print Receipt action.
///
/// - Idle / not yet printed → start original (same as auto-print; exactly-once)
/// - Failed original → retry
/// - Already printed → deliberate print-again (reprint identity)
/// Never rolls back payment.
Future<void> executeReceiptPrint(
  BuildContext context,
  WidgetRef ref,
  String saleId,
) async {
  final controller = ref.read(completedSalePrintProvider.notifier);
  final state = ref.read(completedSalePrintProvider);

  if (saleId.isNotEmpty && state.saleId == saleId && state.canRetryPrint) {
    await controller.retryPrint();
  } else if (state.status == CompletedSalePrintStatus.printing &&
      state.saleId == saleId) {
    // In-flight original/retry; do not start a second physical attempt.
  } else if (state.status == CompletedSalePrintStatus.printed &&
      state.saleId == saleId) {
    await controller.printAgainFromPaymentSuccess();
  } else {
    try {
      final receipt =
          await startCompletedSaleOriginalPrint(ref.read, saleId: saleId);
      if (receipt == null) {
        if (context.mounted) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              const SnackBar(
                content: Text(
                  'Completed sale receipt data is unavailable for printing.',
                ),
              ),
            );
        }
        return;
      }
    } on FormatException catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(error.message)));
      }
      return;
    }
  }

  if (!context.mounted) {
    return;
  }

  final latest = ref.read(completedSalePrintProvider);
  final message = switch (latest.status) {
    CompletedSalePrintStatus.printing => 'Receipt printing is in progress.',
    CompletedSalePrintStatus.printed => 'Receipt printed successfully.',
    CompletedSalePrintStatus.unknownOutcome =>
      'Print outcome is unknown. Retrying may duplicate the physical receipt.',
    CompletedSalePrintStatus.notConfigured =>
      'Receipt printer is not configured.',
    CompletedSalePrintStatus.unavailable => 'Receipt printer is unavailable.',
    CompletedSalePrintStatus.authenticationFailed =>
      'Local Print Agent authentication failed.',
    CompletedSalePrintStatus.failed => 'Receipt print failed.',
    CompletedSalePrintStatus.idle =>
      'No completed-sale print operation is available.',
  };
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}
