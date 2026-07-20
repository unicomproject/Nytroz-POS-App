import 'package:flutter/material.dart';

import '../../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';
import '../../../../../shared/widgets/pos_action_buttons.dart';

class ReturnExchangeReviewActionFooter extends StatelessWidget {
  const ReturnExchangeReviewActionFooter({
    super.key,
    required this.canComplete,
    required this.isSubmitting,
    required this.completeLabel,
    required this.onBack,
    required this.onComplete,
  });

  final bool canComplete;
  final bool isSubmitting;
  final String completeLabel;
  final VoidCallback onBack;
  final VoidCallback onComplete;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 760;

        final backButton = OutlinedButton.icon(
          onPressed: isSubmitting ? null : onBack,
          icon: const Icon(Icons.arrow_back_rounded, size: 18),
          label: const Text('Back'),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(0, 48),
            foregroundColor: TenantAdminColors.primary,
            side: const BorderSide(color: TenantAdminColors.primary),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(TenantAdminRadius.sm),
            ),
          ),
        );

        final completeButton = PosPrimaryActionButton(
          label: completeLabel,
          onPressed: canComplete && !isSubmitting ? onComplete : null,
          isLoading: isSubmitting,
          trailingIcon: Icons.arrow_forward_rounded,
          compact: true,
          borderRadius: TenantAdminRadius.sm,
        );

        if (compact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              backButton,
              const SizedBox(height: TenantAdminSpacing.md),
              completeButton,
            ],
          );
        }

        return Row(
          children: [
            SizedBox(width: 140, child: backButton),
            const Spacer(),
            SizedBox(width: 220, child: completeButton),
          ],
        );
      },
    );
  }
}
