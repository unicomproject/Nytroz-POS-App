import 'package:flutter/material.dart';

import '../../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';
import '../payment/pos_bottom_action_buttons.dart';

class CashPaymentBottomActions extends StatelessWidget {
  const CashPaymentBottomActions({
    super.key,
    required this.canConfirm,
    required this.isLoading,
    required this.onBack,
    required this.onConfirm,
  });

  final bool canConfirm;
  final bool isLoading;
  final VoidCallback onBack;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 520;
        final backButton = PosBottomOutlinedButton(
          label: 'Back',
          onPressed: isLoading ? null : onBack,
          expand: compact,
        );
        final confirmButton = PosBottomFilledButton(
          label: 'Confirm Cash Payment',
          onPressed: canConfirm && !isLoading ? onConfirm : null,
          isLoading: isLoading,
          expand: compact,
        );

        if (compact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              confirmButton,
              const SizedBox(height: TenantAdminSpacing.sm),
              backButton,
            ],
          );
        }

        return Row(
          children: [
            Expanded(child: backButton),
            const SizedBox(width: TenantAdminSpacing.md),
            Expanded(flex: 2, child: confirmButton),
          ],
        );
      },
    );
  }
}
