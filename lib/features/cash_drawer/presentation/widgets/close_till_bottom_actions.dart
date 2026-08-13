import 'package:flutter/material.dart';

import '../../../sale/presentation/widgets/payment/pos_bottom_action_buttons.dart';
import '../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';

class CloseTillBottomActions extends StatelessWidget {
  const CloseTillBottomActions({
    super.key,
    required this.canCloseTill,
    required this.isLoading,
    required this.onCloseTill,
    this.onSaveDraft,
  });

  final bool canCloseTill;
  final bool isLoading;
  final VoidCallback onCloseTill;
  final VoidCallback? onSaveDraft;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final stack = constraints.maxWidth < TenantAdminBreakpoints.mobile;
        final saveDraft = OutlinedButton.icon(
          onPressed: isLoading ? null : onSaveDraft,
          icon: const Icon(Icons.save_outlined),
          label: const Text('Save Draft'),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(0, PosPrimaryActionTokens.height),
            foregroundColor: TenantAdminColors.posHomeAccentOrange,
            side: const BorderSide(
              color: TenantAdminColors.posHomeAccentOrange,
              width: 1.5,
            ),
            textStyle: const TextStyle(fontWeight: FontWeight.w800),
          ),
        );
        final closeTill = PosBottomFilledButton(
          label: 'Close Till',
          icon: Icons.lock_outline_rounded,
          onPressed: canCloseTill && !isLoading ? onCloseTill : null,
          isLoading: isLoading,
          backgroundColor: TenantAdminColors.posHomeAccentOrange,
        );

        if (stack) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              saveDraft,
              const SizedBox(height: TenantAdminSpacing.md),
              closeTill,
            ],
          );
        }

        return Row(
          children: [
            Expanded(child: saveDraft),
            const SizedBox(width: TenantAdminSpacing.md),
            Expanded(flex: 2, child: closeTill),
          ],
        );
      },
    );
  }
}
