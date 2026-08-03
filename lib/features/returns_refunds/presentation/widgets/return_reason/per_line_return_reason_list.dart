import 'package:flutter/material.dart';

import '../../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';
import '../../../domain/entities/return_reason_option.dart';
import '../../providers/return_flow_provider.dart';
import 'return_reason_notes_field.dart';
import 'return_reason_options_list.dart';
import 'selected_return_item_tile.dart';

/// Per-line reason + notes controls shown when apply-same-reason is unchecked.
class PerLineReturnReasonList extends StatelessWidget {
  const PerLineReturnReasonList({
    super.key,
    required this.items,
    required this.currency,
    required this.reasons,
    required this.lineSelections,
    required this.onReasonSelected,
    required this.onNotesChanged,
    this.showValidation = false,
  });

  final List<ReturnSelectedReturnLine> items;
  final String currency;
  final List<ReturnReasonOption> reasons;
  final Map<String, ReturnLineReasonSelection> lineSelections;
  final void Function(String saleLineId, String reasonCode) onReasonSelected;
  final void Function(String saleLineId, String notes) onNotesChanged;
  final bool showValidation;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var index = 0; index < items.length; index += 1) ...[
          if (index > 0) const SizedBox(height: TenantAdminSpacing.lg),
          _PerLineReasonCard(
            item: items[index],
            currency: currency,
            reasons: reasons,
            selection: lineSelections[items[index].saleLineId],
            showValidation: showValidation,
            onReasonSelected: (code) =>
                onReasonSelected(items[index].saleLineId, code),
            onNotesChanged: (notes) =>
                onNotesChanged(items[index].saleLineId, notes),
          ),
        ],
      ],
    );
  }
}

class _PerLineReasonCard extends StatefulWidget {
  const _PerLineReasonCard({
    required this.item,
    required this.currency,
    required this.reasons,
    required this.selection,
    required this.onReasonSelected,
    required this.onNotesChanged,
    required this.showValidation,
  });

  final ReturnSelectedReturnLine item;
  final String currency;
  final List<ReturnReasonOption> reasons;
  final ReturnLineReasonSelection? selection;
  final ValueChanged<String> onReasonSelected;
  final ValueChanged<String> onNotesChanged;
  final bool showValidation;

  @override
  State<_PerLineReasonCard> createState() => _PerLineReasonCardState();
}

class _PerLineReasonCardState extends State<_PerLineReasonCard> {
  late final TextEditingController _notesController;

  @override
  void initState() {
    super.initState();
    _notesController =
        TextEditingController(text: widget.selection?.notes ?? '');
  }

  @override
  void didUpdateWidget(covariant _PerLineReasonCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    final nextNotes = widget.selection?.notes ?? '';
    if (_notesController.text != nextNotes) {
      _notesController.text = nextNotes;
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selection = widget.selection;
    final selectedCode = selection?.reasonCode;
    ReturnReasonOption? selectedReason;
    if (selectedCode != null && selectedCode.isNotEmpty) {
      for (final reason in widget.reasons) {
        if (reason.code == selectedCode) {
          selectedReason = reason;
          break;
        }
      }
    }

    final notesRequired = selectedReason?.requiresNotes == true;
    final notes = selection?.notes ?? '';
    String? lineError;
    if (widget.showValidation) {
      if (selectedCode == null || selectedCode.isEmpty) {
        lineError = 'Select a return reason for this item.';
      } else if (notesRequired && notes.trim().isEmpty) {
        lineError = 'Notes are required for the selected reason.';
      }
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(TenantAdminSpacing.lg),
      decoration: BoxDecoration(
        color: TenantAdminColors.surface,
        borderRadius: BorderRadius.circular(TenantAdminRadius.lg),
        border: Border.all(color: TenantAdminColors.border),
        boxShadow: TenantAdminShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SelectedReturnItemTile(
            item: widget.item,
            currency: widget.currency,
          ),
          const SizedBox(height: TenantAdminSpacing.md),
          Text(
            'Reason',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: TenantAdminColors.bodyText,
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: TenantAdminSpacing.sm),
          ReturnReasonOptionsList(
            reasons: widget.reasons,
            selectedReasonCode: selectedCode,
            onReasonSelected: widget.onReasonSelected,
          ),
          const SizedBox(height: TenantAdminSpacing.md),
          ReturnReasonNotesField(
            controller: _notesController,
            notesLength: notes.length,
            required: notesRequired,
            onChanged: widget.onNotesChanged,
          ),
          if (lineError != null) ...[
            const SizedBox(height: TenantAdminSpacing.sm),
            Text(
              lineError,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: TenantAdminColors.danger,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ],
        ],
      ),
    );
  }
}
