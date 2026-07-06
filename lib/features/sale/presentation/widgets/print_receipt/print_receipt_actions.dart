import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/pos_checkout_summary_provider.dart';

/// Records receipt print audit via the backend, then shows the existing app
/// feedback snackbar. Shared by the print-receipt route and the payment-success
/// print popup.
Future<void> executeReceiptPrint(
  BuildContext context,
  WidgetRef ref,
  String saleId,
) async {
  if (saleId.isNotEmpty) {
    try {
      await ref
          .read(posCheckoutRemoteDatasourceProvider)
          .recordReceiptPrint(saleId: saleId);
    } catch (_) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Receipt print audit could not be recorded.'),
          ),
        );
      return;
    }
  }

  if (!context.mounted) {
    return;
  }

  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      const SnackBar(content: Text('Print receipt is not implemented yet.')),
    );
}
