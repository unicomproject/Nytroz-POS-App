import 'package:flutter/material.dart';

import '../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';
import '../../domain/entities/return_reason_option.dart';
import 'return_reason_option_tile.dart';

class ReturnReasonOptionsSection extends StatelessWidget {
  const ReturnReasonOptionsSection({
    super.key,
    required this.reasons,
    required this.selectedReasonCode,
    required this.onReasonSelected,
  });

  final List<ReturnReasonOption> reasons;
  final String? selectedReasonCode;
  final ValueChanged<String> onReasonSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Return Reasons',
          style: TenantAdminTextStyles.sectionTitle(context),
        ),
        const SizedBox(height: TenantAdminSpacing.lg),
        if (reasons.isEmpty)
          Text(
            'No active return reasons are configured for this tenant.',
            style: TenantAdminTextStyles.muted(context),
          )
        else
          for (var index = 0; index < reasons.length; index += 1) ...[
            if (index > 0) const SizedBox(height: TenantAdminSpacing.sm),
            ReturnReasonOptionTile(
              option: reasons[index],
              selected: selectedReasonCode == reasons[index].code,
              onSelected: () => onReasonSelected(reasons[index].code),
            ),
          ],
      ],
    );
  }
}
