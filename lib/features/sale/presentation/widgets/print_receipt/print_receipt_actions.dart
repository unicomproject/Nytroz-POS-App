import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/completed_sale_print_provider.dart';

/// Executes only an explicit retry of the completed-sale print operation.
///
/// It never inserts an audit row on its own. The print controller records
/// exactly one audit for each real physical print attempt.
Future<void> executeReceiptPrint(
  BuildContext context,
  WidgetRef ref,
  String saleId,
) async {
  final state = ref.read(completedSalePrintProvider);
  if (saleId.isNotEmpty && state.saleId == saleId && state.canRetryPrint) {
    await ref.read(completedSalePrintProvider.notifier).retryPrint();
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
