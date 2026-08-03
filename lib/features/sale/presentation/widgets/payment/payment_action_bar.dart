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
    return Row(
      children: [
        Expanded(
          child: PosBottomOutlinedButton(
            label: 'Back to Cart',
            onPressed: onBackToCart,
          ),
        ),
        const SizedBox(width: TenantAdminSpacing.md),
        Expanded(
          flex: 2,
          child: PosBottomFilledButton(
            label: continueLabel,
            onPressed: onContinue,
            isLoading: isLoading,
          ),
        ),
      ],
    );
  }
}
