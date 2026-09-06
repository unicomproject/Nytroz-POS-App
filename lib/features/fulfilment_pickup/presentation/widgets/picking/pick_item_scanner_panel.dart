import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/access/pos_access_codes.dart';
import '../../../../auth/presentation/providers/session_provider.dart';
import '../../../domain/entities/pos_online_order.dart';
import '../../utils/picking_formatters.dart';

class PickItemResult {
  const PickItemResult({required this.scanned, required this.barcode});
  final bool scanned;
  final String barcode;
}

class PickItemScannerPanel extends ConsumerStatefulWidget {
  const PickItemScannerPanel(
      {required this.line, this.preferScan = false, super.key});
  final PosPickingLine line;
  final bool preferScan;
  @override
  ConsumerState<PickItemScannerPanel> createState() =>
      _PickItemScannerPanelState();
}

class _PickItemScannerPanelState extends ConsumerState<PickItemScannerPanel> {
  final barcode = TextEditingController();
  @override
  void dispose() {
    barcode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(authSessionProvider);
    final canScan =
        session?.hasPermission(PosPermissionCodes.scanOnlineOrderItem) == true;
    final canManual = session
            ?.hasPermission(PosPermissionCodes.manuallyEnterOnlineOrderItem) ==
        true;
    return AlertDialog(
      title: Text(widget.preferScan ? 'Scan Item Barcode' : 'Pick Item'),
      content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(widget.line.productName,
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 12),
                TextField(
                    controller: barcode,
                    autofocus: true,
                    decoration: const InputDecoration(
                        labelText: 'Barcode',
                        helperText:
                            'The server verifies the product barcode.')),
                const SizedBox(height: 12),
                Text(
                    'This pick: ${pickingQuantity(widget.line.remainingQuantity)} unit(s)'),
              ])),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel')),
        if (canManual)
          OutlinedButton(
              onPressed: () => Navigator.pop(context,
                  PickItemResult(scanned: false, barcode: barcode.text)),
              child: const Text('Manual pick')),
        if (canScan)
          FilledButton.icon(
              onPressed: () => Navigator.pop(context,
                  PickItemResult(scanned: true, barcode: barcode.text)),
              icon: const Icon(Icons.qr_code_scanner),
              label: const Text('Scan & pick')),
      ],
    );
  }
}
