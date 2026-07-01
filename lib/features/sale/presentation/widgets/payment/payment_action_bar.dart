import 'package:flutter/material.dart';

import '../../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';
import 'pos_bottom_action_buttons.dart';

class PaymentActionBar extends StatelessWidget {
  const PaymentActionBar({
    super.key,
    required this.continueLabel,
    required this.onBackToCart,
    required this.onContinue,
    this.isLoading = false,
  });

  final String continueLabel;
  final VoidCallback onBackToCart;
  final VoidCallback? onContinue;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 520;
        final backButton = PosBottomOutlinedButton(
          label: 'Back to Cart',
          onPressed: onBackToCart,
          expand: compact,
        );
        final continueButton = onContinue == null
            ? null
            : PosBottomFilledButton(
                label: continueLabel,
                onPressed: onContinue,
                isLoading: isLoading,
                expand: compact,
              );

        if (compact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (continueButton != null) ...[
                continueButton,
                const SizedBox(height: TenantAdminSpacing.sm),
              ],
              backButton,
            ],
          );
        }

        return Row(
          children: [
            Expanded(child: backButton),
            if (continueButton != null) ...[
              const SizedBox(width: TenantAdminSpacing.md),
              Expanded(flex: 2, child: continueButton),
            ],
          ],
        );
      },
    );
  }
}
