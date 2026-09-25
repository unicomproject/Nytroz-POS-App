import 'package:flutter/material.dart';

import '../../utils/picking_visual_metrics.dart';
import '../online_order_ui.dart';

class PackingNotes extends StatelessWidget {
  const PackingNotes({
    required this.controller,
    required this.noteLength,
    required this.maxLength,
    required this.compact,
    required this.enabled,
    this.ultraCompact = false,
    super.key,
  });

  final TextEditingController controller;
  final int noteLength;
  final int maxLength;
  final bool compact;
  final bool enabled;
  final bool ultraCompact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(ultraCompact ? 6 : (compact ? 8 : 10)),
      decoration: pickingCardDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Packing Notes',
                  style: TextStyle(
                    fontSize: ultraCompact ? 12.5 : 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                'Optional',
                style: OnlineOrderUi.subtitle.copyWith(fontSize: 11),
              ),
            ],
          ),
          SizedBox(height: ultraCompact ? 2 : (compact ? 4 : 6)),
          Semantics(
            textField: true,
            label: 'Packing Notes',
            child: TextField(
              key: const Key('packing-notes-field'),
              controller: controller,
              enabled: enabled,
              maxLength: maxLength,
              maxLines: ultraCompact ? 1 : 2,
              minLines: 1,
              decoration: InputDecoration(
                hintText: 'Add packing instructions…',
                counterText: '$noteLength / $maxLength',
                isDense: true,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: ultraCompact ? 6 : 8,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
