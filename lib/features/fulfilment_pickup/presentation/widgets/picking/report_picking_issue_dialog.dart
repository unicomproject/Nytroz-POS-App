import 'package:flutter/material.dart';

import '../../../../../shared/presentation/app_modal.dart';
import '../../../domain/entities/pos_online_order.dart';

class ReportPickingIssueDialog extends StatefulWidget {
  const ReportPickingIssueDialog({required this.line, super.key});
  final PosPickingLine line;
  static Future<String?> show(BuildContext context, PosPickingLine line) =>
      showAppDialog<String>(
          context: context,
          builder: (_) => ReportPickingIssueDialog(line: line));
  @override
  State<ReportPickingIssueDialog> createState() =>
      _ReportPickingIssueDialogState();
}

class _ReportPickingIssueDialogState extends State<ReportPickingIssueDialog> {
  final note = TextEditingController();
  @override
  void dispose() {
    note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: const Text('Report Item Not Found'),
        content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(widget.line.productName,
                  style: const TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              TextField(
                  controller: note,
                  maxLength: 500,
                  decoration:
                      const InputDecoration(labelText: 'Optional note')),
            ]),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(context, note.text.trim()),
              child: const Text('Report issue')),
        ],
      );
}
