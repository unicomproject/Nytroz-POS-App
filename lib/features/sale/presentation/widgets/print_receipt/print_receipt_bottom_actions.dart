import 'package:flutter/material.dart';

import '../../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';
import '../payment/pos_bottom_action_buttons.dart';

class PrintReceiptBottomActions extends StatelessWidget {
  const PrintReceiptBottomActions({
    super.key,
    required this.onBack,
    required this.onPrintReceipt,
  });

  final VoidCallback onBack;
  final VoidCallback onPrintReceipt;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: PosBottomOutlinedButton(
            label: 'Back',
            onPressed: onBack,
          ),
        ),
        const SizedBox(width: TenantAdminSpacing.md),
        Expanded(
          flex: 2,
          child: PosBottomFilledButton(
            label: 'Print Receipt',
            icon: Icons.print_outlined,
            onPressed: onPrintReceipt,
          ),
        ),
      ],
    );
  }
}
