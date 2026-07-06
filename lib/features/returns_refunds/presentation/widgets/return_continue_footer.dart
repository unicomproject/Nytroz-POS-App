import 'package:flutter/material.dart';

import '../../../sale/presentation/widgets/payment/pos_bottom_action_buttons.dart';
import '../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';

class ReturnContinueFooter extends StatelessWidget {
  const ReturnContinueFooter({
    super.key,
    required this.canContinue,
    required this.onCancel,
    required this.onContinue,
    this.cancelLabel = 'Cancel',
    this.continueLabel = 'Continue',
  });

  final bool canContinue;
  final VoidCallback onCancel;
  final VoidCallback onContinue;
  final String cancelLabel;
  final String continueLabel;

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
                label: cancelLabel,
                onPressed: onCancel,
              ),
              const SizedBox(height: TenantAdminSpacing.md),
              PosBottomFilledButton(
                label: continueLabel,
                icon: Icons.arrow_forward_rounded,
                onPressed: canContinue ? onContinue : null,
              ),
            ],
          );
        }

        return Row(
          children: [
            Expanded(
              child: PosBottomOutlinedButton(
                label: cancelLabel,
                onPressed: onCancel,
              ),
            ),
            const SizedBox(width: TenantAdminSpacing.md),
            Expanded(
              flex: 2,
              child: PosBottomFilledButton(
                label: continueLabel,
                icon: Icons.arrow_forward_rounded,
                onPressed: canContinue ? onContinue : null,
              ),
            ),
          ],
        );
      },
    );
  }
}
