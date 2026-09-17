import 'package:nytroz_pos/features/tenant_admin/presentation/theme/tenant_admin_theme.dart';
import 'package:flutter/material.dart';

import '../../payment_method_style.dart';

class PaymentInfoCardNotice extends StatelessWidget {
  const PaymentInfoCardNotice({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('payment-info-card-notice'),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: TenantAdminColors.subtleBackground,
        border: Border.all(color: PaymentMethodStyle.border),
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Row(
        children: [
          Icon(
            Icons.info_outline_rounded,
            size: 20,
            color: TenantAdminColors.mutedText,
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Select a payment method to continue. You will be able to review and complete the payment on the next screen.',
              style: TextStyle(
                fontSize: 13,
                color: TenantAdminColors.mutedText,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
