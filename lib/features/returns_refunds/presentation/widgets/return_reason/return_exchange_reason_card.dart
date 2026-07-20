import 'package:flutter/material.dart';

import '../../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';
import '../../../domain/entities/return_reason_option.dart';
import 'apply_same_reason_control.dart';
import 'return_reason_notes_field.dart';
import 'return_reason_options_list.dart';

class ReturnExchangeReasonCard extends StatelessWidget {
  const ReturnExchangeReasonCard({
    super.key,
    required this.reasons,
    required this.selectedReasonCode,
    required this.notesController,
    required this.notesLength,
    required this.applySameReasonToAll,
    required this.onReasonSelected,
    required this.onNotesChanged,
    required this.onApplySameReasonChanged,
    this.notesRequired = false,
    this.validationMessage,
  });

  final List<ReturnReasonOption> reasons;
  final String? selectedReasonCode;
  final TextEditingController notesController;
  final int notesLength;
  final bool applySameReasonToAll;
  final ValueChanged<String> onReasonSelected;
  final ValueChanged<String> onNotesChanged;
  final ValueChanged<bool> onApplySameReasonChanged;
  final bool notesRequired;
  final String? validationMessage;

  @override
  Widget build(BuildContext context) {
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
          Text(
            'Return / Exchange Reason',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: TenantAdminColors.bodyText,
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: TenantAdminSpacing.md),
          ApplySameReasonControl(
            value: applySameReasonToAll,
            onChanged: onApplySameReasonChanged,
          ),
          if (applySameReasonToAll) ...[
            const SizedBox(height: TenantAdminSpacing.lg),
            ReturnReasonOptionsList(
              reasons: reasons,
              selectedReasonCode: selectedReasonCode,
              onReasonSelected: onReasonSelected,
            ),
            const SizedBox(height: TenantAdminSpacing.lg),
            ReturnReasonNotesField(
              controller: notesController,
              notesLength: notesLength,
              required: notesRequired,
              onChanged: onNotesChanged,
            ),
            if (validationMessage != null) ...[
              const SizedBox(height: TenantAdminSpacing.md),
              Text(
                validationMessage!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: TenantAdminColors.danger,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}
