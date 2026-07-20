import 'package:flutter/material.dart';

import '../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';
import '../../../../shared/widgets/pos_action_buttons.dart';

class ReturnsExchangeActionFooter extends StatelessWidget {
  const ReturnsExchangeActionFooter({
    super.key,
    required this.canContinue,
    required this.onBack,
    required this.onContinue,
    this.isSubmitting = false,
    this.continueLabel = 'Continue',
  });

  final bool canContinue;
  final bool isSubmitting;
  final VoidCallback onBack;
  final VoidCallback onContinue;
  final String continueLabel;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < TenantAdminBreakpoints.mobile;
        final backButton = OutlinedButton(
          onPressed: onBack,
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(0, 48),
            foregroundColor: TenantAdminColors.bodyText,
            side: const BorderSide(color: TenantAdminColors.border),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(TenantAdminRadius.sm),
            ),
          ),
          child: const Text('Back'),
        );
        final continueButton = PosPrimaryActionButton(
          label: continueLabel,
          onPressed: canContinue && !isSubmitting ? onContinue : null,
          isLoading: isSubmitting,
          trailingIcon: Icons.arrow_forward_rounded,
          compact: true,
          borderRadius: TenantAdminRadius.sm,
        );

        if (compact) {
          return Row(
            children: [
              Expanded(child: backButton),
              const SizedBox(width: TenantAdminSpacing.md),
              Expanded(flex: 2, child: continueButton),
            ],
          );
        }

        return Row(
          children: [
            SizedBox(width: 140, child: backButton),
            const Spacer(),
            SizedBox(width: 220, child: continueButton),
          ],
        );
      },
    );
  }
}
