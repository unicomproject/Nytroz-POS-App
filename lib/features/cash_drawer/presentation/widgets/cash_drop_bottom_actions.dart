import 'package:flutter/material.dart';

import '../../../sale/presentation/widgets/payment/pos_bottom_action_buttons.dart';
import '../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';

class CashDropBottomActions extends StatelessWidget {
  const CashDropBottomActions({
    super.key,
    required this.canConfirm,
    required this.isLoading,
    required this.onCancel,
    required this.onConfirm,
  });

  final bool canConfirm;
  final bool isLoading;
  final VoidCallback onCancel;
  final VoidCallback onConfirm;

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
                label: 'Cancel',
                onPressed: isLoading ? null : onCancel,
              ),
              const SizedBox(height: TenantAdminSpacing.md),
              PosBottomFilledButton(
                label: 'Confirm Cash Drop',
                onPressed: canConfirm && !isLoading ? onConfirm : null,
                isLoading: isLoading,
              ),
            ],
          );
        }

        return Row(
          children: [
            Expanded(
              child: PosBottomOutlinedButton(
                label: 'Cancel',
                onPressed: isLoading ? null : onCancel,
              ),
            ),
            const SizedBox(width: TenantAdminSpacing.md),
            Expanded(
              flex: 2,
              child: PosBottomFilledButton(
                label: 'Confirm Cash Drop',
                onPressed: canConfirm && !isLoading ? onConfirm : null,
                isLoading: isLoading,
              ),
            ),
          ],
        );
      },
    );
  }
}
