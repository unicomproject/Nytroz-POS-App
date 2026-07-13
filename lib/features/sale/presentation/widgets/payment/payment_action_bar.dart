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
    if (onContinue == null) {
      return _PrimaryBackButton(onPressed: onBackToCart);
    }

    return Row(
      children: [
        Expanded(
          child: PosBottomOutlinedButton(
            label: 'Back to Cart',
            onPressed: onBackToCart,
          ),
        ),
        if (onContinue != null) ...[
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
      ],
    );
  }
}

class _PrimaryBackButton extends StatelessWidget {
  const _PrimaryBackButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: PosBottomActionSizes.minHeight,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [TenantAdminColors.navySoft, TenantAdminColors.primary],
          ),
          borderRadius: BorderRadius.circular(TenantAdminRadius.md),
          boxShadow: TenantAdminShadows.card,
        ),
        child: FilledButton.icon(
          onPressed: onPressed,
          style: FilledButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(TenantAdminRadius.md),
            ),
          ),
          icon: const Icon(Icons.shopping_cart_checkout_rounded, size: 18),
          label: const Text(
            'Back to Cart',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
      ),
    );
  }
}
