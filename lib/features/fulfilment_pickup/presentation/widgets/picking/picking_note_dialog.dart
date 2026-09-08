import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../../../../shared/presentation/app_modal.dart';
import '../../../../../shared/widgets/pos_action_buttons.dart';
import '../../../domain/entities/pos_online_order.dart';
import '../online_order_ui.dart';

class PickingNoteDialog extends StatefulWidget {
  const PickingNoteDialog(
      {required this.onSave, required this.existingNotes, super.key});
  final Future<PosPickingNoteCommandResult> Function(String note) onSave;
  final List<PosPickingNote> existingNotes;
  static Future<void> show(BuildContext context,
          {required Future<PosPickingNoteCommandResult> Function(String note)
              onSave,
          required List<PosPickingNote> existingNotes}) =>
      showAppDialog<void>(
          context: context,
          barrierDismissible: false,
          builder: (_) =>
              PickingNoteDialog(onSave: onSave, existingNotes: existingNotes));
  @override
  State<PickingNoteDialog> createState() => _PickingNoteDialogState();
}

class _PickingNoteDialogState extends State<PickingNoteDialog> {
  final controller = TextEditingController();
  bool busy = false;
  String? error;
  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final value = controller.text.trim();
    if (value.isEmpty) {
      setState(() => error = 'Picking note is required.');
      return;
    }
    if (value.length > 500 || busy) return;
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await widget.onSave(value);
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (exception) {
      if (mounted) {
        if (exception is DioException &&
            exception.response?.statusCode == 409) {
          final messenger = ScaffoldMessenger.maybeOf(context);
          Navigator.pop(context);
          messenger?.showSnackBar(const SnackBar(
              content:
                  Text('This order changed. Picking details were refreshed.')));
          return;
        }
        setState(() {
          busy = false;
          error = 'Unable to save the picking note. Try again.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: const Text('Add Picking Note'),
        content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (widget.existingNotes.isNotEmpty)
                    Text('${widget.existingNotes.length} saved note(s)',
                        style: OnlineOrderUi.subtitle),
                  TextField(
                      key: const Key('picking-note-field'),
                      controller: controller,
                      autofocus: true,
                      maxLength: 500,
                      maxLines: 4,
                      enabled: !busy,
                      decoration: InputDecoration(
                          labelText: 'Operational note', errorText: error)),
                ])),
        actions: [
          TextButton(
              onPressed: busy ? null : () => Navigator.pop(context),
              child: const Text('Cancel')),
          PosPrimaryActionButton(
              label: 'Save Note',
              compact: true,
              isLoading: busy,
              onPressed: busy ? null : _save,
              backgroundColor: Theme.of(context).colorScheme.primary,
              gradient: null),
        ],
      );
}
