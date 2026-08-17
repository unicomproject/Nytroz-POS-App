import 'package:flutter/material.dart';

import '../../../sale/presentation/widgets/payment/pos_bottom_action_buttons.dart';
import '../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';

class CashInBottomActions extends StatelessWidget {
  const CashInBottomActions({
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
    return Row(
      children: [
        Expanded(
          flex: 5,
          child: OutlinedButton(
            onPressed: isLoading ? null : onCancel,
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(0, PosPrimaryActionTokens.height),
              foregroundColor: TenantAdminColors.posHomeAccentOrange,
              side: const BorderSide(
                color: TenantAdminColors.posHomeAccentOrange,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(TenantAdminRadius.md),
              ),
            ),
            child: const Text(
              'Cancel',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ),
        const SizedBox(width: TenantAdminSpacing.md),
        Expanded(
          flex: 3,
          child: PosBottomFilledButton(
            label: 'Confirm Cash In',
            onPressed: canConfirm && !isLoading ? onConfirm : null,
            isLoading: isLoading,
            icon: Icons.point_of_sale_outlined,
            backgroundColor: TenantAdminColors.posHomeAccentOrange,
          ),
        ),
      ],
    );
  }
}
