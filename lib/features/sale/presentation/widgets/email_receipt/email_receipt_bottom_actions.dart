import 'package:flutter/material.dart';

import '../../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';
import '../payment/pos_bottom_action_buttons.dart';

class EmailReceiptBottomActions extends StatelessWidget {
  const EmailReceiptBottomActions({
    super.key,
    required this.canSendReceipt,
    required this.onBack,
    required this.onSendReceipt,
  });

  final bool canSendReceipt;
  final VoidCallback onBack;
  final VoidCallback onSendReceipt;

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
            label: 'Send Receipt',
            icon: Icons.send_rounded,
            onPressed: canSendReceipt ? onSendReceipt : null,
          ),
        ),
      ],
    );
  }
}
