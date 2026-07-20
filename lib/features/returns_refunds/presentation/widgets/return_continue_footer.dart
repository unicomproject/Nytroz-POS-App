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
        final guidance = ReturnContinueGuidance(canContinue: canContinue);

        if (stackVertically) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              guidance,
              const SizedBox(height: TenantAdminSpacing.md),
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
            Expanded(flex: 2, child: guidance),
            const SizedBox(width: TenantAdminSpacing.md),
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

class ReturnContinueGuidance extends StatelessWidget {
  const ReturnContinueGuidance({
    super.key,
    required this.canContinue,
  });

  final bool canContinue;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(TenantAdminSpacing.md),
      decoration: BoxDecoration(
        color:
            canContinue ? const Color(0xFFEFFAF3) : TenantAdminColors.secondary,
        borderRadius: BorderRadius.circular(TenantAdminRadius.md),
        border: Border.all(
          color: canContinue
              ? const Color(0xFFBBE7C8)
              : TenantAdminColors.info.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            canContinue
                ? Icons.check_circle_outline_rounded
                : Icons.info_outline_rounded,
            color: canContinue
                ? TenantAdminColors.success
                : TenantAdminColors.info,
            size: 20,
          ),
          const SizedBox(width: TenantAdminSpacing.sm),
          Expanded(
            child: Text(
              canContinue
                  ? 'Original sale selected. Continue to the next return step.'
                  : 'A valid original sale is required to continue the return or exchange process.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: TenantAdminColors.bodyText,
                    fontWeight: FontWeight.w700,
                    height: 1.35,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
