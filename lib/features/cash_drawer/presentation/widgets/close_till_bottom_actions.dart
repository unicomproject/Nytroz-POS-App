import 'package:flutter/material.dart';

import '../../../sale/presentation/widgets/payment/pos_bottom_action_buttons.dart';
import '../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';

class CloseTillBottomActions extends StatelessWidget {
  const CloseTillBottomActions({
    super.key,
    required this.canCloseTill,
    required this.isLoading,
    required this.onSaveDraft,
    required this.onCloseTill,
  });

  final bool canCloseTill;
  final bool isLoading;
  final VoidCallback onSaveDraft;
  final VoidCallback onCloseTill;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final stackVertically =
            constraints.maxWidth < TenantAdminBreakpoints.mobile;

        if (stackVertically) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              PosBottomOutlinedButton(
                label: 'Save Draft',
                onPressed: isLoading ? null : onSaveDraft,
              ),
              const SizedBox(height: TenantAdminSpacing.md),
              PosBottomFilledButton(
                label: 'Close Till',
                onPressed: canCloseTill && !isLoading ? onCloseTill : null,
                isLoading: isLoading,
              ),
            ],
          );
        }

        return Row(
          children: [
            Expanded(
              child: PosBottomOutlinedButton(
                label: 'Save Draft',
                onPressed: isLoading ? null : onSaveDraft,
              ),
            ),
            const SizedBox(width: TenantAdminSpacing.md),
            Expanded(
              child: PosBottomFilledButton(
                label: 'Close Till',
                onPressed: canCloseTill && !isLoading ? onCloseTill : null,
                isLoading: isLoading,
              ),
            ),
          ],
        );
      },
    );
  }
}
