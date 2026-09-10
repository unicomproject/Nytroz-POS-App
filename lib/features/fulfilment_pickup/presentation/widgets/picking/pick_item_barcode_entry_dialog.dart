import 'package:flutter/material.dart';

import '../../../../../shared/presentation/app_modal.dart';

/// OO-04B scan/manual barcode capture dialog.
///
/// Owns [TextEditingController] in [State] and disposes it only after the
/// dialog subtree is unmounted. Callers must not create/dispose a controller
/// around [show] — that races the dialog exit animation and triggers
/// framework `_dependents.isEmpty` assertions.
class PickItemBarcodeEntryDialog extends StatefulWidget {
  const PickItemBarcodeEntryDialog({required this.scanned, super.key});

  final bool scanned;

  static Future<String?> show(
    BuildContext context, {
    required bool scanned,
  }) {
    return showAppDialog<String>(
      context: context,
      builder: (_) => PickItemBarcodeEntryDialog(scanned: scanned),
    );
  }

  @override
  State<PickItemBarcodeEntryDialog> createState() =>
      _PickItemBarcodeEntryDialogState();
}

class _PickItemBarcodeEntryDialogState
    extends State<PickItemBarcodeEntryDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() => Navigator.of(context).pop(_controller.text);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.scanned ? 'Scan Item Barcode' : 'Enter Barcode Manually',
      ),
      content: TextField(
        key: Key(widget.scanned ? 'scan-barcode-input' : 'manual-barcode-input'),
        controller: _controller,
        autofocus: true,
        textInputAction: TextInputAction.done,
        decoration: InputDecoration(
          labelText: 'Barcode',
          helperText: widget.scanned
              ? 'Use the connected barcode scanner.'
              : 'Enter the barcode printed on the item.',
        ),
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _submit,
          child: const Text('Verify'),
        ),
      ],
    );
  }
}
